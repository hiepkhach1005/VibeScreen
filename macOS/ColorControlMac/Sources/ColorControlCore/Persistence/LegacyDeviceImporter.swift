import Foundation

public struct DeviceMigrationReport: Sendable, Equatable {
    public let source: String
    public let devices: [TVDeviceDescriptor]
    public let issues: [MigrationIssue]

    public init(source: String, devices: [TVDeviceDescriptor], issues: [MigrationIssue]) {
        self.source = source
        self.devices = devices
        self.issues = issues
    }
}

public enum LegacyDeviceImporter {
    public static func importLG(data: Data, source: String = "LgConfig.json") throws -> DeviceMigrationReport {
        try importDevices(data: data, source: source, kind: .lgWebOS)
    }

    public static func importSamsung(data: Data, source: String = "SamsungConfig.json") throws -> DeviceMigrationReport {
        try importDevices(data: data, source: source, kind: .samsungTizen)
    }

    private static func importDevices(
        data: Data,
        source: String,
        kind: TVDeviceKind
    ) throws -> DeviceMigrationReport {
        let object = try JSONSerialization.jsonObject(with: data)
        let records: [[String: Any]]

        if let array = object as? [[String: Any]] {
            records = array
        } else if let dictionary = object as? [String: Any],
                  let nested = dictionary["Devices"] as? [[String: Any]] ?? dictionary["devices"] as? [[String: Any]] {
            records = nested
        } else {
            return DeviceMigrationReport(
                source: source,
                devices: [],
                issues: [MigrationIssue(severity: .error, source: source, message: "Expected a device array or an object containing Devices."))]
            )
        }

        var devices: [TVDeviceDescriptor] = []
        var issues: [MigrationIssue] = []

        for (index, record) in records.enumerated() {
            let recordSource = "\(source)[\(index)]"
            guard let host = value(record, keys: ["IpAddress", "ipAddress", "Host", "host"]), !host.isEmpty else {
                issues.append(MigrationIssue(severity: .error, source: recordSource, message: "Device has no IP address; it was not imported."))
                continue
            }

            let name = value(record, keys: ["Name", "name"]) ?? host
            let macAddress = value(record, keys: ["MacAddress", "macAddress"])
            let options = (record["Options"] as? [String: Any]) ?? (record["options"] as? [String: Any]) ?? [:]
            let stableID = StableMigrationID.make(
                source: source,
                legacyID: nil,
                name: "\(name)|\(host)|\(macAddress ?? "")",
                index: index
            )

            let hasToken = value(record, keys: ["Token", "token"]) != nil
            let credentialReference = "tv-credential-\(stableID.uuidString.lowercased())"
            if hasToken {
                issues.append(MigrationIssue(
                    severity: .warning,
                    source: recordSource,
                    message: "Pairing token was not copied into JSON; the macOS app must save it to Keychain under \(credentialReference)."
                ))
            }
            if options["PowerOffByWindows"] != nil || options["powerOffByWindows"] != nil
                || options["PowerOnByWindows"] != nil || options["powerOnByWindows"] != nil {
                issues.append(MigrationIssue(
                    severity: .warning,
                    source: recordSource,
                    message: "Windows monitor power options were mapped to macOS screen sleep/wake policy."
                ))
            }

            devices.append(
                TVDeviceDescriptor(
                    id: stableID,
                    name: name,
                    kind: kind,
                    host: host,
                    macAddress: macAddress,
                    usesSecureConnection: bool(options, keys: ["UseSecureConnection", "useSecureConnection"]) ?? true,
                    credentialReference: credentialReference,
                    powerPolicy: powerPolicy(options)
                )
            )
        }

        return DeviceMigrationReport(source: source, devices: devices, issues: issues)
    }

    private static func powerPolicy(_ options: [String: Any]) -> TVPowerPolicy {
        TVPowerPolicy(
            powerOnAfterStartup: bool(options, keys: ["PowerOnAfterStartup", "powerOnAfterStartup"]) ?? false,
            powerOnAfterResume: bool(options, keys: ["PowerOnAfterResume", "powerOnAfterResume"]) ?? false,
            powerOffOnShutdown: bool(options, keys: ["PowerOffOnShutdown", "powerOffOnShutdown"]) ?? false,
            powerOffOnStandby: bool(options, keys: ["PowerOffOnStandby", "powerOffOnStandby"]) ?? false,
            powerOffOnScreenSaver: bool(options, keys: ["PowerOffOnScreenSaver", "powerOffOnScreenSaver"])
                ?? bool(options, keys: ["PowerOffByWindows", "powerOffByWindows"])
                ?? false,
            powerOnAfterScreenSaver: bool(options, keys: ["PowerOnAfterScreenSaver", "powerOnAfterScreenSaver"])
                ?? bool(options, keys: ["PowerOnByWindows", "powerOnByWindows"])
                ?? false,
            powerOnAfterManualPowerOff: bool(options, keys: ["PowerOnAfterManualPowerOff", "powerOnAfterManualPowerOff"]) ?? false,
            powerOffAfterSessionLock: bool(options, keys: ["PowerOffAfterSessionLock", "powerOffAfterSessionLock"]) ?? false,
            powerOnAfterSessionUnlock: bool(options, keys: ["PowerOnAfterSessionUnlock", "powerOnAfterSessionUnlock"]) ?? false,
            turnScreenOffOnScreenSaver: bool(options, keys: ["TurnScreenOffOnScreenSaver", "turnScreenOffOnScreenSaver"]) ?? false,
            turnScreenOnAfterScreenSaver: bool(options, keys: ["TurnScreenOnAfterScreenSaver", "turnScreenOnAfterScreenSaver"]) ?? false,
            screenSaverMinimumDuration: integer(options, keys: ["ScreenSaverMinimalDuration", "screenSaverMinimalDuration"]) ?? 0,
            triggersEnabled: bool(options, keys: ["TriggersEnabled", "triggersEnabled"]) ?? true
        )
    }

    private static func value(_ record: [String: Any], keys: [String]) -> String? {
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
