import Foundation

public struct GameMigrationReport: Sendable, Equatable {
    public let source: String
    public let presets: [GamePreset]
    public let issues: [MigrationIssue]

    public init(source: String, presets: [GamePreset], issues: [MigrationIssue]) {
        self.source = source
        self.presets = presets
        self.issues = issues
    }
}

public enum LegacyGameImporter {
    public static func importData(
        _ data: Data,
        source: String = "GamePresets.json"
    ) throws -> GameMigrationReport {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let records = object as? [[String: Any]] else {
            return GameMigrationReport(
                source: source,
                presets: [],
                issues: [MigrationIssue(
                    severity: .error,
                    source: source,
                    message: "Expected a JSON array of game presets."
                )]
            )
        }

        var presets: [GamePreset] = []
        var issues: [MigrationIssue] = []

        for (index, record) in records.enumerated() {
            let recordSource = "\(source)[\(index)]"
            guard let name = string(record, keys: ["name", "Name"]), !name.isEmpty else {
                issues.append(MigrationIssue(
                    severity: .error,
                    source: recordSource,
                    message: "Game preset has no name; it was not imported."
                ))
                continue
            }

            let path = string(record, keys: ["Path", "path"])
            let launch: GameLaunchSpecification?
            if let path, !path.isEmpty {
                let parameters = string(record, keys: ["Parameters", "parameters"]) ?? ""
                launch = GameLaunchSpecification(
                    pathOrBundleIdentifier: path,
                    arguments: tokenize(parameters),
                    workingDirectory: string(record, keys: ["WorkingDirectory", "workingDirectory"])
                )

                if path.contains("\\") || path.range(of: #"^[A-Za-z]:"#, options: .regularExpression) != nil {
                    issues.append(MigrationIssue(
                        severity: .warning,
                        source: recordSource,
                        message: "Windows executable path was retained as an unresolved launch target; choose a macOS app or bundle identifier."
                    ))
                }
            } else {
                launch = nil
                issues.append(MigrationIssue(
                    severity: .warning,
                    source: recordSource,
                    message: "Game preset has no launch path."
                ))
            }

            let autoSettings = (record["AutoSettings"] as? [String: Any])
                ?? (record["autoSettings"] as? [String: Any])
                ?? [:]
            let action = processAction(autoSettings)
            let nativeAction: GameProcessAutoAction = action == .suspend ? .none : action
            if action != .none && action != .restart {
                issues.append(MigrationIssue(
                    severity: .warning,
                    source: recordSource,
                    message: "Process suspension has no public macOS equivalent and was normalized to no automatic process action."
                ))
            }

            let stableID = StableMigrationID.make(
                source: source,
                legacyID: integer(record, keys: ["id", "Id"]),
                name: name,
                index: index
            )
            presets.append(
                GamePreset(
                    id: stableID,
                    name: name,
                    launch: launch,
                    preLaunchSteps: steps(record, keys: ["PreLaunchSteps", "preLaunchSteps"]),
                    postLaunchSteps: steps(record, keys: ["PostLaunchSteps", "postLaunchSteps"]),
                    finalizeSteps: steps(record, keys: ["FinalizeSteps", "finalizeSteps"]),
                    autoApply: bool(autoSettings, keys: ["AllowAutoApply", "allowAutoApply"]) ?? false,
                    processAutoAction: nativeAction,
                    showInQuickAccess: bool(record, keys: ["ShowInQuickAccess", "showInQuickAccess"]) ?? false
                )
            )
        }

        return GameMigrationReport(source: source, presets: presets, issues: issues)
    }

    private static func steps(_ record: [String: Any], keys: [String]) -> [PresetStep] {
        for key in keys {
            if let values = record[key] as? [String] {
                return values.map { PresetStepParser.parse($0) }
            }
            if let values = record[key] as? [Any] {
                return values.compactMap { $0 as? String }.map { PresetStepParser.parse($0) }
            }
        }
        return []
    }

    private static func processAction(_ record: [String: Any]) -> GameProcessAutoAction {
        if let value = integer(record, keys: ["ProcessAutoAction", "processAutoAction"]) {
            switch value {
            case 1: return .suspend
            case 2: return .restart
            default: return .none
            }
        }

        switch string(record, keys: ["ProcessAutoAction", "processAutoAction"])?.lowercased() {
        case "suspend": return .suspend
        case "restart": return .restart
        default: return .none
        }
    }

    private static func tokenize(_ value: String) -> [String] {
        var result: [String] = []
        var current = ""
        var quoted = false

        for character in value {
            if character == "\"" {
                quoted.toggle()
            } else if character.isWhitespace && !quoted {
                if !current.isEmpty {
                    result.append(current)
                    current.removeAll(keepingCapacity: true)
                }
            } else {
                current.append(character)
            }
        }

        if !current.isEmpty {
            result.append(current)
        }
        return result
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
}
