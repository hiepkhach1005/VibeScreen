import Foundation

public enum TVDeviceKind: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case lgWebOS
    case samsungTizen
}

public enum TVConnectionState: String, Codable, Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case pairingRequired
    case failed
}

public enum TVPowerState: String, Codable, Sendable, Equatable {
    case on
    case off
    case unknown
}

public struct TVPowerPolicy: Codable, Sendable, Equatable {
    public var powerOnAfterStartup: Bool
    public var powerOnAfterResume: Bool
    public var powerOffOnShutdown: Bool
    public var turnScreenOffOnShutdown: Bool
    public var turnScreenOnAfterStartup: Bool
    public var powerOffOnStandby: Bool
    public var powerOffOnScreenSaver: Bool
    public var powerOnAfterScreenSaver: Bool
    public var powerOnAfterManualPowerOff: Bool
    public var powerOffAfterSessionLock: Bool
    public var powerOnAfterSessionUnlock: Bool
    public var turnScreenOffOnScreenSaver: Bool
    public var turnScreenOnAfterScreenSaver: Bool
    public var screenSaverMinimumDuration: Int
    public var triggersEnabled: Bool

    public init(
        powerOnAfterStartup: Bool = false,
        powerOnAfterResume: Bool = false,
        powerOffOnShutdown: Bool = false,
        turnScreenOffOnShutdown: Bool = false,
        turnScreenOnAfterStartup: Bool = false,
        powerOffOnStandby: Bool = false,
        powerOffOnScreenSaver: Bool = false,
        powerOnAfterScreenSaver: Bool = false,
        powerOnAfterManualPowerOff: Bool = false,
        powerOffAfterSessionLock: Bool = false,
        powerOnAfterSessionUnlock: Bool = false,
        turnScreenOffOnScreenSaver: Bool = false,
        turnScreenOnAfterScreenSaver: Bool = false,
        screenSaverMinimumDuration: Int = 0,
        triggersEnabled: Bool = true
    ) {
        self.powerOnAfterStartup = powerOnAfterStartup
        self.powerOnAfterResume = powerOnAfterResume
        self.powerOffOnShutdown = powerOffOnShutdown
        self.turnScreenOffOnShutdown = turnScreenOffOnShutdown
        self.turnScreenOnAfterStartup = turnScreenOnAfterStartup
        self.powerOffOnStandby = powerOffOnStandby
        self.powerOffOnScreenSaver = powerOffOnScreenSaver
        self.powerOnAfterScreenSaver = powerOnAfterScreenSaver
        self.powerOnAfterManualPowerOff = powerOnAfterManualPowerOff
        self.powerOffAfterSessionLock = powerOffAfterSessionLock
        self.powerOnAfterSessionUnlock = powerOnAfterSessionUnlock
        self.turnScreenOffOnScreenSaver = turnScreenOffOnScreenSaver
        self.turnScreenOnAfterScreenSaver = turnScreenOnAfterScreenSaver
        self.screenSaverMinimumDuration = max(0, screenSaverMinimumDuration)
        self.triggersEnabled = triggersEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case powerOnAfterStartup
        case powerOnAfterResume
        case powerOffOnShutdown
        case turnScreenOffOnShutdown
        case turnScreenOnAfterStartup
        case powerOffOnStandby
        case powerOffOnScreenSaver
        case powerOnAfterScreenSaver
        case powerOnAfterManualPowerOff
        case powerOffAfterSessionLock
        case powerOnAfterSessionUnlock
        case turnScreenOffOnScreenSaver
        case turnScreenOnAfterScreenSaver
        case screenSaverMinimumDuration
        case triggersEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            powerOnAfterStartup: try container.decodeIfPresent(Bool.self, forKey: .powerOnAfterStartup) ?? false,
            powerOnAfterResume: try container.decodeIfPresent(Bool.self, forKey: .powerOnAfterResume) ?? false,
            powerOffOnShutdown: try container.decodeIfPresent(Bool.self, forKey: .powerOffOnShutdown) ?? false,
            turnScreenOffOnShutdown: try container.decodeIfPresent(Bool.self, forKey: .turnScreenOffOnShutdown) ?? false,
            turnScreenOnAfterStartup: try container.decodeIfPresent(Bool.self, forKey: .turnScreenOnAfterStartup) ?? false,
            powerOffOnStandby: try container.decodeIfPresent(Bool.self, forKey: .powerOffOnStandby) ?? false,
            powerOffOnScreenSaver: try container.decodeIfPresent(Bool.self, forKey: .powerOffOnScreenSaver) ?? false,
            powerOnAfterScreenSaver: try container.decodeIfPresent(Bool.self, forKey: .powerOnAfterScreenSaver) ?? false,
            powerOnAfterManualPowerOff: try container.decodeIfPresent(Bool.self, forKey: .powerOnAfterManualPowerOff) ?? false,
            powerOffAfterSessionLock: try container.decodeIfPresent(Bool.self, forKey: .powerOffAfterSessionLock) ?? false,
            powerOnAfterSessionUnlock: try container.decodeIfPresent(Bool.self, forKey: .powerOnAfterSessionUnlock) ?? false,
            turnScreenOffOnScreenSaver: try container.decodeIfPresent(Bool.self, forKey: .turnScreenOffOnScreenSaver) ?? false,
            turnScreenOnAfterScreenSaver: try container.decodeIfPresent(Bool.self, forKey: .turnScreenOnAfterScreenSaver) ?? false,
            screenSaverMinimumDuration: try container.decodeIfPresent(Int.self, forKey: .screenSaverMinimumDuration) ?? 0,
            triggersEnabled: try container.decodeIfPresent(Bool.self, forKey: .triggersEnabled) ?? true
        )
    }
}

