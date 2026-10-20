import AppKit
import VibeScreenCore
import Foundation

enum MacGameLauncherError: Error, LocalizedError, Sendable {
    case applicationNotFound(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case let .applicationNotFound(value): return "Could not resolve application \(value)."
        case let .launchFailed(message): return message
        }
    }
}

/// Uses public Process/NSWorkspace APIs. Windows elevation, affinity,
/// priority, and thread suspension are intentionally not represented here.
actor MacGameProcessLauncher: GameProcessLauncher {
    private var childProcesses: [Int32: Process] = [:]

    func launch(_ specification: GameLaunchSpecification) async throws -> LaunchedProcess {
        let input = specification.pathOrBundleIdentifier
        let url = URL(fileURLWithPath: input)

        if input.hasSuffix(".app") || (!input.contains("/") && !input.contains("\\")) {
            let applicationURL: URL
            if input.hasSuffix(".app") {
                applicationURL = url
            } else if let resolved = await MainActor.run(body: {
                NSWorkspace.shared.urlForApplication(withBundleIdentifier: input)
            }) {
                applicationURL = resolved
            } else {
                throw MacGameLauncherError.applicationNotFound(input)
            }

            let processIdentifier: Int32 = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Int32, any Error>) in
                Task { @MainActor in
                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.arguments = specification.arguments
                    if let workingDirectory = specification.workingDirectory {
                        configuration.environment = ["PWD": workingDirectory]
                    }

                    NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) { application, error in
                        if let error {
                            continuation.resume(throwing: MacGameLauncherError.launchFailed(error.localizedDescription))
                        } else if let application {
                            continuation.resume(returning: application.processIdentifier)
                        } else {
                            continuation.resume(throwing: MacGameLauncherError.launchFailed("macOS did not return a running application."))
                        }
                    }
                }
            }

            return LaunchedProcess(identifier: processIdentifier)
        }

        let process = Process()
        process.executableURL = url
        process.arguments = specification.arguments
        if let workingDirectory = specification.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)
        }

        do {
            try process.run()
        } catch {
            throw MacGameLauncherError.launchFailed(error.localizedDescription)
        }

        childProcesses[process.processIdentifier] = process
        return LaunchedProcess(identifier: process.processIdentifier)
    }

    func waitForExit(_ process: LaunchedProcess) async throws {
        guard let identifier = process.identifier else {
            return
        }

        if let child = childProcesses[identifier] {
            if child.isRunning {
                await withCheckedContinuation { continuation in
                    child.terminationHandler = { _ in
                        continuation.resume()
                    }
                }
            }
            childProcesses.removeValue(forKey: identifier)
            return
        }

        // NSWorkspace launches do not expose a Process termination handler.
        // Poll the public running-application registry at a low frequency so
        // finalization steps still run for .app and bundle-ID targets.
        while await MainActor.run(body: {
            NSRunningApplication(processIdentifier: identifier) != nil
        }) {
            try await Task.sleep(nanoseconds: 500_000_000)
        }
    }
}
