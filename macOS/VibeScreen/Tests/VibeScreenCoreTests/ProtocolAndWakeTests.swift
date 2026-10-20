import XCTest
@testable import VibeScreenCore

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

    func testLGPowerStateRequestAndParserNormalizeActiveAndStandby() throws {
        var factory = LGWebOSRequestFactory()
        let request = LGWebOSCommand.getPowerState.makeRequest(using: &factory)

        XCTAssertEqual(request.uri, "ssap://com.webos.service.tvpower/power/getPowerState")
        XCTAssertEqual(request.type, "subscribe")
        XCTAssertEqual(
            LGPowerStateParser.parse(.object([
                "payload": .object(["state": .string("Active")])
            ])),
            .on
        )
        XCTAssertEqual(
            LGPowerStateParser.parse(.object([
                "payload": .object(["state": .string("Power_Off")])
            ])),
            .off
        )
    }

    func testSamsungPowerStateParserAndEndpoint() throws {
        let endpoint = SamsungPowerStateEndpoint(host: "192.0.2.10")
        let url = try XCTUnwrap(endpoint.url)

        XCTAssertEqual(url.scheme, "http")
        XCTAssertEqual(url.port, 8001)
        XCTAssertEqual(url.path, "/api/v2/")
        XCTAssertEqual(
            SamsungPowerStateParser.parse(.object([
                "device": .object(["PowerState": .string("standby")])
            ])),
            .off
        )
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

    func testLGVolumeValueParserAcceptsFirmwareRepresentations() {
        XCTAssertEqual(LGVolumeValueParser.parse(.number(15)), 15)
        XCTAssertEqual(LGVolumeValueParser.parse(.string("15.0")), 15)
        XCTAssertEqual(
            LGVolumeValueParser.parse(.object(["value": .number(15)])),
            15
        )
        XCTAssertEqual(
            LGVolumeValueParser.parse(.object(["volume": .null, "level": .number(15)])),
            15
        )
        XCTAssertEqual(
            LGVolumeValueParser.parse(.object([
                "returnValue": .bool(true),
                "volumeStatus": .object([
                    "volume": .number(15),
                    "muteStatus": .bool(false)
                ])
            ])),
            15
        )
        XCTAssertEqual(LGVolumeValueParser.parse(.number(140)), 100)
    }

    func testLGRegistrationUsesStableRegisterIDAndReadsClientKey() throws {
        let message = LGWebOSRegistration.makeMessage(clientKey: "existing-key")
        XCTAssertEqual(message.type, "register")
        XCTAssertEqual(message.id, "register_0")

        let encoded = try JSONEncoder().encode(message)
        let registration = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let registrationPayload = try XCTUnwrap(registration["payload"] as? [String: Any])
        let manifest = try XCTUnwrap(registrationPayload["manifest"] as? [String: Any])
        let signed = try XCTUnwrap(manifest["signed"] as? [String: Any])
        let signedPermissions = try XCTUnwrap(signed["permissions"] as? [String])
        XCTAssertTrue(signedPermissions.contains("READ_COUNTRY_INFO"))
        XCTAssertTrue(signedPermissions.contains("WRITE_NOTIFICATION_TOAST"))

        let data = #"{"type":"registered","payload":{"client-key":"new-key"}}"#.data(using: .utf8)!
        XCTAssertEqual(try LGWebOSRegistration.clientKey(from: data), "new-key")
    }

    func testLGPictureSettingUsesBoundedLegacyAlertAction() throws {
        var factory = LGWebOSRequestFactory()
        let request = LGWebOSCommand.pictureSettingAlert(name: "brightness", value: 140)
            .makeRequest(using: &factory)
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let payload = try XCTUnwrap(object["payload"] as? [String: Any])
        let closeAction = try XCTUnwrap(payload["onclose"] as? [String: Any])
        let parameters = try XCTUnwrap(closeAction["params"] as? [String: Any])
        let settings = try XCTUnwrap(parameters["settings"] as? [String: Any])

        XCTAssertEqual(object["uri"] as? String, "ssap://system.notifications/createAlert")
        XCTAssertEqual(closeAction["uri"] as? String, "luna://com.webos.settingsservice/setSystemSettings")
        XCTAssertEqual(settings["brightness"] as? String, "100")
    }

    func testLGSystemSettingPreservesHDMIChildPayloadShape() throws {
        let payload = LGWebOSCommand.systemSettingsPayload(
            category: "other",
            name: "gameMode_hdmi2",
            value: .string("on")
        )
        let data = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let settings = try XCTUnwrap(object["settings"] as? [String: Any])
        let gameMode = try XCTUnwrap(settings["gameMode"] as? [String: Any])

        XCTAssertEqual(object["category"] as? String, "other")
        XCTAssertEqual(gameMode["hdmi2"] as? String, "on")
    }

    func testLGBlackLevelExpandsToEveryLegacyColorSystem() throws {
        let payload = LGWebOSCommand.systemSettingsPayload(
            category: "picture",
            name: "blackLevel",
            value: .string("limited")
        )
        let data = try JSONEncoder().encode(payload)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let settings = try XCTUnwrap(object["settings"] as? [String: Any])
        let blackLevel = try XCTUnwrap(settings["blackLevel"] as? [String: Any])

        XCTAssertEqual(blackLevel.count, 8)
        XCTAssertTrue(blackLevel.values.allSatisfy { ($0 as? String) == "limited" })
    }

    func testLGControlCatalogIncludesGameBarAndPerPortGameOptimizer() {
        XCTAssertEqual(
            LGControlCatalog.controls(in: .gameBar).map(\.id),
            ["backlight", "contrast", "brightness", "color"]
        )
        XCTAssertTrue(LGControlCatalog.controls.contains { $0.id == "gameMode_hdmi4" })
        XCTAssertTrue(LGControlCatalog.controls.contains { $0.id == "enableALLM" })
    }

    func testLGOLEDProtectionUsesBoundedAlertRoute() throws {
        var factory = LGWebOSRequestFactory()
        let request = LGWebOSCommand.lunaActionAlert(
            uri: "luna://com.webos.service.oledepl/setTemporalPeakControl",
            payload: .object(["enable": .bool(false)])
        ).makeRequest(using: &factory)
        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let payload = try XCTUnwrap(object["payload"] as? [String: Any])
        let closeAction = try XCTUnwrap(payload["onclose"] as? [String: Any])

        XCTAssertEqual(object["uri"] as? String, "ssap://system.notifications/createAlert")
        XCTAssertEqual(closeAction["uri"] as? String, "luna://com.webos.service.oledepl/setTemporalPeakControl")
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