public struct TVDeviceDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var kind: TVDeviceKind
    public var host: String
    public var macAddress: String?
    public var usesSecureConnection: Bool
    public var credentialReference: String?
    public var trustedCertificateSHA256: String?
    public var powerPolicy: TVPowerPolicy

    public init(
        id: UUID = UUID(),
        name: String,
        kind: TVDeviceKind,
        host: String,
        macAddress: String? = nil,
        usesSecureConnection: Bool = false,
        credentialReference: String? = nil,
        trustedCertificateSHA256: String? = nil,
        powerPolicy: TVPowerPolicy = TVPowerPolicy()
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.host = host
        self.macAddress = macAddress
        self.usesSecureConnection = usesSecureConnection
        self.credentialReference = credentialReference
        self.trustedCertificateSHA256 = trustedCertificateSHA256
        self.powerPolicy = powerPolicy
    }
}

public enum TVPowerCommand: String, Codable, Sendable, Equatable {
    case powerOff
    case powerOn
    case screenOff
    case screenOn
}

public struct TVPowerAction: Codable, Sendable, Equatable {
    public let command: TVPowerCommand
    public let delaySeconds: Int

    public init(command: TVPowerCommand, delaySeconds: Int = 0) {
        self.command = command
        self.delaySeconds = max(0, delaySeconds)
    }
}

public enum TVPowerPolicyEngine {
    public static func actions(
        for signal: PlatformSignalKind,
        device: TVDeviceDescriptor,
        manualPowerOff: Bool = false
    ) -> [TVPowerAction] {
        guard device.powerPolicy.triggersEnabled else { return [] }
        let policy = device.powerPolicy

        switch signal {
        case .startup:
            if policy.turnScreenOnAfterStartup {
                return automaticPowerOnActions(
                    enabled: true,
                    command: .screenOn,
                    policy: policy,
                    manualPowerOff: manualPowerOff
                )
            }
            return automaticPowerOnActions(
                enabled: policy.powerOnAfterStartup,
                command: .powerOn,
                policy: policy,
                manualPowerOff: manualPowerOff
            )
        case .didWake:
            return automaticPowerOnActions(
                enabled: policy.powerOnAfterResume,
                command: .powerOn,
                policy: policy,
                manualPowerOff: manualPowerOff
            )
        case .willPowerOff:
            if policy.turnScreenOffOnShutdown {
                return [TVPowerAction(command: .screenOff)]
            }
            return policy.powerOffOnShutdown ? [TVPowerAction(command: .powerOff)] : []
        case .willSleep:
            return policy.powerOffOnStandby ? [TVPowerAction(command: .powerOff)] : []
        case .screensDidSleep:
            guard policy.powerOffOnScreenSaver else { return [] }
            let command: TVPowerCommand = policy.turnScreenOffOnScreenSaver ? .screenOff : .powerOff
            return [TVPowerAction(command: command, delaySeconds: policy.screenSaverMinimumDuration)]
        case .screensDidWake:
            if policy.turnScreenOffOnScreenSaver && policy.turnScreenOnAfterScreenSaver {
                return automaticPowerOnActions(
                    enabled: true,
                    command: .screenOn,
                    policy: policy,
                    manualPowerOff: manualPowerOff
                )
            }
            return automaticPowerOnActions(
                enabled: policy.powerOnAfterScreenSaver,
                command: .powerOn,
                policy: policy,
                manualPowerOff: manualPowerOff
            )
        case .sessionDidResignActive:
            return policy.powerOffAfterSessionLock ? [TVPowerAction(command: .powerOff)] : []
        case .sessionDidBecomeActive:
            return automaticPowerOnActions(
                enabled: policy.powerOnAfterSessionUnlock,
                command: .powerOn,
                policy: policy,
                manualPowerOff: manualPowerOff
            )
        case .applicationActivityChanged, .displayConfigurationChanged:
            return []
        }
    }

