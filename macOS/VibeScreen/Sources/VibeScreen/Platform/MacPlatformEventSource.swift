import AppKit
import VibeScreenCore
import CoreGraphics
import Foundation

/// Bridges documented NSWorkspace/AppKit notifications into the core event
/// contract. It observes the workspace notification center, as required by
/// AppKit, and never assumes a Windows service or process exists.
@MainActor
final class MacPlatformEventSource {
    let events: AsyncStream<PlatformSignal>

    private let continuation: AsyncStream<PlatformSignal>.Continuation
    private let diagnostics: (any PowerDiagnosticRecording)?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var pendingScreenWakeTasks: [UUID: Task<Void, Never>] = [:]
    private var diagnosticTasks: [UUID: Task<Void, Never>] = [:]

    init(diagnostics: (any PowerDiagnosticRecording)? = nil) {
        self.diagnostics = diagnostics
        let stream = AsyncStream<PlatformSignal>.makeStream()
        events = stream.stream
        continuation = stream.continuation

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observe(workspaceCenter, name: NSWorkspace.willSleepNotification, kind: .willSleep)
        observe(workspaceCenter, name: NSWorkspace.didWakeNotification, kind: .didWake)
        observe(workspaceCenter, name: NSWorkspace.screensDidSleepNotification, kind: .screensDidSleep)
        observeScreenWake(workspaceCenter)
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

        recordDiagnostic(kind: "platform.signal.emitted", details: ["signal": "startup"])
        continuation.yield(PlatformSignal(kind: .startup, context: makeContext()))
    }

    func stop() {
        pendingScreenWakeTasks.values.forEach { $0.cancel() }
        pendingScreenWakeTasks.removeAll()
        diagnosticTasks.values.forEach { $0.cancel() }
        diagnosticTasks.removeAll()
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

    private func observeScreenWake(_ center: NotificationCenter) {
        let observer = center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.validateScreenWakeUserIntent()
            }
        }
        observers.append((center, observer))
    }

    private func validateScreenWakeUserIntent() {
        let validationID = UUID()
        recordDiagnostic(
            kind: "platform.screenWake.received",
            details: ["validationID": validationID.uuidString]
        )

        let task = Task { @MainActor [weak self] in
            do {
                // Give the physical input event that woke the screen time to
                // reach the current user session before measuring idle time.
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }

            let inputAge = CGEventSource.secondsSinceLastEventType(
                .combinedSessionState,
                eventType: .null
            )
            let shouldForward = ScreenWakeUserIntentPolicy.shouldForwardScreenWake(
                secondsSinceLastUserInput: inputAge
            )
            recordDiagnostic(
                kind: shouldForward
                    ? "platform.screenWake.forwarded"
                    : "platform.screenWake.suppressedNoRecentInput",
                details: [
                    "validationID": validationID.uuidString,
                    "inputAgeSeconds": String(format: "%.3f", inputAge),
                    "maximumInputAgeSeconds": String(
                        ScreenWakeUserIntentPolicy.defaultMaximumInputAgeSeconds
                    )
                ]
            )
            pendingScreenWakeTasks.removeValue(forKey: validationID)
            guard shouldForward else { return }
            emit(.screensDidWake)
        }
        pendingScreenWakeTasks[validationID] = task
    }

    private func emit(_ kind: PlatformSignalKind) {
        if kind == .screensDidSleep {
            pendingScreenWakeTasks.values.forEach { $0.cancel() }
            pendingScreenWakeTasks.removeAll()
        }
        recordDiagnostic(kind: "platform.signal.emitted", details: ["signal": kind.rawValue])
        continuation.yield(PlatformSignal(kind: kind, context: makeContext()))
    }

    private func recordDiagnostic(kind: String, details: [String: String]) {
        guard let diagnostics else { return }
        let taskID = UUID()
        let task = Task { @MainActor [weak self, diagnostics] in
            await diagnostics.record(kind: kind, details: details)
            self?.diagnosticTasks.removeValue(forKey: taskID)
        }
        diagnosticTasks[taskID] = task
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
