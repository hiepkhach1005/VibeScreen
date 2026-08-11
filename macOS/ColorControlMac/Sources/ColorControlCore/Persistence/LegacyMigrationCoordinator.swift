import Foundation

public struct LegacyMigrationInput: Sendable {
    public var settings: Data?
    public var lgDevices: Data?
    public var samsungDevices: Data?
    public var lgPresets: Data?
    public var samsungPresets: Data?
    public var gamePresets: Data?
    public var lgRemotes: Data?
    public var samsungRemotes: Data?

    public init(
        settings: Data? = nil,
        lgDevices: Data? = nil,
        samsungDevices: Data? = nil,
        lgPresets: Data? = nil,
        samsungPresets: Data? = nil,
        gamePresets: Data? = nil,
        lgRemotes: Data? = nil,
        samsungRemotes: Data? = nil
    ) {
        self.settings = settings
        self.lgDevices = lgDevices
        self.samsungDevices = samsungDevices
        self.lgPresets = lgPresets
        self.samsungPresets = samsungPresets
        self.gamePresets = gamePresets
        self.lgRemotes = lgRemotes
        self.samsungRemotes = samsungRemotes
    }
}

public struct LegacyMigrationPreview: Sendable, Equatable {
    public let snapshot: NativeStoreSnapshot
    public let issues: [MigrationIssue]

    public init(snapshot: NativeStoreSnapshot, issues: [MigrationIssue]) {
        self.snapshot = snapshot
        self.issues = issues
    }

    public var isSafeToCommit: Bool {
        !issues.contains { $0.severity == .error }
    }
}

/// Coordinates all bounded legacy decoders into one dry-run snapshot. No
/// source file is written and no secret is placed in the resulting JSON.
public enum LegacyMigrationCoordinator {
    public static func preview(_ input: LegacyMigrationInput) -> LegacyMigrationPreview {
        var issues: [MigrationIssue] = []
        var presets: [Preset] = []
        var devices: [TVDeviceDescriptor] = []
        var gamePresets: [GamePreset] = []
        var remotes: [TVRemoteDefinition] = []
        var settings = NativeAppSettings()

        if let data = input.settings {
            do {
                let report = try LegacySettingsImporter.importData(data)
                settings = report.settings
                issues.append(contentsOf: report.issues)
            } catch {
                issues.append(errorIssue(source: "Settings.json", error: error))
            }
        }

        if let data = input.lgDevices {
            appendDeviceReport(
                result: tryReport { try LegacyDeviceImporter.importLG(data: data) },
                devices: &devices,
                issues: &issues
            )
        }
        if let data = input.samsungDevices {
            appendDeviceReport(
                result: tryReport { try LegacyDeviceImporter.importSamsung(data: data) },
                devices: &devices,
                issues: &issues
            )
        }
        if let data = input.lgPresets {
            appendPresetReport(
                result: tryReport { try LegacyPresetImporter.importLG(data: data) },
                presets: &presets,
                issues: &issues
            )
        }
        if let data = input.samsungPresets {
            appendPresetReport(
                result: tryReport { try LegacyPresetImporter.importSamsung(data: data) },
                presets: &presets,
                issues: &issues
            )
        }
        if let data = input.gamePresets {
            switch tryReport({ try LegacyGameImporter.importData(data) }) {
            case let .success(report):
                gamePresets.append(contentsOf: report.presets)
                issues.append(contentsOf: report.issues)
            case let .failure(error):
                issues.append(errorIssue(source: "GamePresets.json", error: error))
            }
        }
        if let data = input.lgRemotes {
            appendRemoteReport(
                result: tryReport { try LegacyRemoteImporter.importLG(data: data) },
                remotes: &remotes,
                issues: &issues
            )
        }
        if let data = input.samsungRemotes {
            appendRemoteReport(
                result: tryReport { try LegacyRemoteImporter.importSamsung(data: data) },
                remotes: &remotes,
                issues: &issues
            )
        }

        let snapshot = NativeStoreSnapshot(
            presets: deduplicate(presets, key: \.id, issues: &issues, source: "presets"),
            devices: deduplicate(devices, key: \.id, issues: &issues, source: "devices"),
            gamePresets: deduplicate(gamePresets, key: \.id, issues: &issues, source: "gamePresets"),
            remotes: deduplicate(remotes, key: \.id, issues: &issues, source: "remotes"),
            settings: settings
        )
        return LegacyMigrationPreview(snapshot: snapshot, issues: issues)
    }

    public static func commit(
        _ preview: LegacyMigrationPreview,
        to store: NativeStore
    ) async throws {
        guard preview.isSafeToCommit else {
            throw ColorControlCoreError.actionRejected("Migration contains errors and cannot be committed.")
        }
        try await store.save(preview.snapshot)
    }

    private static func tryReport<T>(_ operation: () throws -> T) -> Result<T, any Error> {
        do { return .success(try operation()) }
        catch { return .failure(error) }
    }

    private static func appendPresetReport(
        result: Result<PresetMigrationReport, any Error>,
        presets: inout [Preset],
        issues: inout [MigrationIssue]
    ) {
        switch result {
        case let .success(report):
            presets.append(contentsOf: report.presets)
            issues.append(contentsOf: report.issues)
        case let .failure(error):
            issues.append(errorIssue(source: "preset import", error: error))
        }
    }

    private static func appendDeviceReport(
        result: Result<DeviceMigrationReport, any Error>,
        devices: inout [TVDeviceDescriptor],
        issues: inout [MigrationIssue]
    ) {
        switch result {
        case let .success(report):
            devices.append(contentsOf: report.devices)
            issues.append(contentsOf: report.issues)
        case let .failure(error):
            issues.append(errorIssue(source: "device import", error: error))
        }
    }

    private static func appendRemoteReport(
        result: Result<RemoteMigrationReport, any Error>,
        remotes: inout [TVRemoteDefinition],
        issues: inout [MigrationIssue]
    ) {
        switch result {
        case let .success(report):
            remotes.append(contentsOf: report.remotes)
            issues.append(contentsOf: report.issues)
        case let .failure(error):
            issues.append(errorIssue(source: "remote import", error: error))
        }
    }

    private static func deduplicate<T: Identifiable>(
        _ values: [T],
        key: (T) -> T.ID,
        issues: inout [MigrationIssue],
        source: String
    ) -> [T] where T.ID: Hashable {
        var seen: Set<T.ID> = []
        return values.filter { value in
            guard seen.insert(key(value)).inserted else {
                issues.append(MigrationIssue(
                    severity: .warning,
                    source: source,
                    message: "Duplicate migrated record was ignored."
                ))
                return false
            }
            return true
        }
    }

    private static func errorIssue(source: String, error: any Error) -> MigrationIssue {
        MigrationIssue(
            severity: .error,
            source: source,
            message: "Migration decoder failed: \(error.localizedDescription)"
        )
    }
}
