import XCTest
@testable import VibeScreenCore

final class LegacyPresetImporterTests: XCTestCase {
    func testImportsLGPresetAndReportsRemovedGsyncCondition() throws {
        let json = #"[
          {
            "name": "Cinema",
            "appId": "com.palm.app.settings",
            "DeviceMacAddress": "AA:BB:CC:DD:EE:FF",
            "steps": ["RIGHT:500", "ENTER"],
            "shortcut": "",
            "id": 42,
            "Triggers": [
              {
                "Trigger": 6,
                "IncludedProcesses": ["game"],
                "Conditions": 34
              }
            ]
          }
        ]"#.data(using: .utf8)!

        let report = try LegacyPresetImporter.importLG(data: json)
        let preset = try XCTUnwrap(report.presets.first)

        XCTAssertEqual(preset.name, "Cinema")
        XCTAssertEqual(preset.applicationIdentifier, "com.palm.app.settings")
        XCTAssertEqual(preset.targetDeviceAddress, "AA:BB:CC:DD:EE:FF")
        XCTAssertEqual(preset.steps.map(\.delayMilliseconds), [500, 0])
        XCTAssertEqual(preset.triggers.first?.kind, .processSwitch)
        XCTAssertTrue(report.issues.contains { $0.message.contains("G-SYNC") })
    }

    func testStableIDsAreRepeatableAcrossDryRuns() throws {
        let json = #"[{"name":"One","steps":["KEY_POWER"],"id":7}]"#.data(using: .utf8)!
        let first = try LegacyPresetImporter.importSamsung(data: json)
        let second = try LegacyPresetImporter.importSamsung(data: json)

        XCTAssertEqual(first.presets.map(\.id), second.presets.map(\.id))
    }
}