    private static func automaticPowerOnActions(
        enabled: Bool,
        command: TVPowerCommand,
        policy: TVPowerPolicy,
        manualPowerOff: Bool
    ) -> [TVPowerAction] {
        guard enabled else { return [] }
        guard !manualPowerOff || policy.powerOnAfterManualPowerOff else { return [] }
        return [TVPowerAction(command: command)]
    }
}

public enum TVCommand: Sendable, Equatable {
    case powerOn
    case powerOff
    case screenOff
    case screenOn
    case volumeUp
    case volumeDown
    case setVolume(Int)
    case mute(Bool)
    case setPictureSetting(name: String, value: Int)
    case setLGSystemSetting(category: String, name: String, value: JSONValue)
    case reboot
    case mediaPlay
    case mediaPause
    case mediaStop
    case channelUp
    case channelDown
    case setInput(String)
    case openURL(String)
    case closeApplication(String)
    case setLGOLEDProtection(name: String, enabled: Bool)
    case setLGHDMIIcon(port: Int, icon: String, label: String)
    case remoteKey(String)
    case launchApplication(identifier: String, parameters: JSONValue?)
}

public enum TVProtocolError: Error, LocalizedError, Sendable, Equatable {
    case invalidHost
    case unsupportedCommand(TVCommand)
    case malformedMessage
    case pairingRequired
    case pairingTimedOut
    case powerStateUnavailable
    case untrustedCertificate(fingerprint: String)
    case transportUnavailable
    case remoteFailure(String)

    public var errorDescription: String? {
        switch self {
        case .invalidHost: return "The device host is invalid."
        case let .unsupportedCommand(command): return "The command is not supported by this adapter: \(command)."
        case .malformedMessage: return "The device returned a malformed protocol message."
        case .pairingRequired: return "The device requires pairing before it can be controlled."
        case .pairingTimedOut: return "Pairing timed out. Approve the request on the TV, then try again."
        case .powerStateUnavailable:
            return "The TV power state could not be determined. No power-off command was sent."
        case let .untrustedCertificate(fingerprint):
            return "The TV presented an untrusted certificate with SHA-256 fingerprint \(fingerprint). Verify it, then explicitly trust it to continue."
        case .transportUnavailable: return "The device transport is unavailable."
        case let .remoteFailure(message): return message
        }
    }
}

public enum LGPowerStateParser {
    public static func parse(_ value: JSONValue) -> TVPowerState? {
        guard case let .object(root) = value else { return nil }
        let payload: [String: JSONValue]
        if case let .object(nested)? = root["payload"] {
            payload = nested
        } else {
            payload = root
        }
        guard case let .string(rawState)? = payload["state"] else { return nil }

        switch normalized(rawState) {
        case "active", "on", "power_on": return .on
        case "poweroff", "power_off", "off", "standby", "active_standby", "screenoff", "screen_off", "suspend": return .off
        default: return .unknown
        }
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}

public enum SamsungPowerStateParser {
    public static func parse(_ value: JSONValue) -> TVPowerState? {
        guard case let .object(root) = value,
              case let .object(device)? = root["device"],
              case let .string(rawState)? = device["PowerState"] else {
            return nil
        }

        switch rawState.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "on", "active": return .on
        case "off", "standby", "sleep": return .off
        default: return .unknown
        }
    }
}

