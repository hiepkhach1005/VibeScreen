import XCTest
@testable import ColorControlCore

final class LegacyAdditionalImporterTests: XCTestCase {
    func testGameImporterPreservesLaunchArgumentsAndFlagsWindowsPath() throws {
        let json = #"[
          {
            "id": 4,
            "name": "Racing",
            "Path": "C:\\Games\\racing.exe",
            "Parameters": "--profile \"big screen\"",
            "PreLaunchSteps": ["Volume(20):100"],
            "AutoSettings": {"AllowAutoApply": true, "ProcessAutoAction": 1}
          }
        ]"#.data(using: .utf8)!

        let report = try LegacyGameImporter.importData(json)
        let preset = try XCTUnwrap(report.presets.first)

        XCTAssertEqual(preset.launch?.arguments, ["--profile", "big screen"])
        XCTAssertEqual(preset.preLaunchSteps.first?.delayMilliseconds, 100)
        XCTAssertEqual(preset.processAutoAction, .none)
        XCTAssertTrue(report.issues.contains { $0.message.contains("Windows executable") })
    }

    func testRemoteImporterRetainsUnknownButtonPayload() throws {
        let json = #"[
          {
            "Name": "Living room",
            "ImageFileName": "remote.png",
            "Buttons": [{"Name": "Power", "Button": "KEY_POWER", "Top": 10, "Left": 20}]
          }
        ]"#.data(using: .utf8)!

        let report = try LegacyRemoteImporter.importSamsung(data: json)
        let remote = try XCTUnwrap(report.remotes.first)
        let button = try XCTUnwrap(remote.buttons.first)

        XCTAssertEqual(remote.kind, .samsungTizen)
        XCTAssertEqual(button.command, "KEY_POWER")
        XCTAssertEqual(button.top, 10)
        XCTAssertNotNil(button.legacyPayload)
    }

    func testSettingsImporterExcludesWindowsWebAndGPUFields() throws {
        let json = #"{
          "AutoStart": true,
          "StartMinimized": true,
          "MinimizeToTray": false,
          "ProcessMonitorPollingInterval": 2500,
          "UiPort": 8080,
          "NvPresetId_ApplyOnStartup": 3,
          "ElevationMethod": 2
        }"#.data(using: .utf8)!

        let report = try LegacySettingsImporter.importData(json)

        XCTAssertTrue(report.settings.launchAtLogin)
        XCTAssertTrue(report.settings.startHidden)
        XCTAssertFalse(report.settings.minimizeToMenuBar)
        XCTAssertEqual(report.settings.processMonitorIntervalMilliseconds, 2500)
        XCTAssertEqual(report.issues.count, 3)
    }

    func testMigrationCoordinatorBuildsOnePreviewWithoutWritingLegacyData() throws {
        let settings = #"{"AutoStart":true}"#.data(using: .utf8)!
        let devices = #"{"Devices":[{"Name":"TV","IpAddress":"192.168.1.55"}]}"#.data(using: .utf8)!

        let preview = LegacyMigrationCoordinator.preview(
            LegacyMigrationInput(settings: settings, lgDevices: devices)
        )

        XCTAssertTrue(preview.isSafeToCommit)
        XCTAssertTrue(preview.snapshot.settings.launchAtLogin)
        XCTAssertEqual(preview.snapshot.devices.count, 1)
        XCTAssertNotNil(preview.snapshot.devices[0].credentialReference)
    }
}
