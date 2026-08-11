import ColorControlCore
import Foundation

/// LG client boundary: registration is sent as the first message and the
/// returned client key is immediately moved to Keychain.
actor LGWebOSDeviceClient: TVDeviceController {
    private let device: TVDeviceDescriptor
    private let transport: any TVTransport
    private let credentials: KeychainCredentialStore
    private var requestFactory = LGWebOSRequestFactory()
    private var pointerTransport: MacLGPointerWebSocketTransport? = nil

    init(
        device: TVDeviceDescriptor,
        transport: any TVTransport = MacTVWebSocketTransport(),
        credentials: KeychainCredentialStore = KeychainCredentialStore()
    ) {
        self.device = device
        self.transport = transport
        self.credentials = credentials
    }

    func deviceDescriptor() async -> TVDeviceDescriptor {
        device
    }

    func connect() async throws {
        try await transport.connect(to: device)

        let existingKey: String?
        if let reference = device.credentialReference {
            existingKey = try credentials.read(reference: reference)
        } else {
            existingKey = nil
        }

        let registration = LGWebOSRegistration.makeMessage(clientKey: existingKey)
        let data = try JSONEncoder().encode(registration)
        guard let response = try await transport.send(data) else {
            throw TVProtocolError.malformedMessage
        }

        if let newKey = try await registeredClientKey(initialResponse: response),
           let reference = device.credentialReference {
            try credentials.save(newKey, reference: reference)
        } else if existingKey == nil {
            throw TVProtocolError.pairingRequired
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

    private func registeredClientKey(initialResponse: Data) async throws -> String? {
        if let key = try LGWebOSRegistration.clientKey(from: initialResponse) {
            return key
        }

        // Registration may arrive after a prompt/response event. Keep the
        // bounded loop small so a dead TV cannot hold a preset forever.
        for _ in 0..<8 {
            guard let next = try await transport.receive() else { continue }
            if let key = try LGWebOSRegistration.clientKey(from: next) {
                return key
            }
        }
        return nil
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
    private let credentials: KeychainCredentialStore

    init(
        device: TVDeviceDescriptor,
        transport: any TVTransport = MacTVWebSocketTransport(),
        credentials: KeychainCredentialStore = KeychainCredentialStore()
    ) {
        self.device = device
        self.transport = transport
        self.credentials = credentials
    }

    func deviceDescriptor() async -> TVDeviceDescriptor {
        device
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
        case .screenOff, .screenOn, .setVolume, .launchApplication:
            throw TVProtocolError.unsupportedCommand(command)
        }

        let data = try JSONEncoder().encode(SamsungRemoteCommand(key: remoteKey).request())
        _ = try await transport.send(data)
    }

    func disconnect() async {
        await transport.disconnect()
    }
}