public protocol TVTransport: Sendable {
    func connect(to device: TVDeviceDescriptor) async throws
    func send(_ data: Data) async throws -> Data?
    func receive() async throws -> Data?
    func disconnect() async
}

public struct LGWebOSRequest: Codable, Sendable, Equatable {
    public let id: String
    public let type: String
    public let uri: String
    public let payload: JSONValue?

    public init(
        id: String,
        type: String = "request",
        uri: String,
        payload: JSONValue? = nil
    ) {
        self.id = id
        self.type = type
        self.uri = uri
        self.payload = payload
    }
}

public struct LGWebOSRequestFactory: Sendable {
    private var commandCount = 0

    public init() {}

    public mutating func makeRequest(
        prefix: String = "",
        uri: String,
        payload: JSONValue? = nil,
        type: String = "request"
    ) -> LGWebOSRequest {
        commandCount += 1
        let id = prefix.isEmpty ? String(commandCount) : "\(prefix)_\(commandCount)"
        return LGWebOSRequest(id: id, type: type, uri: uri, payload: payload)
    }
}

public struct LGWebOSRegistrationMessage: Codable, Sendable, Equatable {
    public let type: String
    public let id: String
    public let payload: JSONValue

    public init(type: String, id: String, payload: JSONValue) {
        self.type = type
        self.id = id
        self.payload = payload
    }
}

public enum LGWebOSRegistration {
    public static func makeMessage(
        clientKey: String? = nil,
        useLegacyHandshake: Bool = false
    ) -> LGWebOSRegistrationMessage {
        let effectiveClientKey = clientKey ?? ""
        let appID = useLegacyHandshake ? "com.lge.test" : "com.colorcontrol.app"
        let appVersion = useLegacyHandshake ? "1.1" : "1.0"

        let manifest = JSONValue.object([
            "manifestVersion": .number(1),
            "appVersion": .string(appVersion),
            "signed": .object([
                "appId": .string(appID),
                "created": .string(useLegacyHandshake ? "20140509" : "20260426"),
                // Signed pairing manifest: kept from the ColorControl name so existing TV pairings stay valid.
                "localizedAppNames": .object(["": .string("ColorControl")]),
                "localizedVendorNames": .object(["": .string("ColorControl")]),
                "permissions": .array([
                    .string("CONTROL_POWER"),
                    .string("READ_POWER_STATE"),
                    .string("READ_CURRENT_CHANNEL"),
                    .string("READ_RUNNING_APPS"),
                    .string("READ_NETWORK_STATE"),
                    .string("READ_INPUT_DEVICE_LIST"),
                    .string("READ_TV_CHANNEL_LIST"),
                    .string("READ_SETTINGS"),
                    .string("READ_COUNTRY_INFO"),
                    .string("WRITE_NOTIFICATION_TOAST"),
                    .string("CONTROL_AUDIO"),
                    .string("CONTROL_DISPLAY"),
                    .string("CONTROL_INPUT_JOYSTICK"),
                    .string("CONTROL_INPUT_MEDIA_PLAYBACK"),
                    .string("CONTROL_INPUT_TV"),
                    .string("CONTROL_TV_SCREEN"),
                    .string("LAUNCH"),
                    .string("LAUNCH_WEBAPP"),
                    .string("APP_TO_APP"),
                    .string("CLOSE")
                ]),
                "serial": .string(useLegacyHandshake ? "2f930e2d2cfe083771f68e4fe7bb07" : "colorcontrol-webos26")
            ]),
            "permissions": .array([
                .string("LAUNCH"),
                .string("LAUNCH_WEBAPP"),
                .string("APP_TO_APP"),
                .string("CLOSE"),
                .string("CONTROL_AUDIO"),
                .string("CONTROL_DISPLAY"),
                .string("CONTROL_INPUT_JOYSTICK"),
                .string("CONTROL_INPUT_MEDIA_PLAYBACK"),
                .string("CONTROL_INPUT_TV"),
                .string("CONTROL_POWER"),
                .string("CONTROL_TV_SCREEN"),
                .string("READ_CURRENT_CHANNEL"),
                .string("READ_APP_STATUS"),
                .string("READ_INPUT_DEVICE_LIST"),
                .string("READ_NETWORK_STATE"),
                .string("READ_RUNNING_APPS"),
                .string("READ_TV_CHANNEL_LIST"),
                .string("WRITE_NOTIFICATION_TOAST"),
                .string("READ_POWER_STATE"),
                .string("READ_COUNTRY_INFO"),
                .string("READ_SETTINGS")
            ])
        ])

        return LGWebOSRegistrationMessage(
            type: "register",
            id: "register_0",
            payload: .object([
                "forcePairing": .bool(false),
                "pairingType": .string("PROMPT"),
                "client-key": .string(effectiveClientKey),
                "manifest": manifest
            ])
        )
    }

