import Foundation

public protocol TVDeviceController: Sendable {
    func deviceDescriptor() async -> TVDeviceDescriptor
    func connect() async throws
    func execute(_ command: TVCommand) async throws
    func disconnect() async
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
    private var controllers: [UUID: any TVDeviceController] = [:]
    private let wakeOnLAN: (any WakeOnLANSender)?
    private let clock: any TVPowerActionClock

    public init(
        wakeOnLAN: (any WakeOnLANSender)? = nil,
        clock: any TVPowerActionClock = SystemTVPowerActionClock()
    ) {
        self.wakeOnLAN = wakeOnLAN
        self.clock = clock
    }

    public func register(_ controller: any TVDeviceController) async {
        let descriptor = await controller.deviceDescriptor()
        controllers[descriptor.id] = controller
    }

    public func remove(deviceID: UUID) {
        controllers.removeValue(forKey: deviceID)
    }

    public func removeAll() {
        controllers.removeAll()
    }

    public func handle(signal: PlatformSignalKind) async -> [TVPowerExecutionResult] {
        let registeredControllers = Array(controllers.values)
        var results: [TVPowerExecutionResult] = []

        for controller in registeredControllers {
            let descriptor = await controller.deviceDescriptor()
            let actions = TVPowerPolicyEngine.actions(for: signal, device: descriptor)
            guard !actions.isEmpty else { continue }

            results.append(
                await execute(
                    actions,
                    for: descriptor,
                    using: controller
                )
            )
        }

        return results
    }

    private func execute(
        _ actions: [TVPowerAction],
        for descriptor: TVDeviceDescriptor,
        using controller: any TVDeviceController
    ) async -> TVPowerExecutionResult {
        var actionResults: [TVPowerActionResult] = []
        var status: TVPowerExecutionStatus = .succeeded
        var isConnected = false

        for action in actions {
            do {
                try await clock.sleep(for: action.delaySeconds)

                switch action.command {
                case .powerOn:
                    guard let macAddress = descriptor.macAddress, !macAddress.isEmpty else {
                        throw TVPowerCoordinatorError.missingMacAddress
                    }
                    guard let wakeOnLAN else {
                        throw TVPowerCoordinatorError.wakeOnLANUnavailable
                    }
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
                    try await controller.execute(command.asTVCommand)
                }

                actionResults.append(TVPowerActionResult(action: action, succeeded: true))
            } catch is CancellationError {
                status = .cancelled
                actionResults.append(
                    TVPowerActionResult(
                        action: action,
                        succeeded: false,
                        message: "Power action cancelled."
                    )
                )
                break
            } catch {
                status = .failed
                actionResults.append(
                    TVPowerActionResult(
                        action: action,
                        succeeded: false,
                        message: error.localizedDescription
                    )
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
