import Foundation

public struct NativeAppSettings: Codable, Sendable, Equatable {
    public var launchAtLogin: Bool
    public var startHidden: Bool
    public var minimizeToMenuBar: Bool
    public var checkForUpdates: Bool
    public var logLevel: String
    public var processMonitorIntervalMilliseconds: Int

    public init(
        launchAtLogin: Bool = false,
        startHidden: Bool = false,
        minimizeToMenuBar: Bool = true,
        checkForUpdates: Bool = true,
        logLevel: String = "info",
        processMonitorIntervalMilliseconds: Int = 1_000
    ) {
        self.launchAtLogin = launchAtLogin
        self.startHidden = startHidden
        self.minimizeToMenuBar = minimizeToMenuBar
        self.checkForUpdates = checkForUpdates
        self.logLevel = logLevel
        self.processMonitorIntervalMilliseconds = max(100, processMonitorIntervalMilliseconds)
    }
}

public struct TVRemoteButtonDefinition: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var command: String
    public var top: Double
    public var left: Double
    public var legacyPayload: JSONValue?

    public init(
        id: UUID = UUID(),
        name: String,
        command: String,
        top: Double = 0,
        left: Double = 0,
        legacyPayload: JSONValue? = nil
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.top = top
        self.left = left
        self.legacyPayload = legacyPayload
    }
}

public struct TVRemoteDefinition: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var kind: TVDeviceKind
    public var name: String
    public var imageFileName: String?
    public var buttons: [TVRemoteButtonDefinition]

    public init(
        id: UUID = UUID(),
        kind: TVDeviceKind,
        name: String,
        imageFileName: String? = nil,
        buttons: [TVRemoteButtonDefinition] = []
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.imageFileName = imageFileName
        self.buttons = buttons
    }
}

public struct NativeStoreSnapshot: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 2

    public let schemaVersion: Int
    public var presets: [Preset]
    public var devices: [TVDeviceDescriptor]
    public var gamePresets: [GamePreset]
    public var remotes: [TVRemoteDefinition]
    public var settings: NativeAppSettings

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case presets
        case devices
        case gamePresets
        case remotes
        case settings
    }

    public init(
        schemaVersion: Int = NativeStoreSnapshot.currentSchemaVersion,
        presets: [Preset] = [],
        devices: [TVDeviceDescriptor] = [],
        gamePresets: [GamePreset] = [],
        remotes: [TVRemoteDefinition] = [],
        settings: NativeAppSettings = NativeAppSettings()
    ) {
        self.schemaVersion = schemaVersion
        self.presets = presets
        self.devices = devices
        self.gamePresets = gamePresets
        self.remotes = remotes
        self.settings = settings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        presets = try container.decodeIfPresent([Preset].self, forKey: .presets) ?? []
        devices = try container.decodeIfPresent([TVDeviceDescriptor].self, forKey: .devices) ?? []
        gamePresets = try container.decodeIfPresent([GamePreset].self, forKey: .gamePresets) ?? []
        remotes = try container.decodeIfPresent([TVRemoteDefinition].self, forKey: .remotes) ?? []
        settings = try container.decodeIfPresent(NativeAppSettings.self, forKey: .settings) ?? NativeAppSettings()
    }
}

public enum NativeStoreError: Error, LocalizedError, Sendable, Equatable {
    case unsupportedSchema(Int)
    case directoryCreationFailed
    case backupFailed

    public var errorDescription: String? {
        switch self {
        case let .unsupportedSchema(version): return "Unsupported ColorControl data schema: \(version)."
        case .directoryCreationFailed: return "The ColorControl Application Support directory could not be created."
        case .backupFailed: return "The previous ColorControl data could not be backed up."
        }
    }
}

/// Versioned, atomic native persistence. Import code never writes directly to
/// a legacy file; it produces a snapshot which is then saved here.
public actor NativeStore {
    public let directoryURL: URL
    public let snapshotURL: URL

    private let fileManager: FileManagerBox

    public init(
        directoryURL: URL,
        fileManager: FileManager = .default
    ) {
        self.directoryURL = directoryURL
        self.snapshotURL = directoryURL.appendingPathComponent("ColorControl.json")
        self.fileManager = FileManagerBox(fileManager)
    }

    public static func makeDefault(fileManager: FileManager = .default) -> NativeStore? {
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        return NativeStore(
            directoryURL: applicationSupport.appendingPathComponent("ColorControl", isDirectory: true),
            fileManager: fileManager
        )
    }

    public func load() throws -> NativeStoreSnapshot? {
        guard fileManager.value.fileExists(atPath: snapshotURL.path) else { return nil }
        let data = try Data(contentsOf: snapshotURL)
        let snapshot = try JSONDecoder().decode(NativeStoreSnapshot.self, from: data)
        guard snapshot.schemaVersion <= NativeStoreSnapshot.currentSchemaVersion else {
            throw NativeStoreError.unsupportedSchema(snapshot.schemaVersion)
        }
        guard snapshot.schemaVersion < NativeStoreSnapshot.currentSchemaVersion else {
            return snapshot
        }

        return NativeStoreSnapshot(
            presets: snapshot.presets,
            devices: snapshot.devices,
            gamePresets: snapshot.gamePresets,
            remotes: snapshot.remotes,
            settings: snapshot.settings
        )
    }

    public func save(_ snapshot: NativeStoreSnapshot) throws {
        do {
            try fileManager.value.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw NativeStoreError.directoryCreationFailed
        }

        if fileManager.value.fileExists(atPath: snapshotURL.path) {
            let backupURL = directoryURL.appendingPathComponent("ColorControl.json.bak")
            do {
                if fileManager.value.fileExists(atPath: backupURL.path) {
                    try fileManager.value.removeItem(at: backupURL)
                }
                try fileManager.value.copyItem(at: snapshotURL, to: backupURL)
            } catch {
                throw NativeStoreError.backupFailed
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
    }
}

private final class FileManagerBox: @unchecked Sendable {
    let value: FileManager

    init(_ value: FileManager) {
        self.value = value
    }
}
