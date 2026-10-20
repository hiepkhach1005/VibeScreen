import Foundation

public struct GlobalKeyboardShortcut: Codable, Sendable, Equatable {
    public var keyCode: UInt16
    public var key: String
    public var usesCommand: Bool
    public var usesOption: Bool
    public var usesControl: Bool
    public var usesShift: Bool

    public init(
        keyCode: UInt16,
        key: String,
        usesCommand: Bool,
        usesOption: Bool,
        usesControl: Bool,
        usesShift: Bool
    ) {
        self.keyCode = keyCode
        self.key = key
        self.usesCommand = usesCommand
        self.usesOption = usesOption
        self.usesControl = usesControl
        self.usesShift = usesShift
    }

    public var displayText: String {
        var result = ""
        if usesControl { result += "⌃" }
        if usesOption { result += "⌥" }
        if usesShift { result += "⇧" }
        if usesCommand { result += "⌘" }
        return result + key
    }

    public var hasRegistrationModifier: Bool {
        usesCommand || usesOption || usesControl
    }

    /// Control-O is the single first-TV power toggle shortcut.
    public static let defaultTVPowerToggle = GlobalKeyboardShortcut(
        keyCode: 31,
        key: "O",
        usesCommand: false,
        usesOption: false,
        usesControl: true,
        usesShift: false
    )

    public static let legacyDefaultTVPowerOn = GlobalKeyboardShortcut(
        keyCode: 126,
        key: "↑",
        usesCommand: true,
        usesOption: true,
        usesControl: true,
        usesShift: false
    )

    public static let legacyDefaultTVPowerOff = GlobalKeyboardShortcut(
        keyCode: 125,
        key: "↓",
        usesCommand: true,
        usesOption: true,
        usesControl: true,
        usesShift: false
    )
}

public struct NativeAppSettings: Codable, Sendable, Equatable {
    public static let minimumLGLiveSyncIntervalSeconds = 1
    public static let maximumLGLiveSyncIntervalSeconds = 3_600
    public static let minimumSystemMonitorIntervalMilliseconds = 500
    public static let maximumSystemMonitorIntervalMilliseconds = 60_000

    public var launchAtLogin: Bool
    public var startHidden: Bool
    public var minimizeToMenuBar: Bool
    public var checkForUpdates: Bool
    public var logLevel: String
    public var processMonitorIntervalMilliseconds: Int
    public var systemMonitorIntervalMilliseconds: Int
    public var showSystemMonitorInSidebar: Bool
    public var showOverviewInSidebar: Bool
    public var lgLiveSyncEnabled: Bool
    public var lgLiveSyncIntervalSeconds: Int
    public var tvPowerToggleShortcut: GlobalKeyboardShortcut

    public init(
        launchAtLogin: Bool = false,
        startHidden: Bool = false,
        minimizeToMenuBar: Bool = true,
        checkForUpdates: Bool = true,
        logLevel: String = "info",
        processMonitorIntervalMilliseconds: Int = 1_000,
        systemMonitorIntervalMilliseconds: Int = 1_000,
        showSystemMonitorInSidebar: Bool = true,
        showOverviewInSidebar: Bool = false,
        lgLiveSyncEnabled: Bool = true,
        lgLiveSyncIntervalSeconds: Int = 5,
        tvPowerToggleShortcut: GlobalKeyboardShortcut = .defaultTVPowerToggle
    ) {
        self.launchAtLogin = launchAtLogin
        self.startHidden = startHidden
        self.minimizeToMenuBar = minimizeToMenuBar
        self.checkForUpdates = checkForUpdates
        self.logLevel = logLevel
        self.processMonitorIntervalMilliseconds = max(100, processMonitorIntervalMilliseconds)
        self.systemMonitorIntervalMilliseconds = Self.clampedSystemMonitorInterval(
            systemMonitorIntervalMilliseconds
        )
        self.showSystemMonitorInSidebar = showSystemMonitorInSidebar
        self.showOverviewInSidebar = showOverviewInSidebar
        self.lgLiveSyncEnabled = lgLiveSyncEnabled
        self.lgLiveSyncIntervalSeconds = Self.clampedLGLiveSyncInterval(lgLiveSyncIntervalSeconds)
        self.tvPowerToggleShortcut = tvPowerToggleShortcut
    }

