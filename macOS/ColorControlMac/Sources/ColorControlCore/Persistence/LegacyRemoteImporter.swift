import Foundation

public struct RemoteMigrationReport: Sendable, Equatable {
    public let source: String
    public let remotes: [TVRemoteDefinition]
    public let issues: [MigrationIssue]

    public init(source: String, remotes: [TVRemoteDefinition], issues: [MigrationIssue]) {
        self.source = source
        self.remotes = remotes
        self.issues = issues
    }
}

public enum LegacyRemoteImporter {
    public static func importLG(data: Data, source: String = "LgRemotes.json") throws -> RemoteMigrationReport {
        try importData(data, source: source, kind: .lgWebOS)
    }

    public static func importSamsung(data: Data, source: String = "SamsungRemotes.json") throws -> RemoteMigrationReport {
        try importData(data, source: source, kind: .samsungTizen)
    }

    private static func importData(
        _ data: Data,
        source: String,
        kind: TVDeviceKind
    ) throws -> RemoteMigrationReport {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let records = object as? [[String: Any]] else {
            return RemoteMigrationReport(
                source: source,
                remotes: [],
                issues: [MigrationIssue(
                    severity: .error,
                    source: source,
                    message: "Expected a JSON array of remote definitions."
                )]
            )
        }

        var remotes: [TVRemoteDefinition] = []
        var issues: [MigrationIssue] = []

        for (index, record) in records.enumerated() {
            let recordSource = "\(source)[\(index)]"
            let name = string(record, keys: ["Name", "name"]) ?? "Remote \(index + 1)"
            let buttonRecords = (record["Buttons"] as? [[String: Any]])
                ?? (record["buttons"] as? [[String: Any]])
                ?? []
            let remoteID = StableMigrationID.make(
                source: source,
                legacyID: nil,
                name: name,
                index: index
            )

            let buttons = buttonRecords.enumerated().map { buttonIndex, button in
                let payload = (try? JSONSerialization.data(withJSONObject: button))
                    .flatMap { try? JSONDecoder().decode(JSONValue.self, from: $0) }
                return TVRemoteButtonDefinition(
                    id: StableMigrationID.make(
                        source: recordSource,
                        legacyID: nil,
                        name: string(button, keys: ["Name", "name"]) ?? "Button \(buttonIndex + 1)",
                        index: buttonIndex
                    ),
                    name: string(button, keys: ["Name", "name"]) ?? "Button \(buttonIndex + 1)",
                    command: commandString(button),
                    top: number(button, keys: ["Top", "top"]),
                    left: number(button, keys: ["Left", "left"]),
                    legacyPayload: payload
                )
            }

            if buttons.isEmpty {
                issues.append(MigrationIssue(
                    severity: .warning,
                    source: recordSource,
                    message: "Remote has no buttons; it was imported for manual editing."
                ))
            }

            remotes.append(
                TVRemoteDefinition(
                    id: remoteID,
                    kind: kind,
                    name: name,
                    imageFileName: string(record, keys: ["ImageFileName", "imageFileName"]),
                    buttons: buttons
                )
            )
        }

        return RemoteMigrationReport(source: source, remotes: remotes, issues: issues)
    }

    private static func commandString(_ record: [String: Any]) -> String {
        for key in ["Button", "button", "Command", "command"] {
            if let value = record[key] as? String { return value }
            if let value = record[key] as? NSNumber { return value.stringValue }
        }
        return "legacy"
    }

    private static func string(_ record: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = record[key] as? String, !value.isEmpty { return value }
        }
        return nil
    }

    private static func number(_ record: [String: Any], keys: [String]) -> Double {
        for key in keys {
            if let value = record[key] as? NSNumber { return value.doubleValue }
        }
        return 0
    }
}
