import AppKit
import Carbon
import ColorControlCore
import Foundation

enum TVPowerShortcut: UInt32, CaseIterable {
    case toggle = 1
}

enum GlobalTVShortcutError: Error, LocalizedError {
    case eventHandler(OSStatus)
    case missingModifier
    case registration(GlobalKeyboardShortcut, OSStatus)

    var errorDescription: String? {
        switch self {
        case let .eventHandler(status):
            return "Could not start the TV shortcut handler (macOS error \(status))."
        case .missingModifier:
            return "The TV power toggle shortcut must include Command, Option, or Control."
        case let .registration(shortcut, status) where status == eventHotKeyExistsErr:
            return "\(shortcut.displayText) is already used by ColorControl, macOS, or another app."
        case let .registration(shortcut, status):
            return "Could not register \(shortcut.displayText) (macOS error \(status))."
        }
    }
}

enum ShortcutRecordingError: Error, LocalizedError {
    case unsupportedKey
    case missingModifier

    var errorDescription: String? {
        switch self {
        case .unsupportedKey:
            return "That key cannot be used as a global shortcut."
        case .missingModifier:
            return "Include Command, Option, or Control in the shortcut."
        }
    }
}

extension GlobalKeyboardShortcut {
    init(recording event: NSEvent) throws {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = Self.displayKey(for: event)
        guard !key.isEmpty else { throw ShortcutRecordingError.unsupportedKey }

        self.init(
            keyCode: event.keyCode,
            key: key,
            usesCommand: flags.contains(.command),
            usesOption: flags.contains(.option),
            usesControl: flags.contains(.control),
            usesShift: flags.contains(.shift)
        )
        guard hasRegistrationModifier else { throw ShortcutRecordingError.missingModifier }
    }

    private static func displayKey(for event: NSEvent) -> String {
        switch Int(event.keyCode) {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_F13: return "F13"
        case kVK_F14: return "F14"
        case kVK_F15: return "F15"
        case kVK_F16: return "F16"
        case kVK_F17: return "F17"
        case kVK_F18: return "F18"
        case kVK_F19: return "F19"
        case kVK_F20: return "F20"
        default:
            return event.charactersIgnoringModifiers?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased() ?? ""
        }
    }
}

@MainActor
final class MacGlobalTVShortcutManager {
    private static let signature: OSType = 0x43435456 // "CCTV"

    private var eventHandler: EventHandlerRef?
    private var hotKeys: [EventHotKeyRef] = []
    private var onToggle: (@MainActor () -> Void)?

    func start(
        toggle: GlobalKeyboardShortcut,
        onToggle: @escaping @MainActor () -> Void
    ) throws {
        stop()

        guard toggle.hasRegistrationModifier else {
            throw GlobalTVShortcutError.missingModifier
        }

        self.onToggle = onToggle

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            colorControlGlobalHotKeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        guard handlerStatus == noErr else {
            stop()
            throw GlobalTVShortcutError.eventHandler(handlerStatus)
        }

        do {
            try register(.toggle, binding: toggle)
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        for hotKey in hotKeys {
            UnregisterEventHotKey(hotKey)
        }
        hotKeys.removeAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        onToggle = nil
    }

    fileprivate func handle(shortcutID: UInt32) {
        guard let shortcut = TVPowerShortcut(rawValue: shortcutID) else { return }
        switch shortcut {
        case .toggle: onToggle?()
        }
    }

    private func register(
        _ shortcut: TVPowerShortcut,
        binding: GlobalKeyboardShortcut
    ) throws {
        var hotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(binding.keyCode),
            carbonModifiers(for: binding),
            EventHotKeyID(signature: Self.signature, id: shortcut.rawValue),
            GetApplicationEventTarget(),
            OptionBits(kEventHotKeyExclusive),
            &hotKey
        )
        guard status == noErr, let hotKey else {
            throw GlobalTVShortcutError.registration(binding, status)
        }
        hotKeys.append(hotKey)
    }

    private func carbonModifiers(for shortcut: GlobalKeyboardShortcut) -> UInt32 {
        var modifiers: UInt32 = 0
        if shortcut.usesCommand { modifiers |= UInt32(cmdKey) }
        if shortcut.usesOption { modifiers |= UInt32(optionKey) }
        if shortcut.usesControl { modifiers |= UInt32(controlKey) }
        if shortcut.usesShift { modifiers |= UInt32(shiftKey) }
        return modifiers
    }
}

private func colorControlGlobalHotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID(signature: 0, id: 0)
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }

    let manager = Unmanaged<MacGlobalTVShortcutManager>
        .fromOpaque(userData)
        .takeUnretainedValue()
    Task { @MainActor in
        manager.handle(shortcutID: hotKeyID.id)
    }
    return noErr
}
