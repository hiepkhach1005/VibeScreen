import XCTest
@testable import ColorControlCore

final class LegacyDeviceImporterTests: XCTestCase {
    func testImportsPowerPolicyAndKeepsTokenOutOfSnapshot() throws {
        let json = #"{
          "Devices": [
            {
              "Name": "Living room",
              "IpAddress": "192.168.1.10",
              "MacAddress": "AA:BB:CC:DD:EE:FF",
              "Token": "secret-token",
              "Options": {
                "UseSecureConnection": true,
                "PowerOffOnStandby": true,
                "PowerOnAfterResume": true,
                "ScreenSaverMinimalDuration": 20
              }
            }
          ]
        }"#.data(using: .utf8)!

        let report = try LegacyDeviceImporter.importSamsung(data: json)
        let device = try XCTUnwrap(report.devices.first)

        XCTAssertEqual(device.kind, .samsungTizen)
        XCTAssertEqual(device.host, "192.168.1.10")
        XCTAssertEqual(device.usesSecureConnection, true)
        XCTAssertNotNil(device.credentialReference)
        XCTAssertTrue(device.powerPolicy.powerOffOnStandby)
        XCTAssertTrue(device.powerPolicy.powerOnAfterResume)
        XCTAssertEqual(device.powerPolicy.screenSaverMinimumDuration, 20)
        XCTAssertTrue(report.issues.contains { $0.message.contains("Keychain") })
    }

    func testMapsWindowsMonitorPowerOptionsToMacScreenPolicy() throws {
        let json = #"[{"Name":"Desk","IpAddress":"192.168.1.11","Options":{"PowerOffByWindows":true,"PowerOnByWindows":true}}]"#.data(using: .utf8)!

        let report = try LegacyDeviceImporter.importLG(data: json)
        let device = try XCTUnwrap(report.devices.first)

        XCTAssertTrue(device.powerPolicy.powerOffOnScreenSaver)
        XCTAssertTrue(device.powerPolicy.powerOnAfterScreenSaver)
        XCTAssertTrue(report.issues.contains { $0.message.contains("screen sleep/wake") })
    }
}
