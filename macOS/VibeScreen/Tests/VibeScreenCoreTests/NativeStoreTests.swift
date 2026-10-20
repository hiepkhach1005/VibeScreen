import XCTest
@testable import VibeScreenCore

final class NativeStoreTests: XCTestCase {
    func testNativeSettingsDecodeOldSnapshotWithCurrentDefaults() throws {
        let data = Data(
            #"{"launchAtLogin":false,"startHidden":false,"minimizeToMenuBar":true,"checkForUpdates":true,"logLevel":"info","processMonitorIntervalMilliseconds":1000}"#.utf8
        )

        let settings = try JSONDecoder().decode(NativeAppSettings.self, from: data)

        XCTAssertFalse(settings.showOverviewInSidebar)
        XCTAssertTrue(settings.showSystemMonitorInSidebar)
        XCTAssertTrue(settings.lgLiveSyncEnabled)
        XCTAssertEqual(settings.lgLiveSyncIntervalSeconds, 5)
        XCTAssertEqual(settings.systemMonitorIntervalMilliseconds, 1_000)
        XCTAssertEqual(settings.tvPowerToggleShortcut, .defaultTVPowerToggle)
    }

    func testNativeSettingsRoundTripOverviewVisibility() throws {
        let settings = NativeAppSettings(
            showOverviewInSidebar: true,
            showSystemMonitorInSidebar: false
        )
        let data = try JSONEncoder().encode(settings)

        let decoded = try JSONDecoder().decode(NativeAppSettings.self, from: data)

        XCTAssertTrue(decoded.showOverviewInSidebar)
        XCTAssertFalse(decoded.showSystemMonitorInSidebar)
    }

    func testNativeSettingsClampLiveSyncInterval() {
        XCTAssertEqual(NativeAppSettings(lgLiveSyncIntervalSeconds: 0).lgLiveSyncIntervalSeconds, 1)
        XCTAssertEqual(NativeAppSettings(lgLiveSyncIntervalSeconds: 9_000).lgLiveSyncIntervalSeconds, 3_600)
    }

    func testNativeSettingsRoundTripsAndClampsSystemMonitorInterval() throws {
        let settings = NativeAppSettings(systemMonitorIntervalMilliseconds: 250)
        XCTAssertEqual(settings.systemMonitorIntervalMilliseconds, 500)

        let data = try JSONEncoder().encode(
            NativeAppSettings(systemMonitorIntervalMilliseconds: 2_500)
        )
        let decoded = try JSONDecoder().decode(NativeAppSettings.self, from: data)

        XCTAssertEqual(decoded.systemMonitorIntervalMilliseconds, 2_500)
        XCTAssertEqual(
            NativeAppSettings(systemMonitorIntervalMilliseconds: 90_000)
                .systemMonitorIntervalMilliseconds,
            60_000
        )
    }

    func testNativeSettingsRoundTripsEditableTVPowerToggleShortcut() throws {
        let toggle = GlobalKeyboardShortcut(
            keyCode: 0,
            key: "A",
            usesCommand: true,
            usesOption: true,
            usesControl: false,
            usesShift: false
        )
        let settings = NativeAppSettings(
            tvPowerToggleShortcut: toggle
        )

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(NativeAppSettings.self, from: data)

        XCTAssertEqual(decoded.tvPowerToggleShortcut, toggle)
        XCTAssertEqual(toggle.displayText, "⌥⌘A")
    }

    func testNativeSettingsMigratesLegacyDefaultPairToToggleDefault() throws {
        let data = try JSONEncoder().encode([
            "tvPowerOnShortcut": GlobalKeyboardShortcut.legacyDefaultTVPowerOn,
            "tvPowerOffShortcut": GlobalKeyboardShortcut.legacyDefaultTVPowerOff
        ])

        let decoded = try JSONDecoder().decode(NativeAppSettings.self, from: data)

        XCTAssertEqual(decoded.tvPowerToggleShortcut, .defaultTVPowerToggle)
    }

    func testRoundTripsSnapshotAndCreatesBackupOnSecondWrite() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VibeScreenTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = NativeStore(directoryURL: directory)
        let first = NativeStoreSnapshot(
            presets: [Preset(name: "First")],
            devices: [TVDeviceDescriptor(
                name: "Pinned LG",
                kind: .lgWebOS,
                host: "192.0.2.10",
                usesSecureConnection: true,
                trustedCertificateSHA256: "AA:BB:CC"
            )]
        )
        let second = NativeStoreSnapshot(
            presets: [Preset(name: "Second")],
            devices: first.devices
        )

        try await store.save(first)
        try await store.save(second)

        let loaded = try await store.load()
        XCTAssertEqual(loaded, second)
        XCTAssertEqual(loaded?.devices.first?.trustedCertificateSHA256, "AA:BB:CC")
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent("VibeScreen.json.bak").path
        ))
    }

    func testStoreRestrictsSnapshotAndDirectoryPermissions() async throws {
        let directoryName = "VibeScreenPermissionTests-" + UUID().uuidString
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(directoryName, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = NativeStore(directoryURL: directory)
        try await store.save(NativeStoreSnapshot())
        try await store.save(NativeStoreSnapshot(presets: [Preset(name: "Updated")]))

        XCTAssertEqual(try permissions(of: directory), 0o700)
        XCTAssertEqual(try permissions(of: directory.appendingPathComponent("VibeScreen.json")), 0o600)
        XCTAssertEqual(try permissions(of: directory.appendingPathComponent("VibeScreen.json.bak")), 0o600)
    }

    func testRoundTripsIndependentPowerPoliciesForEachDevice() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VibeScreenPolicyTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstDevice = TVDeviceDescriptor(
            name: "Living room",
            kind: .lgWebOS,
            host: "192.0.2.20",
            powerPolicy: TVPowerPolicy(
                powerOnAfterStartup: true,
                powerOffOnStandby: true
            )
        )
        let secondDevice = TVDeviceDescriptor(
            name: "Desk",
            kind: .samsungTizen,
            host: "192.0.2.21",
            powerPolicy: TVPowerPolicy(
                powerOffAfterSessionLock: true,
                screenSaverMinimumDuration: 45
            )
        )
        let store = NativeStore(directoryURL: directory)

        try await store.save(NativeStoreSnapshot(devices: [firstDevice, secondDevice]))
        let loaded = try await store.load()

        XCTAssertEqual(loaded?.devices.first(where: { $0.id == firstDevice.id })?.powerPolicy, firstDevice.powerPolicy)
        XCTAssertEqual(loaded?.devices.first(where: { $0.id == secondDevice.id })?.powerPolicy, secondDevice.powerPolicy)
        XCTAssertNotEqual(firstDevice.powerPolicy, secondDevice.powerPolicy)
    }

    private func permissions(of url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return try XCTUnwrap(attributes[.posixPermissions] as? NSNumber).intValue & 0o777
    }
}
