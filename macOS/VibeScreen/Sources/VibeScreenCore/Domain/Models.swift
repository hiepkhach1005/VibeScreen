import Foundation

/// Events that can cause a preset to run. GPU-only triggers from the Windows
/// application are deliberately absent from the native contract.
public enum PresetTriggerKind: String, Codable, CaseIterable, Sendable, Equatable {
    case startup
    case resume
    case shutdown
    case standby
    case processSwitch
    case screensaverStart
    case screensaverStop
    case displayChange
}

/// A typed boundary around legacy preset actions. Unknown legacy actions are
/// retained instead of being silently discarded during migration.
public enum PresetStepAction: Codable, Sendable, Equatable {
    case deviceCommand(target: String, command: String)
    case launchApplication(bundleIdentifier: String)
    case setDisplayProfile(identifier: String)
    case wait
    case legacy(name: String, value: String?)

    private enum CodingKeys: String, CodingKey {
        case kind
        case target
        case command
        case bundleIdentifier
        case identifier
        case name
        case value
    }

    private enum Kind: String, Codable {
        case deviceCommand
        case launchApplication
        case setDisplayProfile
        case wait
        case legacy
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .deviceCommand(target, command):
            try container.encode(Kind.deviceCommand, forKey: .kind)
            try container.encode(target, forKey: .target)
            try container.encode(command, forKey: .command)
        case let .launchApplication(bundleIdentifier):
            try container.encode(Kind.launchApplication, forKey: .kind)
            try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        case let .setDisplayProfile(identifier):
            try container.encode(Kind.setDisplayProfile, forKey: .kind)
            try container.encode(identifier, forKey: .identifier)
        case .wait:
            try container.encode(Kind.wait, forKey: .kind)
        case let .legacy(name, value):
            try container.encode(Kind.legacy, forKey: .kind)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(value, forKey: .value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .deviceCommand:
            self = .deviceCommand(
                target: try container.decode(String.self, forKey: .target),
                command: try container.decode(String.self, forKey: .command)
            )
        case .launchApplication:
            self = .launchApplication(
                bundleIdentifier: try container.decode(String.self, forKey: .bundleIdentifier)
            )
        case .setDisplayProfile:
            self = .setDisplayProfile(
                identifier: try container.decode(String.self, forKey: .identifier)
            )
        case .wait:
            self = .wait
        case .legacy:
            self = .legacy(
                name: try container.decode(String.self, forKey: .name),
                value: try container.decodeIfPresent(String.self, forKey: .value)
            )
        }
    }
}

public struct PresetStep: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let rawValue: String
    public let step: String
    public let actionName: String?
    public let actionValue: String?
    public let parameters: [String]?
    public let delayMilliseconds: Int
    public let option: String
    public let action: PresetStepAction

    public init(
        id: UUID = UUID(),
        rawValue: String,
        step: String,
        actionName: String?,
        actionValue: String?,
        parameters: [String]?,
        delayMilliseconds: Int,
        option: String,
        action: PresetStepAction
    ) {
        self.id = id
        self.rawValue = rawValue
        self.step = step
        self.actionName = actionName
        self.actionValue = actionValue
        self.parameters = parameters
        self.delayMilliseconds = delayMilliseconds
        self.option = option
        self.action = action
    }

    /// The normalized legacy syntax used when exporting a migrated preset.
    public var updatedRawValue: String {
        let base: String
        if let actionName, let actionValue {
            base = "\(actionName)(\(actionValue))"
        } else {
            base = step
        }

        guard delayMilliseconds > 0 else { return base }
        guard !option.isEmpty else { return "\(base):\(delayMilliseconds)" }
        return "\(base):\(delayMilliseconds):\(option)"
    }
}

public struct PresetTrigger: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let kind: PresetTriggerKind
    public let includedProcesses: [String]
    public let excludedProcesses: [String]
    public let connectedDisplayPattern: String?
    public let requiresHDR: Bool?
    public let requiresFullscreen: Bool?
    public let requiresNotificationsDisabled: Bool?

    public init(
        id: UUID = UUID(),
        kind: PresetTriggerKind,
        includedProcesses: [String] = [],
        excludedProcesses: [String] = [],
        connectedDisplayPattern: String? = nil,
        requiresHDR: Bool? = nil,
        requiresFullscreen: Bool? = nil,
        requiresNotificationsDisabled: Bool? = nil
    ) {
        self.id = id
        self.kind = kind
        self.includedProcesses = includedProcesses
        self.excludedProcesses = excludedProcesses
        self.connectedDisplayPattern = connectedDisplayPattern
        self.requiresHDR = requiresHDR
        self.requiresFullscreen = requiresFullscreen
        self.requiresNotificationsDisabled = requiresNotificationsDisabled
    }

    public func matches(event: AutomationEvent, context: AutomationEventContext) -> Bool {
        guard event.kind == kind else { return false }

        if !includedProcesses.isEmpty {
            let included = includedProcesses.contains { pattern in
                context.processes.contains { process in
                    process.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
                }
            }
            guard included else { return false }
        }

        let excluded = excludedProcesses.contains { pattern in
            context.processes.contains { process in
                process.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
            }
        }
        guard !excluded else { return false }

        if let connectedDisplayPattern {
            let displayMatches = context.connectedDisplays.contains { display in
                display.range(of: connectedDisplayPattern, options: [.regularExpression, .caseInsensitive]) != nil
            }
            guard displayMatches else { return false }
        }

        if let requiresHDR, context.isHDR != requiresHDR { return false }
        if let requiresFullscreen, context.isFullscreen != requiresFullscreen { return false }
        if let requiresNotificationsDisabled,
           context.notificationsDisabled != requiresNotificationsDisabled {
            return false
        }

        return true
    }
}

