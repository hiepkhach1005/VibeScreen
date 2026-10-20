import Foundation

public enum PlatformSignalKind: String, Sendable, Equatable {
    case startup
    case willSleep
    case didWake
    case screensDidSleep
    case screensDidWake
    case willPowerOff
    case sessionDidResignActive
    case sessionDidBecomeActive
    case applicationActivityChanged
    case displayConfigurationChanged
}

public struct PlatformSignal: Sendable, Equatable {
    public let kind: PlatformSignalKind
    public let context: AutomationEventContext

    public init(kind: PlatformSignalKind, context: AutomationEventContext = AutomationEventContext()) {
        self.kind = kind
        self.context = context
    }

    /// Converts the macOS lifecycle signals that have a legacy preset-trigger
    /// equivalent. Screen sleep/wake is the public macOS approximation for the
    /// legacy screensaver start/stop event and remains separately available to
    /// the TV power-policy layer.
    public var automationEvent: AutomationEvent? {
        switch kind {
        case .startup:
            return AutomationEvent(kind: .startup)
        case .willSleep:
            return AutomationEvent(kind: .standby)
        case .didWake:
            return AutomationEvent(kind: .resume)
        case .willPowerOff:
            return AutomationEvent(kind: .shutdown)
        case .applicationActivityChanged:
            return AutomationEvent(kind: .processSwitch)
        case .displayConfigurationChanged:
            return AutomationEvent(kind: .displayChange)
        case .screensDidSleep:
            return AutomationEvent(kind: .screensaverStart)
        case .screensDidWake:
            return AutomationEvent(kind: .screensaverStop)
        case .sessionDidResignActive, .sessionDidBecomeActive:
            return nil
        }
    }
}
