import ColorControlCore
import Foundation
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    @Published private(set) var presets: [Preset]
    @Published private(set) var devices: [TVDeviceDescriptor] = []
    @Published private(set) var gamePresets: [GamePreset] = []
    @Published private(set) var displays: [MacDisplaySnapshot] = []
    @Published private(set) var lastExecutionStatus: PresetExecutionStatus?
    @Published private(set) var lastActionMessage = "Ready"

    private let repository: any PresetRepository
    private let executionCoordinator: PresetExecutionCoordinator
    private let automationCoordinator: AutomationCoordinator
    private let presetActionRouter: PresetDeviceActionRouter
    private let powerCoordinator: TVPowerPolicyCoordinator
    private let gameWorkflowCoordinator: GameWorkflowCoordinator
    private let nativeStore: NativeStore?
    private var tvControllers: [UUID: any TVDeviceController] = [:]
    private var nativeSettings = NativeAppSettings()
    private var remotes: [TVRemoteDefinition] = []
    private let displayService = MacDisplayService()
    private var platformEventSource: MacPlatformEventSource?
    private var platformEventTask: Task<Void, Never>?

    init() {
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
        let wakeSender = MacWakeOnLANSender()
        let presetActionRouter = PresetDeviceActionRouter(
            wakeOnLAN: wakeSender,
            applicationLauncher: MacApplicationLauncher(),
            displayController: MacPresetDisplayController()
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
            wakeOnLAN: wakeSender
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
            startPlatformEvents()
        }
    }

    func startPlatformEvents() {
        guard platformEventTask == nil else { return }

        let source = MacPlatformEventSource()
        platformEventSource = source
        platformEventTask = Task { [weak self, source] in
            for await signal in source.events {
                guard let self else { return }

                let powerResults = await self.powerCoordinator.handle(signal: signal.kind)
                if !powerResults.isEmpty {
                    let failed = powerResults.contains { $0.status == .failed }
                    if failed {
                        ColorControlLogger.automation.error("Automatic TV power action failed")
                    } else {
                        ColorControlLogger.automation.info("Automatic TV power action completed")
                    }
                    self.lastActionMessage = failed
                        ? "Automatic TV power action needs attention"
                        : "Automatic TV power action completed"
                }

                guard let automationEvent = signal.automationEvent else { continue }

                let results = await self.automationCoordinator.handle(
                    automationEvent,
                    context: signal.context
                )
                guard !results.isEmpty else { continue }

                let failed = results.contains { $0.status == .failed }
                if failed {
                    ColorControlLogger.automation.error("Automatic preset execution failed")
                } else {
                    ColorControlLogger.automation.info("Automatic preset execution completed")
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
                ColorControlLogger.app.info("Loaded native ColorControl state")
                lastActionMessage = "Native state loaded"
            } else {
                presets = try await repository.all()
                lastActionMessage = "Presets loaded"
            }
        } catch {
            ColorControlLogger.app.error("Could not load native state: \(error.localizedDescription)")
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
                ColorControlLogger.app.error("Could not save preset: \(error.localizedDescription)")
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
                ColorControlLogger.app.error("Could not delete preset: \(error.localizedDescription)")
                lastActionMessage = "Could not delete preset: \(error.localizedDescription)"
            }
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        nativeSettings.launchAtLogin = enabled
        Task { [weak self] in
            guard let self else { return }
            do {
                try await persistNativeState()
            } catch {
                lastActionMessage = "Could not save launch-at-login setting: \(error.localizedDescription)"
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
                lastActionMessage = "TV device saved"
            } catch {
                lastActionMessage = "Could not save TV device: \(error.localizedDescription)"
            }
        }
    }

    func deleteDevice(_ device: TVDeviceDescriptor) {
        devices.removeAll { $0.id == device.id }
        Task { [weak self] in
            guard let self else { return }
            await configureTVControllers(devices)
            do {
                try await persistNativeState()
                lastActionMessage = "TV device deleted"
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

    func sendDeviceCommand(_ command: String, to device: TVDeviceDescriptor) {
        lastActionMessage = "Sending \(command) to \(device.name)…"
        Task { [weak self] in
            guard let self else { return }
            do {
                try await presetActionRouter.execute(
                    .deviceCommand(target: device.host, command: command)
                )
                lastActionMessage = "Sent \(command) to \(device.name)"
            } catch {
                ColorControlLogger.protocolIO.error("TV command failed: \(error.localizedDescription)")
                lastActionMessage = "TV command failed: \(error.localizedDescription)"
            }
        }
    }

    private func configureTVControllers(_ descriptors: [TVDeviceDescriptor]) async {
        tvControllers.removeAll()
        await presetActionRouter.removeAll()
        await powerCoordinator.removeAll()

        for descriptor in descriptors {
            let controller: any TVDeviceController
            switch descriptor.kind {
            case .lgWebOS:
                controller = LGWebOSDeviceClient(device: descriptor)
            case .samsungTizen:
                controller = SamsungTizenDeviceClient(device: descriptor)
            }

            tvControllers[descriptor.id] = controller
            await presetActionRouter.register(controller)
            await powerCoordinator.register(controller)
        }
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