public struct Preset: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var shortcut: String
    public var triggers: [PresetTrigger]
    public var steps: [PresetStep]
    public var description: String
    public var showInQuickAccess: Bool
    public var lastUsed: Date?
    public var targetDeviceAddress: String?
    public var applicationIdentifier: String?
    public var legacyNumericIdentifier: Int?

    public init(
        id: UUID = UUID(),
        name: String,
        shortcut: String = "",
        triggers: [PresetTrigger] = [],
        steps: [PresetStep] = [],
        description: String = "",
        showInQuickAccess: Bool = true,
        lastUsed: Date? = nil,
        targetDeviceAddress: String? = nil,
        applicationIdentifier: String? = nil,
        legacyNumericIdentifier: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.shortcut = shortcut
        self.triggers = triggers
        self.steps = steps
        self.description = description
        self.showInQuickAccess = showInQuickAccess
        self.lastUsed = lastUsed
        self.targetDeviceAddress = targetDeviceAddress
        self.applicationIdentifier = applicationIdentifier
        self.legacyNumericIdentifier = legacyNumericIdentifier
    }
}

public struct AutomationEvent: Sendable, Equatable {
    public let kind: PresetTriggerKind

    public init(kind: PresetTriggerKind) {
        self.kind = kind
    }
}

public struct AutomationEventContext: Sendable, Equatable {
    public var processes: Set<String>
    public var foregroundProcess: String?
    public var connectedDisplays: [String]
    public var isHDR: Bool?
    public var isFullscreen: Bool?
    public var notificationsDisabled: Bool?

    public init(
        processes: Set<String> = [],
        foregroundProcess: String? = nil,
        connectedDisplays: [String] = [],
        isHDR: Bool? = nil,
        isFullscreen: Bool? = nil,
        notificationsDisabled: Bool? = nil
    ) {
        self.processes = processes
        self.foregroundProcess = foregroundProcess
        self.connectedDisplays = connectedDisplays
        self.isHDR = isHDR
        self.isFullscreen = isFullscreen
        self.notificationsDisabled = notificationsDisabled
    }
}

public struct PresetExecutionPolicy: Sendable, Equatable {
    public var continueAfterFailure: Bool
    public var retryCount: Int

    public init(continueAfterFailure: Bool = false, retryCount: Int = 0) {
        self.continueAfterFailure = continueAfterFailure
        self.retryCount = max(0, retryCount)
    }
}

public enum PresetExecutionStatus: String, Codable, Sendable, Equatable {
    case succeeded
    case failed
    case cancelled
}

public struct PresetStepFailure: Codable, Sendable, Equatable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

public struct PresetStepResult: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let action: PresetStepAction
    public let succeeded: Bool
    public let failure: PresetStepFailure?

    public init(
        id: UUID,
        action: PresetStepAction,
        succeeded: Bool,
        failure: PresetStepFailure? = nil
    ) {
        self.id = id
        self.action = action
        self.succeeded = succeeded
        self.failure = failure
    }
}

public struct PresetExecutionResult: Codable, Sendable, Equatable {
    public let presetID: UUID
    public let status: PresetExecutionStatus
    public let steps: [PresetStepResult]

    public init(
        presetID: UUID,
        status: PresetExecutionStatus,
        steps: [PresetStepResult]
    ) {
        self.presetID = presetID
        self.status = status
        self.steps = steps
    }
}

public enum VibeScreenCoreError: Error, LocalizedError, Sendable, Equatable {
    case emptyPreset
    case invalidDelay
    case actionRejected(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .emptyPreset:
            return "The preset does not contain any steps."
        case .invalidDelay:
            return "The preset contains an invalid delay."
        case let .actionRejected(message):
            return message
        case .cancelled:
            return "Preset execution was cancelled."
        }
    }
}
