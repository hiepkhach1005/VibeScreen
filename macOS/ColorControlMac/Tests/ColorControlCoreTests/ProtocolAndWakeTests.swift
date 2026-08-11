import XCTest
@testable import ColorControlCore

final class ProtocolAndWakeTests: XCTestCase {
    func testLGRequestKeepsLegacyURIAndPayloadShape() throws {
        var factory = LGWebOSRequestFactory()
        let request = LGWebOSCommand.mute(true).makeRequest(using: &factory)
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(object["uri"] as? String, "ssap://audio/setMute")
        let payload = try XCTUnwrap(object["payload"] as? [String: Any])
        XCTAssertEqual(payload["mute"] as? Bool, true)
    }

    func testLGAbsoluteVolumeUsesTheLegacyAudioEndpoint() throws {
        var factory = LGWebOSRequestFactory()
        let request = LGWebOSCommand.setVolume(120).makeRequest(using: &factory)
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let payload = try XCTUnwrap(object["payload"] as? [String: Any])

        XCTAssertEqual(object["uri"] as? String, "ssap://audio/setVolume")
        XCTAssertEqual((payload["volume"] as? NSNumber)?.intValue, 100)
    }

    func testLGRegistrationUsesStableRegisterIDAndReadsClientKey() throws {
        let message = LGWebOSRegistration.makeMessage(clientKey: "existing-key")
        XCTAssertEqual(message.type, "register")
        XCTAssertEqual(message.id, "register_0")

        let data = #"{"type":"registered","payload":{"client-key":"new-key"}}"#.data(using: .utf8)!
        XCTAssertEqual(try LGWebOSRegistration.clientKey(from: data), "new-key")
    }

    func testSamsungConnectionEventReadsTokenFromTopLevelOrClientAttributes() throws {
        let topLevel = #"{"event":"ms.channel.connect","data":{"token":"1234"}}"#.data(using: .utf8)!
        XCTAssertEqual(
            try SamsungMessageParser.connectionEvent(from: topLevel),
            SamsungConnectionEvent(token: "1234", unauthorized: false)
        )

        let unauthorized = #"{"event":"ms.channel.unauthorized","data":{}}"#.data(using: .utf8)!
        XCTAssertEqual(
            try SamsungMessageParser.connectionEvent(from: unauthorized),
            SamsungConnectionEvent(token: nil, unauthorized: true)
        )
    }

    func testSamsungSecureEndpointMatchesLegacyPortsAndQuery() throws {
        let endpoint = SamsungWebSocketEndpoint(host: "192.168.1.20", secure: true, token: "1234")
        let url = try XCTUnwrap(endpoint.url)

        XCTAssertEqual(url.scheme, "wss")
        XCTAssertEqual(url.port, 8002)
        XCTAssertTrue(url.absoluteString.contains("/api/v2/channels/samsung.remote.control"))
        XCTAssertTrue(url.absoluteString.contains("token=1234"))
    }

    func testWakeOnLANPacketIs102BytesAndStartsWithSixFFBytes() throws {
        let packet = try WakeOnLANPacket.make(macAddress: "AA:BB:CC:DD:EE:FF")

        XCTAssertEqual(packet.count, 102)
        XCTAssertEqual(Array(packet.prefix(6)), Array(repeating: 0xFF, count: 6))
        XCTAssertEqual(Array(packet.suffix(6)), [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])
    }

    func testWakeOnLANRejectsInvalidMAC() {
        XCTAssertThrowsError(try WakeOnLANPacket.make(macAddress: "invalid")) { error in
            XCTAssertEqual(error as? WakeOnLANError, .invalidMACAddress)
        }
    }
}