    private enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case startHidden
        case minimizeToMenuBar
        case checkForUpdates
        case logLevel
        case processMonitorIntervalMilliseconds
        case systemMonitorIntervalMilliseconds
        case showSystemMonitorInSidebar
        case showOverviewInSidebar
        case lgLiveSyncEnabled
        case lgLiveSyncIntervalSeconds
        case tvPowerToggleShortcut
        // Kept only for decoding snapshots written by the previous two-binding UI.
        case tvPowerOnShortcut
        case tvPowerOffShortcut
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            launchAtLogin: try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false,
            startHidden: try container.decodeIfPresent(Bool.self, forKey: .startHidden) ?? false,
            minimizeToMenuBar: try container.decodeIfPresent(Bool.self, forKey: .minimizeToMenuBar) ?? true,
            checkForUpdates: try container.decodeIfPresent(Bool.self, forKey: .checkForUpdates) ?? true,
            logLevel: try container.decodeIfPresent(String.self, forKey: .logLevel) ?? "info",
            processMonitorIntervalMilliseconds: try container.decodeIfPresent(
                Int.self,
                forKey: .processMonitorIntervalMilliseconds
            ) ?? 1_000,
            systemMonitorIntervalMilliseconds: try container.decodeIfPresent(
                Int.self,
                forKey: .systemMonitorIntervalMilliseconds
            ) ?? 1_000,
            showSystemMonitorInSidebar: try container.decodeIfPresent(
                Bool.self,
                forKey: .showSystemMonitorInSidebar
            ) ?? true,
            showOverviewInSidebar: try container.decodeIfPresent(
                Bool.self,
                forKey: .showOverviewInSidebar
            ) ?? false,
            lgLiveSyncEnabled: try container.decodeIfPresent(Bool.self, forKey: .lgLiveSyncEnabled) ?? true,
            lgLiveSyncIntervalSeconds: try container.decodeIfPresent(
                Int.self,
                forKey: .lgLiveSyncIntervalSeconds
            ) ?? 5,
            tvPowerToggleShortcut: Self.migratedTVPowerToggleShortcut(from: container)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(startHidden, forKey: .startHidden)
        try container.encode(minimizeToMenuBar, forKey: .minimizeToMenuBar)
        try container.encode(checkForUpdates, forKey: .checkForUpdates)
        try container.encode(logLevel, forKey: .logLevel)
        try container.encode(processMonitorIntervalMilliseconds, forKey: .processMonitorIntervalMilliseconds)
        try container.encode(systemMonitorIntervalMilliseconds, forKey: .systemMonitorIntervalMilliseconds)
        try container.encode(showSystemMonitorInSidebar, forKey: .showSystemMonitorInSidebar)
        try container.encode(showOverviewInSidebar, forKey: .showOverviewInSidebar)
        try container.encode(lgLiveSyncEnabled, forKey: .lgLiveSyncEnabled)
        try container.encode(lgLiveSyncIntervalSeconds, forKey: .lgLiveSyncIntervalSeconds)
        try container.encode(tvPowerToggleShortcut, forKey: .tvPowerToggleShortcut)
    }

    private static func migratedTVPowerToggleShortcut(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> GlobalKeyboardShortcut {
        if let current = try? container.decode(
            GlobalKeyboardShortcut.self,
            forKey: .tvPowerToggleShortcut
        ) {
            return current
        }

        let oldPowerOn = try? container.decode(
            GlobalKeyboardShortcut.self,
            forKey: .tvPowerOnShortcut
        )
        let oldPowerOff = try? container.decode(
            GlobalKeyboardShortcut.self,
            forKey: .tvPowerOffShortcut
        )

        // A snapshot containing the old defaults should adopt the new friendly
        // default. For a customized pair, keep the old power-on binding as the
        // least surprising single toggle until the user changes it.
        if oldPowerOn == .some(.legacyDefaultTVPowerOn)
            && oldPowerOff == .some(.legacyDefaultTVPowerOff) {
            return .defaultTVPowerToggle
        }
        return oldPowerOn ?? .defaultTVPowerToggle
    }

    public static func clampedLGLiveSyncInterval(_ seconds: Int) -> Int {
        min(
            maximumLGLiveSyncIntervalSeconds,
            max(minimumLGLiveSyncIntervalSeconds, seconds)
        )
    }

    public static func clampedSystemMonitorInterval(_ milliseconds: Int) -> Int {
        min(
            maximumSystemMonitorIntervalMilliseconds,
            max(minimumSystemMonitorIntervalMilliseconds, milliseconds)
        )
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
        case let .unsupportedSchema(version): return "Unsupported VibeScreen data schema: \(version)."
        case .directoryCreationFailed: return "The VibeScreen Application Support directory could not be created."
        case .backupFailed: return "The previous VibeScreen data could not be backed up."
        }
    }
}

