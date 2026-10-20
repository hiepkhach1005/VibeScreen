import Foundation

public protocol WakeOnLANSender: Sendable {
    func send(
        macAddress: String,
        broadcastAddress: String,
        port: UInt16
    ) async throws
}

public enum WakeOnLANError: Error, LocalizedError, Sendable, Equatable {
    case invalidMACAddress
    case invalidSecureOnPassword
    case invalidPort

    public var errorDescription: String? {
        switch self {
        case .invalidMACAddress:
            return "A Wake-on-LAN MAC address must contain exactly six hexadecimal bytes."
        case .invalidSecureOnPassword:
            return "A SecureOn password must contain zero or six bytes."
        case .invalidPort:
            return "The Wake-on-LAN UDP port is invalid."
        }
    }
}

public enum WakeOnLANPacket {
    public static func make(macAddress: String, secureOnPassword: String? = nil) throws -> Data {
        let mac = try parseHexBytes(macAddress, expectedCount: 6)
        var bytes = Array(repeating: UInt8(0xFF), count: 6)

        for _ in 0..<16 {
            bytes.append(contentsOf: mac)
        }

        if let secureOnPassword, !secureOnPassword.isEmpty {
            let password = try parseHexBytes(secureOnPassword, expectedCount: 6)
            bytes.append(contentsOf: password)
        }

        return Data(bytes)
    }

    private static func parseHexBytes(_ value: String, expectedCount: Int) throws -> [UInt8] {
        let normalized = value
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.count == expectedCount * 2 else {
            if expectedCount == 6 {
                throw WakeOnLANError.invalidMACAddress
            }
            throw WakeOnLANError.invalidSecureOnPassword
        }

        var result: [UInt8] = []
        result.reserveCapacity(expectedCount)

        var index = normalized.startIndex
        for _ in 0..<expectedCount {
            let next = normalized.index(index, offsetBy: 2)
            guard let byte = UInt8(normalized[index..<next], radix: 16) else {
                if expectedCount == 6 {
                    throw WakeOnLANError.invalidMACAddress
                }
                throw WakeOnLANError.invalidSecureOnPassword
            }
            result.append(byte)
            index = next
        }

        return result
    }
}