    public static func clientKey(from data: Data) throws -> String? {
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        guard case let .object(root) = decoded,
              case let .string(type)? = root["type"],
              type == "registered",
              case let .object(payload)? = root["payload"],
              case let .string(clientKey)? = payload["client-key"] else {
            return nil
        }
        return clientKey.isEmpty ? nil : clientKey
    }
}

public enum LGWebOSCommand: Sendable, Equatable {
    case powerOff
    case getPowerState
    case screenOff
    case screenOn
    case volumeUp
    case volumeDown
    case setVolume(Int)
    case mute(Bool)
    case pictureSettingAlert(name: String, value: Int)
    case systemSettingAlert(category: String, name: String, value: JSONValue)
    case closeAlert(identifier: String)
    case reboot
    case mediaPlay
    case mediaPause
    case mediaStop
    case channelUp
    case channelDown
    case setInput(String)
    case openURL(String)
    case getSystemSettings(category: String, keys: [String])
    case getVolume
    case listApplications
    case listInputs
    case closeApplication(String)
    case lunaActionAlert(uri: String, payload: JSONValue)
    case launchApplication(identifier: String, parameters: JSONValue?)
    case remote(uri: String, payload: JSONValue?)

    public func makeRequest(using factory: inout LGWebOSRequestFactory) -> LGWebOSRequest {
        switch self {
        case .powerOff:
            return factory.makeRequest(uri: "ssap://system/turnOff")
        case .getPowerState:
            return factory.makeRequest(
                uri: "ssap://com.webos.service.tvpower/power/getPowerState",
                type: "subscribe"
            )
        case .screenOff:
            return factory.makeRequest(uri: "ssap://com.webos.service.tvpower/power/turnOffScreen")
        case .screenOn:
            return factory.makeRequest(uri: "ssap://com.webos.service.tvpower/power/turnOnScreen")
        case .volumeUp:
            return factory.makeRequest(prefix: "volumeup", uri: "ssap://audio/volumeUp")
        case .volumeDown:
            return factory.makeRequest(prefix: "volumedown", uri: "ssap://audio/volumeDown")
        case let .setVolume(value):
            return factory.makeRequest(
                uri: "ssap://audio/setVolume",
                payload: .object(["volume": .number(Double(max(0, min(100, value))))])
            )
        case let .mute(value):
            return factory.makeRequest(
                uri: "ssap://audio/setMute",
                payload: .object(["mute": .bool(value)])
            )
        case let .pictureSettingAlert(name, value):
            return Self.systemSettingAlert(
                category: "picture",
                name: name,
                value: .string(String(max(0, min(100, value))))
            ).makeRequest(using: &factory)
        case let .systemSettingAlert(category, name, value):
            let settings = Self.systemSettingsPayload(category: category, name: name, value: value)
            let action: JSONValue = .object([
                "uri": .string("luna://com.webos.settingsservice/setSystemSettings"),
                "params": settings
            ])
            return factory.makeRequest(
                uri: "ssap://system.notifications/createAlert",
                payload: .object([
                    "message": .string("Applying picture setting…"),
                    "buttons": .array([.object([
                        "label": .string(""),
                        "onClick": .string("luna://com.webos.settingsservice/setSystemSettings"),
                        "params": settings
                    ])]),
                    "onclose": action,
                    "onfail": action
                ])
            )
        case .reboot:
            return factory.makeRequest(uri: "ssap://com.webos.service.tvpower/power/reboot")
        case .mediaPlay:
            return factory.makeRequest(uri: "ssap://media.controls/play")
        case .mediaPause:
            return factory.makeRequest(uri: "ssap://media.controls/pause")
        case .mediaStop:
            return factory.makeRequest(uri: "ssap://media.controls/stop")
        case .channelUp:
            return factory.makeRequest(uri: "ssap://tv/channelUp")
        case .channelDown:
            return factory.makeRequest(uri: "ssap://tv/channelDown")
        case let .setInput(identifier):
            return factory.makeRequest(
                uri: "ssap://tv/switchInput",
                payload: .object(["inputId": .string(identifier)])
            )
        case let .openURL(url):
            return factory.makeRequest(
                uri: "ssap://system.launcher/open",
                payload: .object(["target": .string(url)])
            )
        case let .getSystemSettings(category, keys):
            return factory.makeRequest(
                uri: "ssap://settings/getSystemSettings",
                payload: .object([
                    "category": .string(category),
                    "keys": .array(keys.map(JSONValue.string))
                ])
            )
        case .getVolume:
            return factory.makeRequest(uri: "ssap://audio/getVolume")
        case .listApplications:
            return factory.makeRequest(
                uri: "ssap://com.webos.applicationManager/listApps",
                payload: .object([:])
            )
        case .listInputs:
            return factory.makeRequest(uri: "ssap://tv/getExternalInputList")
        case let .closeApplication(identifier):
            return factory.makeRequest(
                uri: "ssap://system.launcher/close",
                payload: .object(["id": .string(identifier)])
            )
        case let .lunaActionAlert(uri, parameters):
            let action: JSONValue = .object(["uri": .string(uri), "params": parameters])
            return factory.makeRequest(
                uri: "ssap://system.notifications/createAlert",
                payload: .object([
                    "message": .string("Applying advanced setting…"),
                    "buttons": .array([.object([
                        "label": .string(""),
                        "onClick": .string(uri),
                        "params": parameters
                    ])]),
                    "onclose": action,
                    "onfail": action
                ])
            )
        case let .closeAlert(identifier):
            return factory.makeRequest(
                uri: "ssap://system.notifications/closeAlert",
                payload: .object(["alertId": .string(identifier)])
            )
        case let .launchApplication(identifier, parameters):
            var payload: [String: JSONValue] = ["id": .string(identifier)]
            if let parameters {
                payload["params"] = parameters
            }
            return factory.makeRequest(
                uri: "ssap://system.launcher/launch",
                payload: .object(payload)
            )
        case let .remote(uri, payload):
            return factory.makeRequest(uri: uri, payload: payload)
        }
    }

