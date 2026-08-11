import AppKit
import ColorControlCore
import Foundation

/// Bridges documented NSWorkspace/AppKit notifications into the core event
/// contract. It observes the workspace notification center, as required by
/// AppKit, and never assumes a Windows service or process exists.
@MainActor
final class MacPlatformEventSource {
    let events: AsyncStream<PlatformSignal>

    private let continuation: AsyncStream<PlatformSignal>.Continuation
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init() {
        let stream = AsyncStream<PlatformSignal>.makeStream()
        events = stream.stream
        continuation = stream.continuation

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observe(workspaceCenter, name: NSWorkspace.willSleepNotification, kind: .willSleep)
        observe(workspaceCenter, name: NSWorkspace.didWakeNotification, kind: .didWake)
        observe(workspaceCenter, name: NSWorkspace.screensDidSleepNotification, kind: .screensDidSleep)
        observe(workspaceCenter, name: NSWorkspace.screensDidWakeNotification, kind: .screensDidWake)
        observe(workspaceCenter, name: NSWorkspace.willPowerOffNotification, kind: .willPowerOff)
        observe(workspaceCenter, name: NSWorkspace.sessionDidResignActiveNotification, kind: .sessionDidResignActive)
        observe(workspaceCenter, name: NSWorkspace.sessionDidBecomeActiveNotification, kind: .sessionDidBecomeActive)
        observe(workspaceCenter, name: NSWorkspace.didLaunchApplicationNotification, kind: .applicationActivityChanged)
        observe(workspaceCenter, name: NSWorkspace.didTerminateApplicationNotification, kind: .applicationActivityChanged)
        observe(workspaceCenter, name: NSWorkspace.didActivateApplicationNotification, kind: .applicationActivityChanged)

        observe(
            NotificationCenter.default,
            name: NSApplication.didChangeScreenParametersNotification,
            kind: .displayConfigurationChanged
        )

        continuation.yield(PlatformSignal(kind: .startup, context: makeContext()))
    }

    func stop() {
        observers.forEach { item in
            item.0.removeObserver(item.1)
        }
        observers.removeAll()
        continuation.finish()
    }

    private func observe(
        _ center: NotificationCenter,
        name: Notification.Name,
        kind: PlatformSignalKind
    ) {
        let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.emit(kind)
            }
        }
        observers.append((center, observer))
    }

    private func emit(_ kind: PlatformSignalKind) {
        continuation.yield(PlatformSignal(kind: kind, context: makeContext()))
    }

    private func makeContext() -> AutomationEventContext {
        let applications = NSWorkspace.shared.runningApplications
        let processes = Set(applications.compactMap(\.bundleIdentifier))
        let foregroundProcess = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let displays = NSScreen.screens.map(\.localizedName)

        // HDR/fullscreen/notification facts are deliberately nil until their
        // dedicated macOS adapters provide authoritative values.
        return AutomationEventContext(
            processes: processes,
            foregroundProcess: foregroundProcess,
            connectedDisplays: displays
        )
    }
}
