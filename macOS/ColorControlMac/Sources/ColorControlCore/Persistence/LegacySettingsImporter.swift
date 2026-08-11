import Foundation

public struct SettingsMigrationReport: Sendable, Equatable {
    public let source: String
    public let settings: NativeAppSettings
    public let issues: [MigrationIssue]

    public init(source: String, settings: NativeAppSettings, issues: [MigrationIssue]) {
        self.source = source
        self.settings = settings
        self.issues = issues
    }
}

public enum LegacySettingsImporter {
    public static func importData(
        _ data: Data,
        source: String = "Settings.json"
    ) throws -> SettingsMigrationReport {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let record = object as? [String: Any] else {
            return SettingsMigrationReport(
                source: source,
                settings: NativeAppSettings(),
                issues: [MigrationIssue(
                    severity: .error,
                    source: source,
                    message: "Expected a JSON object for application settings."
                )]
            )
        }

        var issues: [MigrationIssue] = []
        if hasAny(record, keys: ["UiType", "UiPort", "UiAllowRemoteConnections"]) {
            issues.append(MigrationIssue(
                severity: .warning,
                source: source,
                message: "Legacy web UI settings were ignored because the native app has no web server or browser UI."
            ))
        }
        if hasAny(record, keys: ["NvPresetId_ApplyOnStartup", "AmdPresetId_ApplyOnStartup", "NvPresetsSortState", "AmdPresetsSortState"]) {
            issues.append(MigrationIssue(
                severity: .warning,
                source: source,
                message: "NVIDIA/AMD settings were intentionally excluded from the native macOS configuration."
            ))
        }
        if hasAny(record, keys: ["ElevationMethod", "UseDedicatedElevatedProcess", "ElevationMethodAsked"]) {
            issues.append(MigrationIssue(
                severity: .warning,
                source: source,
                message: "Windows elevation settings were excluded; native actions use documented macOS permissions."
            ))
        }

        let settings = NativeAppSettings(
            launchAtLogin: bool(record, keys: ["AutoStart", "autoStart"]) ?? false,
            startHidden: bool(record, keys: ["StartMinimized", "startMinimized"]) ?? false,
            minimizeToMenuBar: bool(record, keys: ["MinimizeToTray", "minimizeToTray"]) ?? true,
            checkForUpdates: bool(record, keys: ["CheckForUpdates", "checkForUpdates"]) ?? true,
            logLevel: string(record, keys: ["LogLevel", "logLevel"]) ?? "info",
            processMonitorIntervalMilliseconds: integer(record, keys: ["ProcessMonitorPollingInterval", "processMonitorPollingInterval"]) ?? 1_000
        )

        return SettingsMigrationReport(source: source, settings: settings, issues: issues)
    }

    private static func hasAny(_ record: [String: Any], keys: [String]) -> Bool {
        keys.contains { record[$0] != nil }
    }

    private static func string(_ record: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = record[key] as? String, !value.isEmpty { return value }
        }
        return nil
    }

    private static func bool(_ record: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let value = record[key] as? Bool { return value }
            if let value = record[key] as? NSNumber { return value.boolValue }
        }
        return nil
    }

    private static func integer(_ record: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let value = record[key] as? Int { return value }
            if let value = record[key] as? NSNumber { return value.intValue }
        }
        return nil
    }
}
