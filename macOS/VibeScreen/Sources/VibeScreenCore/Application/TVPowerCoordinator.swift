import Foundation

public protocol TVDeviceController: Sendable {
    func deviceDescriptor() async -> TVDeviceDescriptor
    func connect() async throws
    func execute(_ command: TVCommand) async throws
    func disconnect() async
    func readPowerState() async throws -> TVPowerState
}

public extension TVDeviceController {
    func readPowerState() async throws -> TVPowerState {
        throw TVProtocolError.powerStateUnavailable
    }
}

public protocol TVPowerActionClock: Sendable {
    func sleep(for seconds: Int) async throws
}

public struct SystemTVPowerActionClock: TVPowerActionClock {
    public init() {}

    public func sleep(for seconds: Int) async throws {
        guard seconds >= 0 else {
            throw TVPowerCoordinatorError.invalidDelay
        }

        let (nanoseconds, overflowed) = UInt64(seconds).multipliedReportingOverflow(by: 1_000_000_000)
        guard !overflowed else {
            throw TVPowerCoordinatorError.invalidDelay
        }

        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

public enum TVPowerCoordinatorError: Error, LocalizedError, Sendable, Equatable {
    case missingMacAddress
    case wakeOnLANUnavailable
    case invalidDelay

    public var errorDescription: String? {
        switch self {
        case .missingMacAddress:
            return "Wake-on-LAN needs a MAC address for this TV."
        case .wakeOnLANUnavailable:
            return "The Wake-on-LAN sender is not available."
        case .invalidDelay:
            return "The power action contains an invalid delay."
        }
    }
}

public enum TVPowerExecutionStatus: String, Codable, Sendable, Equatable {
    case succeeded
    case failed
    case cancelled
}

public struct TVPowerActionResult: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let action: TVPowerAction
    public let succeeded: Bool
    public let message: String?

    public init(
        id: UUID = UUID(),
        action: TVPowerAction,
        succeeded: Bool,
        message: String? = nil
    ) {
        self.id = id
        self.action = action
        self.succeeded = succeeded
        self.message = message
    }
}

public struct TVPowerExecutionResult: Codable, Sendable, Equatable {
    public let deviceID: UUID
    public let status: TVPowerExecutionStatus
    public let actions: [TVPowerActionResult]

