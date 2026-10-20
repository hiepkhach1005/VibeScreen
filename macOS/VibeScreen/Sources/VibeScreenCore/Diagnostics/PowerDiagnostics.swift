import Foundation

/// A narrow, privacy-safe sink for diagnosing TV power automation. Callers
/// must never include host names, IP addresses, MAC addresses, credentials, or
/// protocol payloads in `details`.
public protocol PowerDiagnosticRecording: Sendable {
    func record(kind: String, details: [String: String]) async
}

public enum ScreenWakeUserIntentPolicy {
    public static let defaultMaximumInputAgeSeconds = 5.0

    /// `NSWorkspace.screensDidWakeNotification` describes a display fact, not
    /// user intent. Only forward it to TV wake automation when CoreGraphics
    /// also reports a recent user input event.
    public static func shouldForwardScreenWake(
        secondsSinceLastUserInput: Double,
        maximumInputAgeSeconds: Double = defaultMaximumInputAgeSeconds
    ) -> Bool {
        secondsSinceLastUserInput.isFinite
            && secondsSinceLastUserInput >= 0
            && secondsSinceLastUserInput <= maximumInputAgeSeconds
    }
}
