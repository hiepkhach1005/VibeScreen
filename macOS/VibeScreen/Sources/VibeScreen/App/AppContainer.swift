import VibeScreenCore
import Foundation
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    @Published private(set) var presets: [Preset]
    @Published private(set) var devices: [TVDeviceDescriptor] = []
    @Published private(set) var deviceConnectionStates: [UUID: TVConnectionState] = [:]
    @Published private(set) var deviceConnectionMessages: [UUID: String] = [:]
    @Published private(set) var pendingCertificateFingerprints: [UUID: String] = [:]
    @Published private(set) var gamePresets: [GamePreset] = []
    @Published private(set) var displays: [MacDisplaySnapshot] = []
    @Published private(set) var lastExecutionStatus: PresetExecutionStatus?
    @Published private(set) var lastActionMessage = "Ready"
    @Published private(set) var nativeSettings = NativeAppSettings()
    @Published private(set) var globalTVShortcutStatus = "Starting…"

    let credentialStorageMode: CredentialStorageMode

    private let repository: any PresetRepository
    private let executionCoordinator: PresetExecutionCoordinator
    private let automationCoordinator: AutomationCoordinator
    private let presetActionRouter: PresetDeviceActionRouter
    private let powerCoordinator: TVPowerPolicyCoordinator
    private let gameWorkflowCoordinator: GameWorkflowCoordinator
    private let nativeStore: NativeStore?
    private let credentialStore: any TVCredentialStore
    private let powerDiagnostics: MacPowerDiagnosticRecorder
    private let globalTVShortcutManager = MacGlobalTVShortcutManager()
    private var tvControllers: [UUID: any TVDeviceController] = [:]
    private var remotes: [TVRemoteDefinition] = []
    private let displayService = MacDisplayService()
    private var platformEventSource: MacPlatformEventSource?
    private var platformEventTask: Task<Void, Never>?
    private var didRestoreTVConnections = false
    private var isPreparingForTermination = false

    init() {
        let powerDiagnostics = MacPowerDiagnosticRecorder()
        self.powerDiagnostics = powerDiagnostics
        let credentialStore = MigratingCredentialStore()
        self.credentialStore = credentialStore
        self.credentialStorageMode = credentialStore.mode

        let firstRunPreset = Preset(
            name: "Display refresh",
            shortcut: "⌥R",
            steps: [
                PresetStep(
                    rawValue: "DisplayRefresh",
                    step: "DisplayRefresh",
                    actionName: nil,
                    actionValue: nil,
                    parameters: nil,
                    delayMilliseconds: 0,
                    option: "",
                    action: .deviceCommand(target: "display", command: "refresh")
                )
            ],
            description: "A safe first-run preset for validating the native shell.",
            showInQuickAccess: true
        )

        let repository = InMemoryPresetRepository(presets: [firstRunPreset])
        self.repository = repository
        self.presets = [firstRunPreset]
        let wakeSender = MacWakeOnLANSender(diagnostics: powerDiagnostics)
        let presetActionRouter = PresetDeviceActionRouter(
            wakeOnLAN: wakeSender,
            applicationLauncher: MacApplicationLauncher(),
            displayController: MacPresetDisplayController(),
            diagnostics: powerDiagnostics
        )
        let executionCoordinator = PresetExecutionCoordinator(
            actionExecutor: presetActionRouter
        )
        self.executionCoordinator = executionCoordinator
        self.automationCoordinator = AutomationCoordinator(
            repository: repository,
            executionCoordinator: executionCoordinator
        )
        self.presetActionRouter = presetActionRouter
        self.powerCoordinator = TVPowerPolicyCoordinator(
            wakeOnLAN: wakeSender,
            diagnostics: powerDiagnostics
        )
        self.gameWorkflowCoordinator = GameWorkflowCoordinator(
            processLauncher: MacGameProcessLauncher(),
            actionExecutor: presetActionRouter
        )
        self.nativeStore = NativeStore.makeDefault()
        self.platformEventSource = nil
        self.platformEventTask = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            await reload()
            configureGlobalTVShortcuts()
            startPlatformEvents()
        }
    }

    func startPlatformEvents() {
        guard platformEventTask == nil, !isPreparingForTermination else { return }

        let source = MacPlatformEventSource(diagnostics: powerDiagnostics)
        platformEventSource = source
        platformEventTask = Task { [weak self, source] in
            for await signal in source.events {
                guard let self,
                      !Task.isCancelled,
                      !self.isPreparingForTermination else { return }

                let powerResults = await self.powerCoordinator.handle(signal: signal.kind)
                guard !Task.isCancelled, !self.isPreparingForTermination else { return }
                if !powerResults.isEmpty {
                    let failed = powerResults.contains { $0.status == .failed }
                    let cancelled = powerResults.contains { $0.status == .cancelled }
                    if failed {
                        VibeScreenLogger.automation.error("Automatic TV power action failed")
                        self.lastActionMessage = "Automatic TV power action needs attention"
                    } else if cancelled {
                        VibeScreenLogger.automation.info("Automatic TV power action cancelled")
                        self.lastActionMessage = "Automatic TV power action cancelled"
                    } else {
                        VibeScreenLogger.automation.info("Automatic TV power action completed")
                        self.lastActionMessage = "Automatic TV power action completed"
                    }
                }

                guard let automationEvent = signal.automationEvent else { continue }

                let results = await self.automationCoordinator.handle(
                    automationEvent,
                    context: signal.context
                )
                guard !Task.isCancelled, !self.isPreparingForTermination else { return }
                guard !results.isEmpty else { continue }

                let failed = results.contains { $0.status == .failed }
                if failed {
                    VibeScreenLogger.automation.error("Automatic preset execution failed")
                } else {
                    VibeScreenLogger.automation.info("Automatic preset execution completed")
                }
                self.lastExecutionStatus = failed ? .failed : .succeeded
                self.lastActionMessage = failed
                    ? "An automatic preset needs attention"
                    : "Automatic presets applied"
            }
        }
    }

    func stopPlatformEvents() {
        platformEventSource?.stop()
        platformEventTask?.cancel()
        platformEventTask = nil
        platformEventSource = nil
    }

    func prepareForTermination() {
        guard !isPreparingForTermination else { return }
        isPreparingForTermination = true
        stopPlatformEvents()
        globalTVShortcutManager.stop()
        VibeScreenLogger.app.info("Stopped platform events and shortcuts before termination")
    }

    func reload() async {
        do {
            if let nativeStore, let snapshot = try await nativeStore.load() {
                try await repository.replaceAll(snapshot.presets)
                presets = try await repository.all()
                devices = snapshot.devices
                nativeSettings = snapshot.settings
                gamePresets = snapshot.gamePresets
                remotes = snapshot.remotes
                await configureTVControllers(snapshot.devices)
                restoreTVConnectionsOnce(snapshot.devices)
                VibeScreenLogger.app.info("Loaded native VibeScreen state")
                lastActionMessage = "Native state loaded"
            } else {
                presets = try await repository.all()
                lastActionMessage = "Presets loaded"
            }
        } catch {
            VibeScreenLogger.app.error("Could not load native state: \(error.localizedDescription)")
            lastActionMessage = "Could not load presets: \(error.localizedDescription)"
        }
    }

    func refreshDisplays() {
        displays = displayService.snapshots()
    }

    func savePreset(_ preset: Preset) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.save(preset)
                presets = try await repository.all()
                try await persistNativeState()
                lastActionMessage = "Preset saved"
            } catch {
                VibeScreenLogger.app.error("Could not save preset: \(error.localizedDescription)")
                lastActionMessage = "Could not save preset: \(error.localizedDescription)"
            }
        }
    }

    func deletePreset(_ preset: Preset) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.delete(id: preset.id)
                presets = try await repository.all()
                try await persistNativeState()
                lastActionMessage = "Preset deleted"
            } catch {
                VibeScreenLogger.app.error("Could not delete preset: \(error.localizedDescription)")
                lastActionMessage = "Could not delete preset: \(error.localizedDescription)"
            }
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        nativeSettings.launchAtLogin = enabled
        nativeSettings.startHidden = enabled
        Task { [weak self] in
            guard let self else { return }
            do {
                try await persistNativeState()
            } catch {
                lastActionMessage = "Could not save launch-at-login setting: \(error.localizedDescription)"
            }
        }
    }

    func setLGLiveSyncEnabled(_ enabled: Bool) {
        nativeSettings.lgLiveSyncEnabled = enabled
        persistSettings(message: "LG live sync setting")
    }

    func setShowOverviewInSidebar(_ isVisible: Bool) {
        nativeSettings.showOverviewInSidebar = isVisible
        persistSettings(message: "Overview visibility setting")
    }

    func setLGLiveSyncIntervalSeconds(_ seconds: Int) {
        nativeSettings.lgLiveSyncIntervalSeconds = NativeAppSettings.clampedLGLiveSyncInterval(seconds)
        persistSettings(message: "LG live sync interval")
    }

    func setSystemMonitorIntervalMilliseconds(_ milliseconds: Int) {
        nativeSettings.systemMonitorIntervalMilliseconds = NativeAppSettings.clampedSystemMonitorInterval(
            milliseconds
        )
        persistSettings(message: "system monitor sampling interval")
    }

    func setSystemMonitorVisibleInSidebar(_ isVisible: Bool) {
        nativeSettings.showSystemMonitorInSidebar = isVisible
        persistSettings(message: "system monitor sidebar visibility")
    }

    private func persistSettings(message: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await persistNativeState()
            } catch {
                lastActionMessage = "Could not save \(message): \(error.localizedDescription)"
            }
        }
    }

    func saveDevice(_ device: TVDeviceDescriptor) {
        devices.removeAll { $0.id == device.id }
        devices.append(device)
        Task { [weak self] in
            guard let self else { return }
            await configureTVControllers(devices)
            do {
                try await persistNativeState()
                await testConnection(to: device)
            } catch {
                lastActionMessage = "Could not save TV device: \(error.localizedDescription)"
            }
        }
    }

    func updatePowerPolicy(_ policy: TVPowerPolicy, for device: TVDeviceDescriptor) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index].powerPolicy = policy
        let updatedDevice = devices[index]
        deviceConnectionStates[device.id] = .disconnected
        deviceConnectionMessages[device.id] = "Automation settings saved"

        Task { [weak self] in
            guard let self else { return }
            await replaceTVController(for: updatedDevice)
            do {
                try await persistNativeState()
                lastActionMessage = "Automation settings saved for \(device.name)"
            } catch {
                lastActionMessage = "Could not save automation settings: \(error.localizedDescription)"
            }
        }
    }

    func connectDevice(_ device: TVDeviceDescriptor) {
        Task { [weak self] in
            await self?.testConnection(to: device)
        }
    }

    func trustCertificateAndConnect(_ device: TVDeviceDescriptor) {
        guard let fingerprint = pendingCertificateFingerprints[device.id] else { return }
        var updatedDevice = device
        updatedDevice.trustedCertificateSHA256 = fingerprint
        pendingCertificateFingerprints.removeValue(forKey: device.id)
        saveDevice(updatedDevice)
    }

    func deleteDevice(_ device: TVDeviceDescriptor) {
        devices.removeAll { $0.id == device.id }
        Task { [weak self] in
            guard let self else { return }
            await configureTVControllers(devices)
            do {
                if let reference = device.credentialReference {
                    try credentialStore.delete(reference: reference)
                }
                try await persistNativeState()
                lastActionMessage = "TV device and pairing credential deleted"
            } catch {
                lastActionMessage = "Could not delete TV device: \(error.localizedDescription)"
            }
        }
    }

    func applyGame(_ preset: GamePreset) {
        lastActionMessage = "Launching \(preset.name)..."
        Task { [weak self] in
            guard let self else { return }
            let result = await gameWorkflowCoordinator.execute(preset)
            lastExecutionStatus = result.status == .succeeded ? .succeeded : (result.status == .cancelled ? .cancelled : .failed)
            lastActionMessage = result.status == .succeeded
                ? "Launched \(preset.name)"
                : "Game preset \(preset.name) needs attention"
        }
    }

    func apply(_ preset: Preset) {
        lastActionMessage = "Applying \(preset.name)…"

        Task { [weak self] in
            guard let self else { return }
            let result = await executionCoordinator.execute(preset)
            lastExecutionStatus = result.status
            refreshDisplays()

            switch result.status {
            case .succeeded:
                lastActionMessage = "Applied \(preset.name)"
            case .failed:
                lastActionMessage = "\(preset.name) needs attention"
            case .cancelled:
                lastActionMessage = "Cancelled \(preset.name)"
            }
        }
    }

    func sendDeviceCommand(
        _ command: String,
        to device: TVDeviceDescriptor,
        origin: String = "userInterface"
    ) {
        lastActionMessage = "Sending \(command) to \(device.name)…"
        deviceConnectionStates[device.id] = .connecting
        deviceConnectionMessages[device.id] = "Connecting to TV…"
        Task { [weak self] in
            guard let self else { return }
            await powerDiagnostics.record(
                kind: "manual.command.started",
                details: [
                    "command": command,
                    "deviceID": device.id.uuidString,
                    "origin": origin
                ]
            )
            do {
                if let powerCommand = Self.manualPowerCommand(for: command) {
                    await powerCoordinator.recordManualPowerAction(powerCommand, for: device.id)
                    await presetActionRouter.recordManualPowerAction(powerCommand, for: device.id)
                }
                try await presetActionRouter.execute(
                    .deviceCommand(target: device.host, command: command)
                )
                deviceConnectionStates[device.id] = .connected
                deviceConnectionMessages[device.id] = "Command completed"
                lastActionMessage = "Sent \(command) to \(device.name)"
                await powerDiagnostics.record(
                    kind: "manual.command.succeeded",
                    details: [
                        "command": command,
                        "deviceID": device.id.uuidString,
                        "origin": origin
                    ]
                )
            } catch {
                VibeScreenLogger.protocolIO.error("TV command failed: \(error.localizedDescription)")
                setConnectionFailure(error, for: device)
                lastActionMessage = "TV command failed: \(error.localizedDescription)"
                await powerDiagnostics.record(
                    kind: "manual.command.failed",
                    details: [
                        "command": command,
                        "deviceID": device.id.uuidString,
                        "errorType": String(describing: type(of: error)),
                        "origin": origin
                    ]
                )
            }
        }
    }

    private func configureGlobalTVShortcuts() {
        do {
            try startGlobalTVShortcuts(using: nativeSettings)
            globalTVShortcutStatus = "Active"
        } catch {
            globalTVShortcutStatus = error.localizedDescription
            VibeScreenLogger.app.error("Global TV shortcut registration failed")
        }
    }

    func updateTVPowerToggleShortcut(_ shortcut: GlobalKeyboardShortcut) -> String? {
        let previousSettings = nativeSettings
        var candidateSettings = nativeSettings
        candidateSettings.tvPowerToggleShortcut = shortcut

        do {
            try startGlobalTVShortcuts(using: candidateSettings)
            nativeSettings = candidateSettings
            globalTVShortcutStatus = "Active"
            persistSettings(message: "TV keyboard shortcut")
            return nil
        } catch {
            let updateError = error.localizedDescription
            do {
                try startGlobalTVShortcuts(using: previousSettings)
                globalTVShortcutStatus = "Active"
            } catch {
                globalTVShortcutStatus = error.localizedDescription
                VibeScreenLogger.app.error("Could not restore previous global TV shortcuts")
            }
            return updateError
        }
    }

    private func startGlobalTVShortcuts(using settings: NativeAppSettings) throws {
        try globalTVShortcutManager.start(
            toggle: settings.tvPowerToggleShortcut,
            onToggle: { [weak self] in
                self?.togglePowerForFirstTV()
            }
        )
    }

    private func togglePowerForFirstTV() {
        guard let device = devices.first else {
            lastActionMessage = "Add a TV before using the power toggle shortcut."
            return
        }
        guard let controller = tvControllers[device.id] else {
            lastActionMessage = "The first TV controller is unavailable."
            return
        }

        deviceConnectionStates[device.id] = .connecting
        deviceConnectionMessages[device.id] = "Reading the current TV power state…"
        lastActionMessage = "Checking \(device.name) power state…"

        Task { [weak self] in
            guard let self else { return }
            await powerDiagnostics.record(
                kind: "shortcut.toggle.invoked",
                details: ["deviceID": device.id.uuidString]
            )

            // A TV may stop answering protocol requests as soon as it enters
            // standby. The coordinator already knows when this app explicitly
            // powered it off, so use the safe WOL path immediately instead of
            // waiting for a state request that cannot succeed.
            if await powerCoordinator.isManuallyPoweredOff(deviceID: device.id) {
                sendSafePowerOn(
                    to: device,
                    reason: "The TV was just powered off",
                    origin: "shortcut.manualOffLatch"
                )
                return
            }

            do {
                let powerState = try await controller.readPowerState()
                deviceConnectionStates[device.id] = .connected

                switch powerState {
                case .on:
                    sendDeviceCommand("PowerOff", to: device, origin: "shortcut.liveStateOn")
                case .off:
                    sendDeviceCommand("PowerOn", to: device, origin: "shortcut.liveStateOff")
                case .unknown:
                    sendSafePowerOn(
                        to: device,
                        reason: "The TV power state is unavailable",
                        origin: "shortcut.liveStateUnknown"
                    )
                }
            } catch {
                VibeScreenLogger.protocolIO.error("TV power state read failed: \(error.localizedDescription)")
                sendSafePowerOn(
                    to: device,
                    reason: "Could not read the TV power state",
                    origin: "shortcut.stateReadFailed"
                )
            }
        }
    }

    private func sendSafePowerOn(
        to device: TVDeviceDescriptor,
        reason: String,
        origin: String
    ) {
        deviceConnectionStates[device.id] = .connecting
        deviceConnectionMessages[device.id] = "Power state unavailable; sending Wake-on-LAN…"
        lastActionMessage = "\(reason) for \(device.name); trying safe power-on…"
        sendDeviceCommand("PowerOn", to: device, origin: origin)
    }

    func sendLGControl(_ control: LGControlDescriptor, value rawValue: String, to device: TVDeviceDescriptor) {
        Task { [weak self] in
            _ = await self?.applyLGControl(control, value: rawValue, to: device)
        }
    }

    func applyLGControl(
        _ control: LGControlDescriptor,
        value rawValue: String,
        to device: TVDeviceDescriptor
    ) async -> Bool {
        do {
            let value = try control.validatedValue(rawValue)
            let command: TVCommand
            if control.id == "audioVolume", let volume = Int(rawValue) {
                command = .setVolume(volume)
            } else {
                command = .setLGSystemSetting(
                    category: control.category,
                    name: control.id,
                    value: value
                )
            }
            try await executeTypedDeviceCommand(command, label: control.title, on: device)
            return true
        } catch {
            setConnectionFailure(error, for: device)
            lastActionMessage = "TV command failed: \(error.localizedDescription)"
            return false
        }
    }

    func sendTypedDeviceCommand(_ command: TVCommand, label: String, to device: TVDeviceDescriptor) {
        Task { [weak self] in
            _ = await self?.applyTypedDeviceCommand(command, label: label, to: device)
        }
    }

    func applyTypedDeviceCommand(
        _ command: TVCommand,
        label: String,
        to device: TVDeviceDescriptor
    ) async -> Bool {
        do {
            try await executeTypedDeviceCommand(command, label: label, on: device)
            return true
        } catch {
            lastActionMessage = "TV command failed: \(error.localizedDescription)"
            return false
        }
    }

    private func executeTypedDeviceCommand(
        _ command: TVCommand,
        label: String,
        on device: TVDeviceDescriptor
    ) async throws {
        lastActionMessage = "Sending \(label) to \(device.name)…"
        deviceConnectionStates[device.id] = .connecting
        deviceConnectionMessages[device.id] = "Connecting to TV…"
        do {
            if let powerCommand = Self.manualPowerCommand(for: command) {
                await powerCoordinator.recordManualPowerAction(powerCommand, for: device.id)
                await presetActionRouter.recordManualPowerAction(powerCommand, for: device.id)
            }
            try await presetActionRouter.execute(command, target: device.id.uuidString)
            deviceConnectionStates[device.id] = .connected
            deviceConnectionMessages[device.id] = "\(label) completed"
            lastActionMessage = "\(label) applied to \(device.name)"
        } catch {
            VibeScreenLogger.protocolIO.error("TV command failed: \(error.localizedDescription)")
            setConnectionFailure(error, for: device)
            throw error
        }
    }

    private static func manualPowerCommand(for command: TVCommand) -> TVPowerCommand? {
        switch command {
        case .powerOn: return .powerOn
        case .powerOff: return .powerOff
        case .screenOn: return .screenOn
        case .screenOff: return .screenOff
        default: return nil
        }
    }

    private static func manualPowerCommand(for rawCommand: String) -> TVPowerCommand? {
        switch rawCommand
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        {
        case "poweron", "turnon", "wake": return .powerOn
        case "poweroff", "turnoff", "shutdown": return .powerOff
        case "screenon", "turnscreenon": return .screenOn
        case "screenoff", "turnscreenoff": return .screenOff
        default: return nil
        }
    }

    func loadLGLiveValues(for device: TVDeviceDescriptor) async -> [String: String] {
        guard let client = tvControllers[device.id] as? LGWebOSDeviceClient else { return [:] }
        do {
            try await client.connect()
            var result: [String: String] = [:]
            let gameBarControls = LGControlCatalog.controls(in: .gameBar)
            // Keep the periodic reads independent. Some LG models reject one
            // or more picture keys; that must not prevent the volume read from
            // reaching the TV or erase a previously useful partial snapshot.
            do {
                let settings = try await client.readSystemSettings(
                    category: "picture",
                    keys: gameBarControls.map(\.id)
                )
                for control in gameBarControls {
                    if let value = Self.lgSettingValue(for: control.id, in: settings) {
                        result[control.id] = value
                    }
                }
            } catch { /* Keep the independent volume read alive. */ }
            do {
                result["audioVolume"] = String(try await client.readVolume())
            } catch { /* Preserve any picture values that were read successfully. */ }
            await client.disconnect()
            return result
        } catch {
            await client.disconnect()
            return [:]
        }
    }

    func loadLGControlValues(for device: TVDeviceDescriptor) async -> LGControlSnapshot {
        guard let client = tvControllers[device.id] as? LGWebOSDeviceClient else {
            deviceConnectionMessages[device.id] = "LG control read-back is unavailable."
            return LGControlSnapshot()
        }

        deviceConnectionMessages[device.id] = "Reading current LG settings…"
        do {
            try await client.connect()
            var result: [String: String] = [:]
            var readFailures = 0
            let gameBarControls = LGControlCatalog.controls(in: .gameBar)
            do {
                let settings = try await client.readSystemSettings(
                    category: "picture",
                    keys: gameBarControls.map(\.id)
                )
                for control in gameBarControls {
                    if let value = Self.lgSettingValue(for: control.id, in: settings) {
                        result[control.id] = value
                    }
                }
            } catch {
                readFailures += 1
            }

            let categories = Dictionary(grouping: LGControlCatalog.controls, by: \.category)
            let orderedCategories = ["picture", "other", "aiPicture", "aspectRatio", "sound", "network"]
            for category in orderedCategories {
                guard let categoryControls = categories[category] else { continue }
                let controls = categoryControls.filter { $0.group != .gameBar && $0.id != "audioVolume" }
                guard !controls.isEmpty else { continue }
                let keys = Array(Set(controls.map { control in
                    control.id.split(separator: "_", maxSplits: 1).first.map(String.init) ?? control.id
                })).sorted()
                do {
                    let settings = try await client.readSystemSettings(category: category, keys: keys)
                    for control in controls {
                        if let value = Self.lgSettingValue(for: control.id, in: settings) {
                            result[control.id] = value
                        }
                    }
                } catch {
                    readFailures += 1
                }
            }
            do {
                result["audioVolume"] = String(try await client.readVolume())
            } catch {
                readFailures += 1
            }
            let applications: [LGNamedResource]
            do {
                applications = try await client.listApplications()
            } catch {
                applications = []
                readFailures += 1
            }
            let inputs: [LGNamedResource]
            do {
                inputs = try await client.listInputs()
            } catch {
                inputs = []
                readFailures += 1
            }
            await client.disconnect()
            deviceConnectionStates[device.id] = .connected
            deviceConnectionMessages[device.id] = readFailures == 0
                ? "Current LG settings loaded"
                : "LG settings loaded where supported; this TV rejected \(readFailures) setting groups."
            return LGControlSnapshot(values: result, applications: applications, inputs: inputs)
        } catch {
            await client.disconnect()
            setConnectionFailure(error, for: device)
            return LGControlSnapshot()
        }
    }

    private static func lgSettingValue(for name: String, in settings: [String: JSONValue]) -> String? {
        let value: JSONValue?
        if let direct = settings[name] {
            value = direct
        } else if let separator = name.firstIndex(of: "_") {
            let parent = String(name[..<separator])
            let child = String(name[name.index(after: separator)...])
            if case let .object(children)? = settings[parent] {
                value = children[child]
            } else {
                value = nil
            }
        } else {
            value = nil
        }

        switch value {
        case let .string(raw): return raw
        case let .number(raw): return raw.rounded() == raw ? String(Int(raw)) : String(raw)
        case let .bool(raw): return raw ? "true" : "false"
        case let .array(values):
            let rendered = values.compactMap { item -> String? in
                switch item {
                case let .number(raw): return raw.rounded() == raw ? String(Int(raw)) : String(raw)
                case let .string(raw): return raw
                default: return nil
                }
            }
            return rendered.count == values.count ? rendered.joined(separator: ",") : nil
        case .null, .object, nil: return nil
        }
    }

    private func testConnection(to device: TVDeviceDescriptor) async {
        guard let controller = tvControllers[device.id] else {
            deviceConnectionStates[device.id] = .failed
            deviceConnectionMessages[device.id] = "The device controller is unavailable."
            return
        }

        deviceConnectionStates[device.id] = .connecting
        deviceConnectionMessages[device.id] = device.kind == .lgWebOS
            ? "Connecting with the saved pairing key… TV approval is only needed the first time."
            : "Connecting and waiting for TV authorization…"
        lastActionMessage = "Testing connection to \(device.name)…"

        do {
            try await controller.connect()
            await controller.disconnect()
            deviceConnectionStates[device.id] = .connected
            deviceConnectionMessages[device.id] = "Paired and reachable"
            pendingCertificateFingerprints.removeValue(forKey: device.id)
            lastActionMessage = "Connected to \(device.name)"
        } catch {
            setConnectionFailure(error, for: device)
            lastActionMessage = "Could not connect to \(device.name): \(error.localizedDescription)"
        }
    }

    private func restoreTVConnectionsOnce(_ descriptors: [TVDeviceDescriptor]) {
        guard !didRestoreTVConnections else { return }
        didRestoreTVConnections = true

        for descriptor in descriptors {
            Task { @MainActor [weak self] in
                await self?.testConnection(to: descriptor)
            }
        }
    }

    private func setConnectionFailure(_ error: Error, for device: TVDeviceDescriptor) {
        if case let TVProtocolError.untrustedCertificate(fingerprint) = error {
            deviceConnectionStates[device.id] = .pairingRequired
            deviceConnectionMessages[device.id] = "Verify the certificate fingerprint below, then choose Trust certificate & retry.\n\(fingerprint)"
            pendingCertificateFingerprints[device.id] = fingerprint
            return
        }

        pendingCertificateFingerprints.removeValue(forKey: device.id)
        if let protocolError = error as? TVProtocolError,
           protocolError == .pairingRequired || protocolError == .pairingTimedOut {
            deviceConnectionStates[device.id] = .pairingRequired
        } else {
            deviceConnectionStates[device.id] = .failed
        }

        if device.kind == .lgWebOS && device.usesSecureConnection {
            deviceConnectionMessages[device.id] = "\(error.localizedDescription) If this LG uses a local certificate, edit it and turn off Secure connection to try ws:3000."
        } else {
            deviceConnectionMessages[device.id] = error.localizedDescription
        }
    }

    private func configureTVControllers(_ descriptors: [TVDeviceDescriptor]) async {
        for controller in tvControllers.values {
            await controller.disconnect()
        }
        tvControllers.removeAll()
        await presetActionRouter.removeAll()
        await powerCoordinator.removeAll()

        for descriptor in descriptors {
            await registerTVController(for: descriptor)
        }
    }

    private func replaceTVController(for descriptor: TVDeviceDescriptor) async {
        await powerCoordinator.invalidatePendingActions(for: descriptor.id)
        if let existing = tvControllers[descriptor.id] {
            await existing.disconnect()
        }
        await registerTVController(for: descriptor)
    }

    private func registerTVController(for descriptor: TVDeviceDescriptor) async {
        let controller: any TVDeviceController
        switch descriptor.kind {
        case .lgWebOS:
            controller = LGWebOSDeviceClient(
                device: descriptor,
                transport: MacTVWebSocketTransport(credentials: credentialStore),
                credentials: credentialStore
            )
        case .samsungTizen:
            controller = SamsungTizenDeviceClient(
                device: descriptor,
                transport: MacTVWebSocketTransport(credentials: credentialStore),
                credentials: credentialStore
            )
        }

        tvControllers[descriptor.id] = controller
        await presetActionRouter.register(controller)
        await powerCoordinator.register(controller)
    }

    private func persistNativeState() async throws {
        guard let nativeStore else { return }
        try await nativeStore.save(
            NativeStoreSnapshot(
                presets: presets,
                devices: devices,
                gamePresets: gamePresets,
                remotes: remotes,
                settings: nativeSettings
            )
        )
    }
}
