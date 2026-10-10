import ColorControlCore
import Foundation

/// LG client boundary: registration is sent as the first message and the
/// returned client key is immediately moved to the configured credential store.
actor LGWebOSDeviceClient: TVDeviceController {
    private let device: TVDeviceDescriptor
    private let transport: any TVTransport
    private let credentials: any TVCredentialStore
    private var requestFactory = LGWebOSRequestFactory()
    private var pointerTransport: MacLGPointerWebSocketTransport? = nil
    private var cachedClientKey: String?
    private var didLoadClientKey = false

    init(
        device: TVDeviceDescriptor,
        transport: any TVTransport = MacTVWebSocketTransport(),
        credentials: any TVCredentialStore = MigratingCredentialStore()
    ) {
        self.device = device
        self.transport = transport
        self.credentials = credentials
    }

    func deviceDescriptor() async -> TVDeviceDescriptor {
        device
    }

    func connect() async throws {
        do {
            try await transport.connect(to: device)

            let existingKey = try storedClientKey()

            let registration = LGWebOSRegistration.makeMessage(clientKey: existingKey)
            let data = try JSONEncoder().encode(registration)
            guard let response = try await transport.send(data) else {
                throw TVProtocolError.malformedMessage
            }

            if let newKey = try await registeredClientKey(initialResponse: response),
               let reference = device.credentialReference {
                try credentials.save(newKey, reference: reference)
                cachedClientKey = newKey
                didLoadClientKey = true
            } else if existingKey == nil {
                throw TVProtocolError.pairingRequired
            }
        } catch {
            await transport.disconnect()
            throw error
        }
    }

    private func storedClientKey() throws -> String? {
        if didLoadClientKey { return cachedClientKey }
        defer { didLoadClientKey = true }
        guard let reference = device.credentialReference else { return nil }
        let key = try credentials.read(reference: reference)
        cachedClientKey = key
        return key
    }

    func readPowerState() async throws -> TVPowerState {
        try await connect()
        do {
            let request = LGWebOSCommand.getPowerState.makeRequest(using: &requestFactory)
            guard let response = try await transport.send(JSONEncoder().encode(request)) else {
                throw TVProtocolError.malformedMessage
            }
            let value = try JSONDecoder().decode(JSONValue.self, from: response)
            guard let state = LGPowerStateParser.parse(value) else {
                throw TVProtocolError.powerStateUnavailable
            }
            await disconnect()
            return state
        } catch {
            await disconnect()
            throw error
        }
    }

    func execute(_ command: TVCommand) async throws {
        let lgCommand: LGWebOSCommand
        switch command {
        case .powerOn:
            throw TVProtocolError.unsupportedCommand(command)
        case .powerOff:
            lgCommand = .powerOff
        case .screenOff:
            lgCommand = .screenOff
        case .screenOn:
            lgCommand = .screenOn
        case .volumeUp:
            lgCommand = .volumeUp
        case .volumeDown:
            lgCommand = .volumeDown
        case let .setVolume(value):
            lgCommand = .setVolume(value)
        case let .mute(value):
            lgCommand = .mute(value)
        case let .setPictureSetting(name, value):
            try await executePictureSetting(name: name, value: value)
            return
        case let .setLGSystemSetting(category, name, value):
            try await executeSystemSetting(category: category, name: name, value: value)
            return
        case .reboot:
            lgCommand = .reboot
        case .mediaPlay:
            lgCommand = .mediaPlay
        case .mediaPause:
            lgCommand = .mediaPause
        case .mediaStop:
            lgCommand = .mediaStop
        case .channelUp:
            lgCommand = .channelUp
        case .channelDown:
            lgCommand = .channelDown
        case let .setInput(identifier):
            lgCommand = .setInput(identifier)
        case let .openURL(url):
            lgCommand = .openURL(url)
        case let .closeApplication(identifier):
            lgCommand = .closeApplication(identifier)
        case let .setLGOLEDProtection(name, enabled):
            try await executeOLEDProtection(name: name, enabled: enabled)
            return
        case let .setLGHDMIIcon(port, icon, label):
            try await executeHDMIIcon(port: port, icon: icon, label: label)
            return
        case let .launchApplication(identifier, parameters):
            lgCommand = .launchApplication(identifier: identifier, parameters: parameters)
        case let .remoteKey(key):
            try await executeRemoteKey(key)
            return
        }

        let request = lgCommand.makeRequest(using: &requestFactory)
        let data = try JSONEncoder().encode(request)
        _ = try await transport.send(data)
    }

    func disconnect() async {
        await pointerTransport?.disconnect()
        pointerTransport = nil
        await transport.disconnect()
    }

    func readSystemSettings(category: String, keys: [String]) async throws -> [String: JSONValue] {
        let request = LGWebOSCommand.getSystemSettings(category: category, keys: keys)
            .makeRequest(using: &requestFactory)
        guard let response = try await transport.send(JSONEncoder().encode(request)) else {
            throw TVProtocolError.malformedMessage
        }
        let value = try JSONDecoder().decode(JSONValue.self, from: response)
        guard case let .object(root) = value,
              case let .object(payload)? = root["payload"],
              case let .object(settings)? = payload["settings"] else {
            throw TVProtocolError.malformedMessage
        }
        return settings
    }

    func readVolume() async throws -> Int {
        let request = LGWebOSCommand.getVolume.makeRequest(using: &requestFactory)
        guard let response = try await transport.send(JSONEncoder().encode(request)) else {
            throw TVProtocolError.malformedMessage
        }
        let value = try JSONDecoder().decode(JSONValue.self, from: response)
        guard case let .object(root) = value else {
            throw TVProtocolError.malformedMessage
        }
        let payload: [String: JSONValue]
        if case let .object(responsePayload)? = root["payload"] {
            payload = responsePayload
        } else {
            // A few webOS bridges return the response fields at the root
            // instead of wrapping them in `payload`.
            payload = root
        }
        // LG webOS 2024/2025 firmware returns the scalar at
        // `payload.volumeStatus.volume`, while older versions return
        // `payload.volume`. Parse the complete bounded payload so both
        // representations (and bridge wrappers) are handled.
        guard let volume = LGVolumeValueParser.parse(.object(payload)) else {
            throw TVProtocolError.malformedMessage
        }
        return volume
    }

    func listApplications() async throws -> [LGNamedResource] {
        let request = LGWebOSCommand.listApplications.makeRequest(using: &requestFactory)
        let payload = try await responsePayload(for: request)
        guard case let .array(apps)? = payload["apps"] else {
            throw TVProtocolError.malformedMessage
        }
        return apps.compactMap { item in
            guard case let .object(app) = item,
                  case let .string(id)? = app["id"],
                  case let .string(title)? = app["title"] else { return nil }
            return LGNamedResource(id: id, title: title)
        }.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func listInputs() async throws -> [LGNamedResource] {
        let request = LGWebOSCommand.listInputs.makeRequest(using: &requestFactory)
        let payload = try await responsePayload(for: request)
        let candidate = payload["devices"] ?? payload["inputs"]
        guard case let .array(inputs)? = candidate else {
            throw TVProtocolError.malformedMessage
        }
        return inputs.compactMap { item in
            guard case let .object(input) = item,
                  case let .string(id)? = input["id"] else { return nil }
            let title: String
            if case let .string(label)? = input["label"], !label.isEmpty {
                title = label
            } else {
                title = id
            }
            return LGNamedResource(id: id, title: title)
        }
    }

    private func responsePayload(for request: LGWebOSRequest) async throws -> [String: JSONValue] {
        guard let response = try await transport.send(JSONEncoder().encode(request)) else {
            throw TVProtocolError.malformedMessage
        }
        let value = try JSONDecoder().decode(JSONValue.self, from: response)
        guard case let .object(root) = value,
              case let .object(payload)? = root["payload"] else {
            throw TVProtocolError.malformedMessage
        }
        return payload
    }

    private func registeredClientKey(initialResponse: Data) async throws -> String? {
        if let key = try LGWebOSRegistration.clientKey(from: initialResponse) {
            return key
        }

        // Registration may arrive after a prompt/response event. Keep the
        // bounded loop small so a dead TV cannot hold a preset forever.
        for _ in 0..<8 {
            guard let next = try await receivePairingResponse() else { continue }
            if let key = try LGWebOSRegistration.clientKey(from: next) {
                return key
            }
        }
        return nil
    }

    private func receivePairingResponse() async throws -> Data? {
        try await withThrowingTaskGroup(of: Data?.self) { group in
            group.addTask { [transport] in
                try await transport.receive()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(8))
                throw TVProtocolError.pairingTimedOut
            }
            guard let result = try await group.next() else {
                throw TVProtocolError.pairingTimedOut
            }
            group.cancelAll()
            return result
        }
    }

    private func executePictureSetting(name: String, value: Int) async throws {
        let createRequest = LGWebOSCommand.pictureSettingAlert(name: name, value: value)
            .makeRequest(using: &requestFactory)
        guard let response = try await transport.send(JSONEncoder().encode(createRequest)),
              let alertID = try Self.alertIdentifier(from: response) else {
            throw TVProtocolError.malformedMessage
        }
        let closeRequest = LGWebOSCommand.closeAlert(identifier: alertID)
            .makeRequest(using: &requestFactory)
        _ = try await transport.send(JSONEncoder().encode(closeRequest))
    }

    private func executeSystemSetting(category: String, name: String, value: JSONValue) async throws {
        let createRequest = LGWebOSCommand.systemSettingAlert(
            category: category,
            name: name,
            value: value
        ).makeRequest(using: &requestFactory)
        guard let response = try await transport.send(JSONEncoder().encode(createRequest)),
              let alertID = try Self.alertIdentifier(from: response) else {
            throw TVProtocolError.malformedMessage
        }
        let closeRequest = LGWebOSCommand.closeAlert(identifier: alertID)
            .makeRequest(using: &requestFactory)
        _ = try await transport.send(JSONEncoder().encode(closeRequest))
    }

    private func executeOLEDProtection(name: String, enabled: Bool) async throws {
        let uri: String
        switch name.uppercased() {
        case "TPC":
            uri = "luna://com.webos.service.oledepl/setTemporalPeakControl"
        case "GSR":
            uri = "luna://com.webos.service.oledepl/setGlobalStressReduction"
        default:
            throw TVProtocolError.unsupportedCommand(.setLGOLEDProtection(name: name, enabled: enabled))
        }
        let request = LGWebOSCommand.lunaActionAlert(
            uri: uri,
            payload: .object(["enable": .bool(enabled)])
        ).makeRequest(using: &requestFactory)
        guard let response = try await transport.send(JSONEncoder().encode(request)),
              let alertID = try Self.alertIdentifier(from: response) else {
            throw TVProtocolError.malformedMessage
        }
        let closeRequest = LGWebOSCommand.closeAlert(identifier: alertID)
            .makeRequest(using: &requestFactory)
        _ = try await transport.send(JSONEncoder().encode(closeRequest))
    }

    private func executeHDMIIcon(port: Int, icon: String, label: String) async throws {
        guard (1...4).contains(port), !icon.isEmpty, !label.isEmpty else {
            throw TVProtocolError.remoteFailure("HDMI icon requires a port from 1 through 4, an icon, and a label.")
        }
        let request = LGWebOSCommand.lunaActionAlert(
            uri: "luna://com.webos.service.eim/setDeviceInfo",
            payload: .object([
                "id": .string("HDMI_\(port)"),
                "label": .string(label),
                "icon": .string("\(icon).png")
            ])
        ).makeRequest(using: &requestFactory)
        guard let response = try await transport.send(JSONEncoder().encode(request)),
              let alertID = try Self.alertIdentifier(from: response) else {
            throw TVProtocolError.malformedMessage
        }
        let closeRequest = LGWebOSCommand.closeAlert(identifier: alertID)
            .makeRequest(using: &requestFactory)
        _ = try await transport.send(JSONEncoder().encode(closeRequest))
    }

    private static func alertIdentifier(from data: Data) throws -> String? {
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        guard case let .object(root) = value,
              case let .object(payload)? = root["payload"],
              case let .string(identifier)? = payload["alertId"] else {
            return nil
        }
        return identifier
    }

    private func executeRemoteKey(_ rawKey: String) async throws {
        let key = try LGWebOSButtonName.normalize(rawKey)
        let pointer: MacLGPointerWebSocketTransport
        if let pointerTransport {
            pointer = pointerTransport
        } else {
            let request = LGWebOSCommand.remote(
                uri: "ssap://com.webos.service.networkinput/getPointerInputSocket",
                payload: .object([:])
            ).makeRequest(using: &requestFactory)
            let data = try JSONEncoder().encode(request)
            guard let response = try await transport.send(data),
                  let socketURL = try Self.pointerSocketURL(from: response) else {
                throw TVProtocolError.malformedMessage
            }
            let nextPointer = MacLGPointerWebSocketTransport()
            try await nextPointer.connect(to: socketURL)
            pointerTransport = nextPointer
            pointer = nextPointer
        }
        try await pointer.sendButton(key)
    }

    private static func pointerSocketURL(from data: Data) throws -> URL? {
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        guard case let .object(root) = value,
              case let .object(payload)? = root["payload"],
              case let .string(socketPath)? = payload["socketPath"] else {
            return nil
        }
        return URL(string: socketPath)
    }
}

