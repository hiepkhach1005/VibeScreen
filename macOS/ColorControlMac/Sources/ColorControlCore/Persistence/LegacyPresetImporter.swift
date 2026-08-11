import Foundation

public enum MigrationIssueSeverity: String, Codable, Sendable, Equatable {
    case warning
    case error
}

public struct MigrationIssue: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let severity: MigrationIssueSeverity
    public let source: String
    public let message: String

    public init(
        id: UUID = UUID(),
        severity: MigrationIssueSeverity,
        source: String,
        message: String
    ) {
        self.id = id
        self.severity = severity
        self.source = source
        self.message = message
    }
}

public struct PresetMigrationReport: Sendable, Equatable {
    public let source: String
    public let presets: [Preset]
    public let issues: [MigrationIssue]

    public init(source: String, presets: [Preset], issues: [MigrationIssue]) {
        self.source = source
        self.presets = presets
        self.issues = issues
    }
}

/// Imports the JSON shape used by the legacy LG/Samsung preset classes. It is
/// intentionally dry-run friendly: callers receive a report and decide when
/// to write the returned records into NativeStore.
public enum LegacyPresetImporter {
    public static func importLG(data: Data, source: String = "LgPresets.json") throws -> PresetMigrationReport {
        try importPresets(data: data, source: source, applicationKey: "appId")
    }

    public static func importSamsung(data: Data, source: String = "SamsungPresets.json") throws -> PresetMigrationReport {
        try importPresets(data: data, source: source, applicationKey: "AppId")
    }

    private static func importPresets(
        data: Data,
        source: String,
        applicationKey: String
    ) throws -> PresetMigrationReport {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let records = object as? [[String: Any]] else {
            return PresetMigrationReport(
                source: source,
                presets: [],
                issues: [MigrationIssue(severity: .error, source: source, message: "Expected a JSON array of preset objects.")]
            )
        }

        var presets: [Preset] = []
        var issues: [MigrationIssue] = []

        for (index, record) in records.enumerated() {
            let recordSource = "\(source)[\(index)]"
            guard let name = string(record, keys: ["name", "Name"]), !name.isEmpty else {
                issues.append(MigrationIssue(severity: .error, source: recordSource, message: "Preset has no name; it was not imported."))
                continue
            }

            let legacyID = integer(record, keys: ["id", "Id"])
            let steps = (record["steps"] as? [Any] ?? record["Steps"] as? [Any] ?? [])
                .compactMap { $0 as? String }
                .map { PresetStepParser.parse($0) }

            let triggers = parseTriggers(record, source: recordSource, issues: &issues)
            let conditionInfo = conditionProjection(record, source: recordSource, issues: &issues)

            let stableID = StableMigrationID.make(
                source: source,
                legacyID: legacyID,
                name: name,
                index: index
            )

            let preset = Preset(
                id: stableID,
                name: name,
                shortcut: string(record, keys: ["shortcut", "Shortcut"]) ?? "",
                triggers: triggers.map { trigger in
                    PresetTrigger(
                        id: trigger.id,
                        kind: trigger.kind,
                        includedProcesses: trigger.includedProcesses,
                        excludedProcesses: trigger.excludedProcesses,
                        connectedDisplayPattern: trigger.connectedDisplayPattern,
                        requiresHDR: trigger.requiresHDR ?? conditionInfo.requiresHDR,
                        requiresFullscreen: trigger.requiresFullscreen ?? conditionInfo.requiresFullscreen,
                        requiresNotificationsDisabled: trigger.requiresNotificationsDisabled ?? conditionInfo.requiresNotificationsDisabled
                    )
                },
                steps: steps,
                description: string(record, keys: ["Description", "description"]) ?? "",
                showInQuickAccess: bool(record, keys: ["ShowInQuickAccess", "showInQuickAccess"]) ?? false,
                lastUsed: date(record, keys: ["LastUsed", "lastUsed"]),
                targetDeviceAddress: string(record, keys: ["DeviceMacAddress", "deviceMacAddress"]),
                applicationIdentifier: string(record, keys: [applicationKey]),
                legacyNumericIdentifier: legacyID
            )

            if steps.isEmpty {
                issues.append(MigrationIssue(severity: .warning, source: recordSource, message: "Preset imported without steps."))
            }
            presets.append(preset)
        }

        return PresetMigrationReport(source: source, presets: presets, issues: issues)
    }