    /// Reproduces the legacy `ParamToJson` setting semantics without accepting
    /// arbitrary Luna URIs from the presentation layer.
    public static func systemSettingsPayload(
        category: String,
        name: String,
        value: JSONValue
    ) -> JSONValue {
        var settingName = name
        var settingValue = value

        if name == "blackLevel", case let .string(level) = value {
            settingValue = .object(Dictionary(uniqueKeysWithValues: [
                "ntsc", "ntsc443", "pal", "pal60", "palm", "paln", "secam", "unknown"
            ].map { ($0, .string(level)) }))
        } else if let separator = name.firstIndex(of: "_") {
            settingName = String(name[..<separator])
            let child = String(name[name.index(after: separator)...])
            settingValue = .object([child: normalizedSettingValue(value)])
        } else {
            settingValue = normalizedSettingValue(value)
        }

        var payload: [String: JSONValue] = [
            "category": .string(category),
            "settings": .object([settingName: settingValue])
        ]
        if name == "truMotionMode" {
            payload["current_app"] = .bool(true)
        }
        return .object(payload)
    }

    private static func normalizedSettingValue(_ value: JSONValue) -> JSONValue {
        guard case let .string(raw) = value else { return value }
        if raw == "true" { return .bool(true) }
        if raw == "false" { return .bool(false) }
        if raw.hasPrefix("bool_") { return .bool(raw == "bool_true") }
        if raw.hasPrefix("_") { return .string(String(raw.dropFirst())) }
        return value
    }
}