private enum LGWebOSButtonName {
    private static let supported: Set<String> = [
        "HOME", "BACK", "ENTER", "EXIT", "UP", "DOWN", "LEFT", "RIGHT",
        "RED", "GREEN", "YELLOW", "BLUE", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
        "POWER", "VOLUMEUP", "VOLUMEDOWN", "MUTE", "MENU", "CC", "DASH", "CHANNELUP",
        "CHANNELDOWN", "LIST", "AD", "SAP", "PROGRAM", "PLAY", "PAUSE", "STOP", "REWIND",
        "FASTFORWARD", "GUIDE", "AMAZON", "NETFLIX", "MAGNIFIER_ZOOM", "LIVE_ZOOM", "3D_MODE",
        "ASPECT_RATIO", "RECENT", "RECORD", "SCREEN_REMOTE", "MYAPPS"
    ]

    static func normalize(_ raw: String) throws -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.first == "_" { value.removeFirst() }
        guard supported.contains(value) else {
            throw TVProtocolError.unsupportedCommand(.remoteKey(raw))
        }
        return value
    }
}

/// Samsung client boundary: the first server event supplies or refreshes the
/// token. The token is never included in the native JSON snapshot.
actor SamsungTizenDeviceClient: TVDeviceController {
    private let device: TVDeviceDescriptor
    private let transport: any TVTransport
    private let credentials: any TVCredentialStore

    init(
        device: TVDeviceDescriptor,
        transport: any TVTransport = MacTVWebSocketTransport(),
        credentials: any TVCredentialStore = MigratingCredentialStore()
    ) {
        self.device = device
        self.transport = transport
        self.credentials = credentials
    }

    func deviceDescriptor() async -> TVDeviceDescriptor {
        device
    }

    func readPowerState() async throws -> TVPowerState {
        guard let url = SamsungPowerStateEndpoint(host: device.host).url else {
            throw TVProtocolError.invalidHost
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw TVProtocolError.powerStateUnavailable
        }

        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let state = SamsungPowerStateParser.parse(value) else {
            throw TVProtocolError.powerStateUnavailable
        }
        return state
    }

    func connect() async throws {
        try await transport.connect(to: device)
        guard let data = try await transport.receive(),
              let event = try SamsungMessageParser.connectionEvent(from: data) else {
            throw TVProtocolError.malformedMessage
        }
        if event.unauthorized {
            throw TVProtocolError.pairingRequired
        }
        if let token = event.token, let reference = device.credentialReference {
            try credentials.save(token, reference: reference)
        }
    }

    func execute(_ command: TVCommand) async throws {
        let remoteKey: String
        switch command {
        case .powerOn:
            throw TVProtocolError.unsupportedCommand(command)
        case .powerOff:
            remoteKey = "KEY_POWER"
        case .volumeUp:
            remoteKey = "KEY_VOLUP"
        case .volumeDown:
            remoteKey = "KEY_VOLDOWN"
        case .mute(_):
            remoteKey = "KEY_MUTE"
        case let .remoteKey(key):
            remoteKey = key
        case .screenOff, .screenOn, .setVolume, .setPictureSetting,
             .setLGSystemSetting, .reboot, .mediaPlay, .mediaPause, .mediaStop,
             .channelUp, .channelDown, .setInput, .openURL, .closeApplication,
             .setLGOLEDProtection, .setLGHDMIIcon, .launchApplication:
            throw TVProtocolError.unsupportedCommand(command)
        }

        let data = try JSONEncoder().encode(SamsungRemoteCommand(key: remoteKey).request())
        _ = try await transport.send(data)
    }

    func disconnect() async {
        await transport.disconnect()
    }
}