    private static func parseTriggers(
        _ record: [String: Any],
        source: String,
        issues: inout [MigrationIssue]
    ) -> [PresetTrigger] {
        let values = (record["Triggers"] as? [[String: Any]]) ?? (record["triggers"] as? [[String: Any]]) ?? []

        return values.compactMap { trigger in
            let rawTrigger = integer(trigger, keys: ["Trigger", "trigger"]) ?? 0
            guard let kind = triggerKind(rawTrigger) else {
                issues.append(MigrationIssue(severity: .warning, source: source, message: "Unsupported or empty trigger \(rawTrigger) was skipped."))
                return nil
            }

            return PresetTrigger(
                kind: kind,
                includedProcesses: strings(trigger, keys: ["IncludedProcesses", "includedProcesses"]),
                excludedProcesses: strings(trigger, keys: ["ExcludedProcesses", "excludedProcesses"]),
                connectedDisplayPattern: string(trigger, keys: ["ConnectedDisplaysRegex", "connectedDisplayPattern"]),
                requiresHDR: nil,
                requiresFullscreen: nil,
                requiresNotificationsDisabled: nil
            )
        }
    }

    private static func triggerKind(_ value: Int) -> PresetTriggerKind? {
        switch value {
        case 1: return .startup
        case 2: return .resume
        case 3: return .shutdown
        case 4: return .standby
        case 6: return .processSwitch
        case 7: return .screensaverStart
        case 8: return .screensaverStop
        case 9: return .displayChange
        default: return nil
        }
    }

    private static func conditionProjection(
        _ record: [String: Any],
        source: String,
        issues: inout [MigrationIssue]
    ) -> (requiresHDR: Bool?, requiresFullscreen: Bool?, requiresNotificationsDisabled: Bool?) {
        let triggers = (record["Triggers"] as? [[String: Any]]) ?? (record["triggers"] as? [[String: Any]]) ?? []
        let rawValues = triggers.compactMap { integer($0, keys: ["Conditions", "conditions"]) }
        guard let flags = rawValues.first else {
            return (nil, nil, nil)
        }

        if flags & 16 != 0 || flags & 32 != 0 {
            issues.append(MigrationIssue(severity: .warning, source: source, message: "G-SYNC conditions were omitted because the native app has no NVIDIA dependency."))
        }
        if flags & 1 != 0 && flags & 2 != 0 {
            issues.append(MigrationIssue(severity: .warning, source: source, message: "Preset requested both SDR and HDR; condition was left unresolved for manual review."))
        }

        let hdr: Bool?
        if flags & 2 != 0 { hdr = true }
        else if flags & 1 != 0 { hdr = false }
        else { hdr = nil }

        return (
            hdr,
            flags & 4 != 0 ? true : nil,
            flags & 8 != 0 ? true : nil
        )
    }

    private static func string(_ record: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = record[key] as? String, !value.isEmpty { return value }
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

    private static func bool(_ record: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let value = record[key] as? Bool { return value }
            if let value = record[key] as? NSNumber { return value.boolValue }
        }
        return nil
    }

    private static func strings(_ record: [String: Any], keys: [String]) -> [String] {
        for key in keys {
            if let value = record[key] as? [String] { return value }
            if let value = record[key] as? [Any] { return value.compactMap { $0 as? String } }
        }
        return []
    }

    private static func date(_ record: [String: Any], keys: [String]) -> Date? {
        guard let raw = string(record, keys: keys) else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }
}

enum StableMigrationID {
    static func make(source: String, legacyID: Int?, name: String, index: Int) -> UUID {
        let seed = "\(source)|\(legacyID.map(String.init) ?? "none")|\(name)|\(index)"
        var first: UInt64 = 14_695_981_039_346_656_037
        var second: UInt64 = 10_995_116_282_112_351_651

        for byte in seed.utf8 {
            first ^= UInt64(byte)
            first &*= 1_099_511_628_211
            second ^= UInt64(byte &+ 31)
            second &*= 1_099_511_628_211
        }

        var bytes = [UInt8](repeating: 0, count: 16)
        for index in 0..<8 {
            bytes[index] = UInt8((first >> UInt64(index * 8)) & 0xFF)
            bytes[index + 8] = UInt8((second >> UInt64(index * 8)) & 0xFF)
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
