import ColorControlCore
import Foundation
@preconcurrency import Network

actor MacWakeOnLANSender: WakeOnLANSender {
    func send(
        macAddress: String,
        broadcastAddress: String = "255.255.255.255",
        port: UInt16 = 9
    ) async throws {
        let packet = try WakeOnLANPacket.make(macAddress: macAddress)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw WakeOnLANError.invalidPort
        }

        let connection = NWConnection(
            host: NWEndpoint.Host(broadcastAddress),
            port: nwPort,
            using: .udp
        )

        try await withCheckedThrowingContinuation { continuation in
            connection.start(queue: .global(qos: .utility))
            connection.send(content: packet, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
                connection.cancel()
            })
        }
    }
}
