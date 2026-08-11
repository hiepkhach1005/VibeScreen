import ColorControlCore
import Foundation
import Security

/// A serial URLSession WebSocket transport for local TV control. TLS uses the
/// system trust policy; no global certificate-validation bypass is allowed.
actor MacTVWebSocketTransport: TVTransport {
    private var task: URLSessionWebSocketTask?
    private let credentials: KeychainCredentialStore

    init(credentials: KeychainCredentialStore = KeychainCredentialStore()) {
        self.credentials = credentials
    }

    func connect(to device: TVDeviceDescriptor) async throws {
        guard let url = try makeURL(for: device) else {
            throw TVProtocolError.invalidHost
        }

        task?.cancel(with: .goingAway, reason: nil)
        let nextTask = URLSession.shared.webSocketTask(with: url)
        task = nextTask
        nextTask.resume()
    }

    func send(_ data: Data) async throws -> Data? {
        guard let task else {
            throw TVProtocolError.transportUnavailable
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw TVProtocolError.malformedMessage
        }

        try await task.send(.string(text))
        return try await receive()
    }

    func receive() async throws -> Data? {
        guard let task else {
            throw TVProtocolError.transportUnavailable
        }

        let message = try await task.receive()

        switch message {
        case let .string(value):
            return Data(value.utf8)
        case let .data(value):
            return value
        @unknown default:
            throw TVProtocolError.malformedMessage
        }
    }

    func disconnect() async {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    private func makeURL(for device: TVDeviceDescriptor) throws -> URL? {
        switch device.kind {
        case .samsungTizen:
            let token: String?
            if let reference = device.credentialReference {
                token = try credentials.read(reference: reference)
            } else {
                token = nil
            }
            return SamsungWebSocketEndpoint(
                host: device.host,
                secure: device.usesSecureConnection,
                token: token
            ).url
        case .lgWebOS:
            var components = URLComponents()
            components.scheme = device.usesSecureConnection ? "wss" : "ws"
            components.host = device.host
            components.port = device.usesSecureConnection ? 3001 : 3000
            return components.url
        }
    }
}

/// LG's remote buttons use a second pointer-input WebSocket returned by
/// `ssap://com.webos.service.networkinput/getPointerInputSocket`.
actor MacLGPointerWebSocketTransport {
    private var task: URLSessionWebSocketTask?

    func connect(to url: URL) async throws {
        task?.cancel(with: .goingAway, reason: nil)
        let nextTask = URLSession.shared.webSocketTask(with: url)
        task = nextTask
        nextTask.resume()
    }

    func sendButton(_ name: String) async throws {
        guard let task else {
            throw TVProtocolError.transportUnavailable
        }

        let message = "type:button\nname:\(name)\n\n"
        try await task.send(.string(message))
    }

    func disconnect() async {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }
}

public enum KeychainCredentialError: Error, LocalizedError, Sendable, Equatable {
    case unexpectedStatus(Int32)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(status): return "Keychain operation failed with status \(status)."
        case .invalidData: return "The Keychain item did not contain valid UTF-8 data."
        }
    }
}

/// Stores TV pairing tokens/client keys outside the JSON snapshot. The
/// reference, not the secret, is persisted in `TVDeviceDescriptor`.
public struct KeychainCredentialStore: Sendable {
    private let service: String

    public init(service: String = "com.colorcontrol.mac") {
        self.service = service
    }

    public func save(_ secret: String, reference: String) throws {
        guard let data = secret.data(using: .utf8) else {
            throw KeychainCredentialError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: reference
            ]
            let updateStatus = SecItemUpdate(
                updateQuery as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw KeychainCredentialError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainCredentialError.unexpectedStatus(status)
        }
    }

    public func read(reference: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainCredentialError.unexpectedStatus(status)
        }
        guard let data = result as? Data else {
            throw KeychainCredentialError.invalidData
        }
        guard let value = String(data: data, encoding: .utf8) else {
            throw KeychainCredentialError.invalidData
        }
        return value
    }

    public func delete(reference: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainCredentialError.unexpectedStatus(status)
        }
    }
}