/// Versioned, atomic native persistence. Import code never writes directly to
/// a legacy file; it produces a snapshot which is then saved here.
public actor NativeStore {
    public let directoryURL: URL
    public let snapshotURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
        self.snapshotURL = directoryURL.appendingPathComponent("VibeScreen.json")
    }

    public static func makeDefault() -> NativeStore? {
        guard let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        let directoryURL = applicationSupport.appendingPathComponent("VibeScreen", isDirectory: true)
        for legacyName in ["VibeMonitor", "ColorControl"] {
            migrateLegacyDirectory(
                named: legacyName,
                from: applicationSupport.appendingPathComponent(legacyName, isDirectory: true),
                to: directoryURL
            )
        }
        return NativeStore(directoryURL: directoryURL)
    }

    /// One-time move of data written before the app was renamed (ColorControl, then VibeMonitor).
    /// Diagnostics and development credentials live in the same directory and move with it.
    static func migrateLegacyDirectory(named legacyName: String, from legacyURL: URL, to directoryURL: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: legacyURL.path),
              !fileManager.fileExists(atPath: directoryURL.path),
              (try? fileManager.moveItem(at: legacyURL, to: directoryURL)) != nil else {
            return
        }
        for suffix in ["", ".bak"] {
            let legacySnapshot = directoryURL.appendingPathComponent(legacyName + ".json" + suffix)
            let snapshot = directoryURL.appendingPathComponent("VibeScreen.json" + suffix)
            if fileManager.fileExists(atPath: legacySnapshot.path) {
                try? fileManager.moveItem(at: legacySnapshot, to: snapshot)
            }
        }
    }

    public func load() throws -> NativeStoreSnapshot? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: snapshotURL.path) else { return nil }
        try hardenPermissions(at: directoryURL, permissions: 0o700)
        try hardenPermissions(at: snapshotURL, permissions: 0o600)
        let backupURL = directoryURL.appendingPathComponent("VibeScreen.json.bak")
        if fileManager.fileExists(atPath: backupURL.path) {
            try hardenPermissions(at: backupURL, permissions: 0o600)
        }
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
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            try hardenPermissions(at: directoryURL, permissions: 0o700)
        } catch {
            throw NativeStoreError.directoryCreationFailed
        }

        if fileManager.fileExists(atPath: snapshotURL.path) {
            let backupURL = directoryURL.appendingPathComponent("VibeScreen.json.bak")
            do {
                if fileManager.fileExists(atPath: backupURL.path) {
                    try fileManager.removeItem(at: backupURL)
                }
                try fileManager.copyItem(at: snapshotURL, to: backupURL)
                try hardenPermissions(at: backupURL, permissions: 0o600)
            } catch {
                throw NativeStoreError.backupFailed
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
        try hardenPermissions(at: snapshotURL, permissions: 0o600)
    }

    private func hardenPermissions(at url: URL, permissions: Int) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: permissions],
            ofItemAtPath: url.path
        )
    }
}
