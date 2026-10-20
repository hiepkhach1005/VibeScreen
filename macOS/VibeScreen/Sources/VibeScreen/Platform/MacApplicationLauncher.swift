import AppKit
import VibeScreenCore

actor MacApplicationLauncher: PresetApplicationLauncher {
    func launch(bundleIdentifier: String) async throws {
        guard let url = await MainActor.run(body: {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        }) else {
            throw MacApplicationLauncherError.applicationNotFound(bundleIdentifier)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            Task { @MainActor in
                let configuration = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: url, configuration: configuration) { application, error in
                    if let error {
                        continuation.resume(throwing: MacApplicationLauncherError.launchFailed(error.localizedDescription))
                    } else if let application {
                        _ = application
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: MacApplicationLauncherError.launchFailed(
                            "macOS did not return the launched application."
                        ))
                    }
                }
            }
        }
    }
}

private enum MacApplicationLauncherError: Error, LocalizedError, Sendable {
    case applicationNotFound(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case let .applicationNotFound(identifier):
            return "Could not resolve application \(identifier)."
        case let .launchFailed(message):
            return message
        }
    }
}
