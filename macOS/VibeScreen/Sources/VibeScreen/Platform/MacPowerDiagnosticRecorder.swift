import VibeScreenCore
import Foundation
import OSLog

actor MacPowerDiagnosticRecorder: PowerDiagnosticRecording {
    static let maximumCurrentLogBytes: UInt64 = 1_000_000

    let logURL: URL
    private let previousLogURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
        let diagnosticsDirectory = applicationSupport
            .appendingPathComponent("VibeScreen", isDirectory: true)
            .appendingPathComponent("Diagnostics", isDirectory: true)
        logURL = diagnosticsDirectory.appendingPathComponent("PowerDiagnostics.jsonl")
        previousLogURL = diagnosticsDirectory.appendingPathComponent("PowerDiagnostics.previous.jsonl")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder
    }

    func record(kind: String, details: [String: String]) async {
        do {
            try prepareDirectoryAndRotateIfNeeded()
            let entry = StoredPowerDiagnostic(
                timestamp: ISO8601DateFormatter().string(from: Date()),
                kind: kind,
                details: details
            )
            var data = try encoder.encode(entry)
            data.append(0x0A)

            if !fileManager.fileExists(atPath: logURL.path) {
                guard fileManager.createFile(
                    atPath: logURL.path,
                    contents: nil,
                    attributes: [.posixPermissions: 0o600]
                ) else {
                    throw CocoaError(.fileWriteUnknown)
                }
            }
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: logURL.path)

            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.synchronize()
            VibeScreenLogger.automation.notice("Power diagnostic: \(kind, privacy: .public)")
        } catch {
            VibeScreenLogger.app.error(
                "Could not write power diagnostics: \(error.localizedDescription, privacy: .private)"
            )
        }
    }

    private func prepareDirectoryAndRotateIfNeeded() throws {
        let directory = logURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)

        guard let attributes = try? fileManager.attributesOfItem(atPath: logURL.path),
              let size = attributes[.size] as? NSNumber,
              size.uint64Value >= Self.maximumCurrentLogBytes else { return }

        if fileManager.fileExists(atPath: previousLogURL.path) {
            try fileManager.removeItem(at: previousLogURL)
        }
        try fileManager.moveItem(at: logURL, to: previousLogURL)
        try fileManager.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: previousLogURL.path
        )
    }
}

private struct StoredPowerDiagnostic: Codable {
    let timestamp: String
    let kind: String
    let details: [String: String]
}
