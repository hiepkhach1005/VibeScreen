import ColorControlCore
import CryptoKit
import Foundation
import os
import Security

/// A serial URLSession WebSocket transport for local TV control. TLS uses the
/// system trust policy; no global certificate-validation bypass is allowed.
actor MacTVWebSocketTransport: TVTransport {
    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var trustDelegate: ScopedTVTrustDelegate?
    private let credentials: any TVCredentialStore

    init(credentials: any TVCredentialStore = MigratingCredentialStore()) {
        self.credentials = credentials
    }

    func connect(to device: TVDeviceDescriptor) async throws {
        guard let url = try makeURL(for: device) else {
            throw TVProtocolError.invalidHost
        }

        task?.cancel(with: .goingAway, reason: nil)
        session?.invalidateAndCancel()

        let nextDelegate = ScopedTVTrustDelegate(
            expectedHost: device.host,
            trustedFingerprint: device.trustedCertificateSHA256
        )
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60
        let nextSession = URLSession(
            configuration: configuration,
            delegate: nextDelegate,
            delegateQueue: nil
        )
        let nextTask = nextSession.webSocketTask(with: url)
        trustDelegate = nextDelegate
        session = nextSession
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

        do {
            try await task.send(.string(text))
            return try await receive()
        } catch {
            if let fingerprint = trustDelegate?.rejectedFingerprint() {
                throw TVProtocolError.untrustedCertificate(fingerprint: fingerprint)
            }
            throw error
        }
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
        session?.invalidateAndCancel()
        task = nil
        session = nil
        trustDelegate = nil
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

/// Accepts a locally issued TV certificate only when its leaf SHA-256
/// fingerprint was explicitly pinned for this exact configured host.
private final class ScopedTVTrustDelegate: NSObject, URLSessionDelegate, Sendable {
    private let expectedHost: String
    private let trustedFingerprint: String?
    private let rejectedFingerprintState = OSAllocatedUnfairLock<String?>(initialState: nil)

    init(expectedHost: String, trustedFingerprint: String?) {
        self.expectedHost = expectedHost
        self.trustedFingerprint = trustedFingerprint.map(Self.normalized)
    }

    func rejectedFingerprint() -> String? {
        rejectedFingerprintState.withLock { $0 }
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host.caseInsensitiveCompare(expectedHost) == .orderedSame,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if SecTrustEvaluateWithError(trust, nil) {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let certificates = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leafCertificate = certificates.first else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let certificateData = SecCertificateCopyData(leafCertificate) as Data
        let fingerprint = SHA256.hash(data: certificateData)
            .map { String(format: "%02X", $0) }
            .joined()

        if let trustedFingerprint, trustedFingerprint == fingerprint {
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }

        rejectedFingerprintState.withLock {
            $0 = Self.displayed(fingerprint)
        }
        completionHandler(.cancelAuthenticationChallenge, nil)
    }

    private static func normalized(_ fingerprint: String) -> String {
        fingerprint
            .uppercased()
            .filter { $0.isHexDigit }
    }

    private static func displayed(_ fingerprint: String) -> String {
        stride(from: 0, to: fingerprint.count, by: 2).map { offset in
            let start = fingerprint.index(fingerprint.startIndex, offsetBy: offset)
            let end = fingerprint.index(start, offsetBy: min(2, fingerprint.count - offset))
            return String(fingerprint[start..<end])
        }.joined(separator: ":")
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
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
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