/// Normalizes the volume field returned by different webOS firmware versions.
/// Most TVs return a JSON number, while some bridges/firmware revisions expose
/// a numeric string or wrap the value in a small object.
public enum LGVolumeValueParser {
    public static func parse(_ value: JSONValue?) -> Int? {
        guard let value else { return nil }

        let parsed: Int?
        switch value {
        case let .number(number):
            parsed = boundedInteger(number)
        case let .string(string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let integer = Int(trimmed) {
                parsed = integer
            } else if let number = Double(trimmed) {
                parsed = boundedInteger(number)
            } else {
                parsed = nil
            }
        case let .object(object):
            // Recent webOS versions wrap the scalar in `volumeStatus`, e.g.
            // `{ "payload": { "volumeStatus": { "volume": 15 } } }`.
            // Keep the direct keys first, then follow the known response
            // wrappers used by different firmware/bridge implementations.
            parsed = [
                "volume", "currentVolume", "masterVolume", "value", "level",
                "volumeStatus", "status", "result", "data", "payload"
            ]
                .lazy
                .compactMap { object[$0] }
                .compactMap(parse)
                .first
        case let .array(values):
            parsed = values.first.flatMap(parse)
        default:
            parsed = nil
        }

        guard let parsed else { return nil }
        return min(max(parsed, 0), 100)
    }

    private static func boundedInteger(_ number: Double) -> Int? {
        guard number.isFinite else { return nil }
        let rounded = number.rounded()
        guard rounded >= Double(Int.min), rounded <= Double(Int.max) else { return nil }
        return Int(rounded)
    }
}

public struct SamsungRequest: Codable, Sendable, Equatable {
    public let method: String
    public let params: JSONValue

    public init(method: String, params: JSONValue) {
        self.method = method
        self.params = params
    }
}

public struct SamsungConnectionEvent: Sendable, Equatable {
    public let token: String?
    public let unauthorized: Bool

    public init(token: String?, unauthorized: Bool) {
        self.token = token
        self.unauthorized = unauthorized
    }
}

public enum SamsungMessageParser {
    public static func connectionEvent(from data: Data) throws -> SamsungConnectionEvent? {
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        guard case let .object(root) = decoded,
              case let .string(event)? = root["event"] else {
            return nil
        }

        if event == "ms.channel.unauthorized" {
            return SamsungConnectionEvent(token: nil, unauthorized: true)
        }
        guard event == "ms.channel.connect" else { return nil }

        guard case let .object(dataObject)? = root["data"] else {
            return SamsungConnectionEvent(token: nil, unauthorized: false)
        }
        if case let .string(token)? = dataObject["token"], !token.isEmpty {
            return SamsungConnectionEvent(token: token, unauthorized: false)
        }
        if case let .array(clients)? = dataObject["clients"] {
            for client in clients {
                guard case let .object(clientObject) = client,
                      case let .object(attributes)? = clientObject["attributes"],
                      case let .string(token)? = attributes["token"], !token.isEmpty else {
                    continue
                }
                return SamsungConnectionEvent(token: token, unauthorized: false)
            }
        }
        return SamsungConnectionEvent(token: nil, unauthorized: false)
    }
}

public struct SamsungRemoteCommand: Sendable, Equatable {
    public let key: String
    public let option: String

    public init(key: String, option: String = "false") {
        self.key = key
        self.option = option
    }

    public func request() -> SamsungRequest {
        SamsungRequest(
            method: "ms.remote.control",
            params: .object([
                "Cmd": .string("Click"),
                "DataOfCmd": .string(key),
                "Option": .string(option),
                "TypeOfRemote": .string("SendRemoteKey")
            ])
        )
    }
}

public struct SamsungWebSocketEndpoint: Sendable, Equatable {
    public let host: String
    public let secure: Bool
    public let token: String?
    public let clientName: String

    public init(
        host: String,
        secure: Bool,
        token: String? = nil,
        clientName: String = "ColorControl" // Samsung pairs tokens by name; kept from the old app name.
    ) {
        self.host = host
        self.secure = secure
        self.token = token
        self.clientName = clientName
    }

    public var url: URL? {
        guard !host.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = secure ? "wss" : "ws"
        components.host = host
        components.port = secure ? 8002 : 8001
        components.path = "/api/v2/channels/samsung.remote.control"

        let name = Data(clientName.utf8).base64EncodedString()
        var queryItems = [URLQueryItem(name: "name", value: name)]
        if let token {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        components.queryItems = queryItems
        return components.url
    }
}

public struct SamsungPowerStateEndpoint: Sendable, Equatable {
    public let host: String

    public init(host: String) {
        self.host = host
    }

    public var url: URL? {
        guard !host.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = 8001
        components.path = "/api/v2/"
        return components.url
    }
}
