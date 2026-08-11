import Foundation

public protocol PresetApplicationLauncher: Sendable {
    func launch(bundleIdentifier: String) async throws
}

public protocol PresetDisplayController: Sendable {
    func refresh() async throws
}

/// Routes the subset of legacy preset actions that has a public native
/// equivalent. Unknown actions fail visibly so a migrated preset cannot claim
/// success while silently doing nothing.
public actor PresetDeviceActionRouter: PresetActionExecutor {
    private var controllers: [UUID: any TVDeviceController] = [:]
    private let wakeOnLAN: (any WakeOnLANSender)?
    private let applicationLauncher: (any PresetApplicationLauncher)?
    private let displayController: (any PresetDisplayController)?

    public init(
        wakeOnLAN: (any WakeOnLANSender)? = nil,
        applicationLauncher: (any PresetApplicationLauncher)? = nil,
        displayController: (any PresetDisplayController)? = nil
    ) {
        self.wakeOnLAN = wakeOnLAN
        self.applicationLauncher = applicationLauncher
        self.displayController = displayController
    }

    public func register(_ controller: any TVDeviceController) async {
        let descriptor = await controller.deviceDescriptor()
        controllers[descriptor.id] = controller
    }

    public func removeAll() {
        controllers.removeAll()
    }

    public func execute(_ action: PresetStepAction) async throws {
        switch action {
        case let .deviceCommand(target, command):
            if target.caseInsensitiveCompare("display") == .orderedSame,
               command.caseInsensitiveCompare("refresh") == .orderedSame {
                guard let displayController else {
                    throw ColorControlCoreError.actionRejected("Display control is unavailable.")
                }
                try await displayController.refresh()
                return
            }
            let selected = try await selectedControllers(matching: target)
            if commandName(command).caseInsensitiveCompare("wol") == .orderedSame {
                try await wake(selected)
                return
            }
            let tvCommand = try commandFromLegacy(command)
            if case .powerOn = tvCommand {
                try await wake(selected)
            } else {
                try await execute(tvCommand, on: selected)
            }

        case let .legacy(name, value):
            if name.caseInsensitiveCompare("DisplayRefresh") == .orderedSame {
                guard let displayController else {
                    throw ColorControlCoreError.actionRejected("Display control is unavailable.")
                }
                try await displayController.refresh()
                return
            }
            let selected = Array(controllers.values)
            guard !selected.isEmpty else {
                throw ColorControlCoreError.actionRejected("No TV device is configured for action \(name).")
            }
            if name.caseInsensitiveCompare("wol") == .orderedSame {
                try await wake(selected)
                return
            }
            let command = try commandFromLegacy(value.map { "\(name)(\($0))" } ?? name)
            if case .powerOn = command {
                try await wake(selected)
            } else {
                try await execute(command, on: selected)
            }

        case .wait:
            return
        case let .launchApplication(identifier):
            guard let applicationLauncher else {
                throw ColorControlCoreError.actionRejected("Application launch is unavailable: \(identifier).")
            }
            try await applicationLauncher.launch(bundleIdentifier: identifier)
        case let .setDisplayProfile(identifier):
            throw ColorControlCoreError.actionRejected(
                "Display profile action needs a verified ColorSync adapter: \(identifier)."
            )
        }
    }

    private func selectedControllers(matching target: String) async throws -> [any TVDeviceController] {
        let all = Array(controllers.values)
        if target == "*" || target.caseInsensitiveCompare("all") == .orderedSame {
            guard !all.isEmpty else {
                throw ColorControlCoreError.actionRejected("No TV device is configured.")
            }
            return all
        }

        var matches: [any TVDeviceController] = []
        for controller in all {
            let descriptor = await controller.deviceDescriptor()
            let values = [
                descriptor.id.uuidString,
                descriptor.name,
                descriptor.host,
                descriptor.macAddress ?? "",
                descriptor.kind.rawValue
            ]
            if values.contains(where: { $0.caseInsensitiveCompare(target) == .orderedSame }) {
                matches.append(controller)
            }
        }

        guard !matches.isEmpty else {
            throw ColorControlCoreError.actionRejected("No TV matches preset target \(target).")
        }
        return matches
    }

    private func commandFromLegacy(_ raw: String) throws -> TVCommand {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let name: String
        let value: String?
        if let opening = trimmed.firstIndex(of: "("),
           let closing = trimmed.lastIndex(of: ")"),
           closing > opening {
            name = String(trimmed[..<opening])
            value = String(trimmed[trimmed.index(after: opening)..<closing])
        } else {
            name = trimmed
            value = nil
        }

        switch name.lowercased() {
        case "poweron", "turnon", "wake": return .powerOn
        case "poweroff", "turnoff", "shutdown": return .powerOff
        case "turnscreenoff", "screenoff": return .screenOff
        case "turnscreenon", "screenon": return .screenOn
        case "volumeup": return .volumeUp
        case "volumedown": return .volumeDown
        case "volume", "audiovolume":
            guard let value, let volume = Int(value) else {
                throw ColorControlCoreError.actionRejected("Volume needs an integer value.")
            }
            return .setVolume(volume)
        case "mute":
            return .mute((value ?? "true").lowercased() == "true" || value == "1" || value == "on")
        case "launch", "launchapplication":
            guard let value, !value.isEmpty else {
                throw ColorControlCoreError.actionRejected("LaunchApplication needs an identifier.")
            }
            return .launchApplication(identifier: value, parameters: nil)
        case "wol":
            throw ColorControlCoreError.actionRejected("Wake-on-LAN needs a device target.")
        default:
            guard !name.isEmpty else {
                throw ColorControlCoreError.actionRejected("Preset action is empty.")
            }
            return .remoteKey(name)
        }
    }

    private func commandName(_ raw: String) -> String {
        guard let opening = raw.firstIndex(of: "(") else { return raw }
        return String(raw[..<opening])
    }

    private func wake(_ controllers: [any TVDeviceController]) async throws {
        guard let wakeOnLAN else {
            throw ColorControlCoreError.actionRejected("Wake-on-LAN is unavailable.")
        }

        for controller in controllers {
            let descriptor = await controller.deviceDescriptor()
            guard let macAddress = descriptor.macAddress, !macAddress.isEmpty else {
                throw ColorControlCoreError.actionRejected(
                    "Device \(descriptor.name) has no MAC address for Wake-on-LAN."
                )
            }
            try await wakeOnLAN.send(
                macAddress: macAddress,
                broadcastAddress: "255.255.255.255",
                port: 9
            )
        }
    }

    private func execute(
        _ command: TVCommand,
        on controllers: [any TVDeviceController]
    ) async throws {
        for controller in controllers {
            try await controller.connect()
            do {
                try await controller.execute(command)
            } catch {
                await controller.disconnect()
                throw error
            }
            await controller.disconnect()
        }
    }
}