    public init(
        deviceID: UUID,
        status: TVPowerExecutionStatus,
        actions: [TVPowerActionResult]
    ) {
        self.deviceID = deviceID
        self.status = status
        self.actions = actions
    }
}

/// Applies per-device power policy to normalized macOS lifecycle signals.
/// Connection and WOL effects are injected so this coordinator remains fully
/// testable without a Mac, a TV, or a network interface.
public actor TVPowerPolicyCoordinator {
    private struct RegisteredController: Sendable {
        let deviceID: UUID
        let generation: UUID
        let controller: any TVDeviceController
    }

    private var controllers: [UUID: RegisteredController] = [:]
    private var activeActionTasks: [UUID: [UUID: Task<TVPowerExecutionResult, Never>]] = [:]
    private var manuallyPoweredOffDeviceIDs: Set<UUID> = []
    private let wakeOnLAN: (any WakeOnLANSender)?
    private let clock: any TVPowerActionClock
    private let diagnostics: (any PowerDiagnosticRecording)?

    public init(
        wakeOnLAN: (any WakeOnLANSender)? = nil,
        clock: any TVPowerActionClock = SystemTVPowerActionClock(),
        diagnostics: (any PowerDiagnosticRecording)? = nil
    ) {
        self.wakeOnLAN = wakeOnLAN
        self.clock = clock
        self.diagnostics = diagnostics
    }

    public func register(_ controller: any TVDeviceController) async {
        let descriptor = await controller.deviceDescriptor()
        controllers[descriptor.id] = RegisteredController(
            deviceID: descriptor.id,
            generation: UUID(),
            controller: controller
        )
    }

    /// Cancels work based on the old policy before its controller is replaced.
    /// Keep the manual power-off latch because a policy edit is not a TV command.
    public func invalidatePendingActions(for deviceID: UUID) {
        controllers.removeValue(forKey: deviceID)
        if let tasks = activeActionTasks.removeValue(forKey: deviceID) {
            tasks.values.forEach { $0.cancel() }
        }
    }

    public func remove(deviceID: UUID) {
        invalidatePendingActions(for: deviceID)
        manuallyPoweredOffDeviceIDs.remove(deviceID)
    }

    public func removeAll() {
        activeActionTasks.values
            .flatMap(\.values)
            .forEach { $0.cancel() }
        activeActionTasks.removeAll()
        controllers.removeAll()
        manuallyPoweredOffDeviceIDs.removeAll()
    }

    /// Records an explicit power command from the user-facing remote or
    /// shortcut surface. Automatic screen-sleep actions never call this, so a
    /// mouse/keyboard wake can still restore a screen that automation turned
    /// off. The latch remains until an explicit power-on/screen-on command or
    /// an allowed automatic wake succeeds.
    public func recordManualPowerAction(_ command: TVPowerCommand, for deviceID: UUID) async {
        switch command {
        case .powerOff, .screenOff:
            manuallyPoweredOffDeviceIDs.insert(deviceID)
        case .powerOn, .screenOn:
            manuallyPoweredOffDeviceIDs.remove(deviceID)
        }
        let isLatchedOff = manuallyPoweredOffDeviceIDs.contains(deviceID)
        await diagnostics?.record(
            kind: "power.manualLatch.updated",
            details: [
                "command": command.rawValue,
                "deviceID": deviceID.uuidString,
                "manualOffLatched": String(isLatchedOff)
            ]
        )
    }

    /// Returns whether the user most recently issued an explicit power-off
    /// action for this device. This lets the shortcut recover when a TV stops
    /// answering state queries immediately after entering standby.
    public func isManuallyPoweredOff(deviceID: UUID) -> Bool {
        manuallyPoweredOffDeviceIDs.contains(deviceID)
    }

    public func handle(signal: PlatformSignalKind) async -> [TVPowerExecutionResult] {
        let registeredControllers = Array(controllers.values)
        var results: [TVPowerExecutionResult] = []
        let handlingID = UUID().uuidString

        await diagnostics?.record(
            kind: "power.signal.received",
            details: [
                "controllerCount": String(registeredControllers.count),
                "handlingID": handlingID,
                "signal": signal.rawValue
            ]
        )

        for registration in registeredControllers {
            guard isCurrent(registration) else { continue }
            let descriptor = await registration.controller.deviceDescriptor()
            guard isCurrent(registration) else { continue }
            let manualPowerOff = manuallyPoweredOffDeviceIDs.contains(descriptor.id)
            let actions = TVPowerPolicyEngine.actions(
                for: signal,
                device: descriptor,
                manualPowerOff: manualPowerOff
            )
            await diagnostics?.record(
                kind: "power.policy.evaluated",
                details: [
                    "actions": actions.map { $0.command.rawValue }.joined(separator: ","),
                    "deviceID": descriptor.id.uuidString,
                    "handlingID": handlingID,
                    "manualOffLatched": String(manualPowerOff),
                    "powerOffOnScreenSaver": String(
                        descriptor.powerPolicy.powerOffOnScreenSaver
                    ),
                    "powerOnAfterManualPowerOff": String(
                        descriptor.powerPolicy.powerOnAfterManualPowerOff
                    ),
                    "powerOnAfterResume": String(
                        descriptor.powerPolicy.powerOnAfterResume
                    ),
                    "powerOnAfterScreenSaver": String(
                        descriptor.powerPolicy.powerOnAfterScreenSaver
                    ),
                    "powerOnAfterSessionUnlock": String(
                        descriptor.powerPolicy.powerOnAfterSessionUnlock
                    ),
                    "powerOnAfterStartup": String(
                        descriptor.powerPolicy.powerOnAfterStartup
                    ),
                    "signal": signal.rawValue,
                    "triggersEnabled": String(descriptor.powerPolicy.triggersEnabled)
                ]
            )
            guard isCurrent(registration) else { continue }
            guard !actions.isEmpty else { continue }

            let runID = UUID()
            let executionTask = Task { [self] in
                await execute(
                    actions,
                    for: descriptor,
                    using: registration,
                    handlingID: handlingID,
                    signal: signal
                )
            }
            activeActionTasks[descriptor.id, default: [:]][runID] = executionTask

            let result = await withTaskCancellationHandler {
                await executionTask.value
            } onCancel: {
                executionTask.cancel()
            }

            if var tasks = activeActionTasks[descriptor.id] {
                tasks.removeValue(forKey: runID)
                if tasks.isEmpty {
                    activeActionTasks.removeValue(forKey: descriptor.id)
                } else {
                    activeActionTasks[descriptor.id] = tasks
                }
            }

            results.append(result)

            if result.status == .succeeded,
               actions.contains(where: { $0.command == .powerOn || $0.command == .screenOn }) {
                manuallyPoweredOffDeviceIDs.remove(descriptor.id)
            }
        }

        return results
    }

    private func execute(
        _ actions: [TVPowerAction],
        for descriptor: TVDeviceDescriptor,
        using registration: RegisteredController,
        handlingID: String,
        signal: PlatformSignalKind
    ) async -> TVPowerExecutionResult {
        let controller = registration.controller
        var actionResults: [TVPowerActionResult] = []
        var status: TVPowerExecutionStatus = .succeeded
        var isConnected = false

        for action in actions {
            do {
                try ensureCurrent(registration)
                await diagnostics?.record(
                    kind: "power.action.started",
                    details: [
                        "command": action.command.rawValue,
                        "delaySeconds": String(action.delaySeconds),
                        "deviceID": descriptor.id.uuidString,
                        "handlingID": handlingID,
                        "signal": signal.rawValue
                    ]
                )
                try ensureCurrent(registration)
                try await clock.sleep(for: action.delaySeconds)
                try ensureCurrent(registration)

                switch action.command {
                case .powerOn:
                    guard let macAddress = descriptor.macAddress, !macAddress.isEmpty else {
                        throw TVPowerCoordinatorError.missingMacAddress
                    }
                    guard let wakeOnLAN else {
                        throw TVPowerCoordinatorError.wakeOnLANUnavailable
                    }
                    try ensureCurrent(registration)
                    try await wakeOnLAN.send(
                        macAddress: macAddress,
                        broadcastAddress: "255.255.255.255",
                        port: 9
                    )

                case .powerOff, .screenOff, .screenOn:
                    if !isConnected {
                        try await controller.connect()
                        isConnected = true
                    }
                    try ensureCurrent(registration)
                    try await controller.execute(action.command.asTVCommand)
                }

                try ensureCurrent(registration)
                actionResults.append(TVPowerActionResult(action: action, succeeded: true))
                await diagnostics?.record(
                    kind: "power.action.succeeded",
                    details: [
                        "command": action.command.rawValue,
                        "deviceID": descriptor.id.uuidString,
                        "handlingID": handlingID,
                        "signal": signal.rawValue
                    ]
                )
            } catch is CancellationError {
                status = .cancelled
                actionResults.append(
                    TVPowerActionResult(
                        action: action,
                        succeeded: false,
                        message: "Power action cancelled."
                    )
                )
                await diagnostics?.record(
                    kind: "power.action.cancelled",
                    details: [
                        "command": action.command.rawValue,
                        "deviceID": descriptor.id.uuidString,
                        "handlingID": handlingID,
                        "signal": signal.rawValue
                    ]
                )
                break
            } catch {
                guard !Task.isCancelled, isCurrent(registration) else {
                    status = .cancelled
                    actionResults.append(
                        TVPowerActionResult(
                            action: action,
                            succeeded: false,
                            message: "Power action cancelled."
                        )
                    )
                    await diagnostics?.record(
                        kind: "power.action.cancelled",
                        details: [
                            "command": action.command.rawValue,
                            "deviceID": descriptor.id.uuidString,
                            "handlingID": handlingID,
                            "signal": signal.rawValue
                        ]
                    )
                    break
                }

                status = .failed
                actionResults.append(
                    TVPowerActionResult(
                        action: action,
                        succeeded: false,
                        message: error.localizedDescription
                    )
                )
                await diagnostics?.record(
                    kind: "power.action.failed",
                    details: [
                        "command": action.command.rawValue,
                        "deviceID": descriptor.id.uuidString,
                        "errorType": String(describing: type(of: error)),
                        "handlingID": handlingID,
                        "signal": signal.rawValue
                    ]
                )
                break
            }
        }

        if isConnected {
            await controller.disconnect()
        }

        return TVPowerExecutionResult(
            deviceID: descriptor.id,
            status: status,
            actions: actionResults
        )
    }

    private func isCurrent(_ registration: RegisteredController) -> Bool {
        controllers[registration.deviceID]?.generation == registration.generation
    }

    private func ensureCurrent(_ registration: RegisteredController) throws {
        guard !Task.isCancelled, isCurrent(registration) else {
            throw CancellationError()
        }
    }
}

private extension TVPowerCommand {
    var asTVCommand: TVCommand {
        switch self {
        case .powerOff: return .powerOff
        case .screenOff: return .screenOff
        case .screenOn: return .screenOn
        case .powerOn: return .powerOn
        }
    }
}
