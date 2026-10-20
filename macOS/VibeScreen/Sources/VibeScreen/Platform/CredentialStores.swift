import Foundation

protocol TVCredentialStore: Sendable {
    func save(_ secret: String, reference: String) throws
    func read(reference: String) throws -> String?
    func delete(reference: String) throws
}

extension KeychainCredentialStore: TVCredentialStore {}

enum CredentialStorageMode: Sendable, Equatable {
    case keychain
    case developmentFile(directory: URL)

    static func developmentDirectory(fileManager: FileManager = .default) -> URL {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
        return applicationSupport
            .appendingPathComponent("VibeScreen", isDirectory: true)
            .appendingPathComponent("DevelopmentCredentials", isDirectory: true)
    }

    static func configured(fileManager: FileManager = .default) -> CredentialStorageMode {
#if DEBUG && VIBESCREEN_DEVELOPMENT_FILE_CREDENTIALS
        return .developmentFile(
            directory: developmentDirectory(fileManager: fileManager)
        )
#else
        return .keychain
#endif
    }
}

enum DevelopmentFileCredentialError: Error, LocalizedError, Sendable, Equatable {
    case invalidReference
    case invalidData
    case symbolicLinkNotAllowed
    case couldNotCreateFile

    var errorDescription: String? {
        switch self {
        case .invalidReference:
            return "The credential reference is not safe for file storage."
        case .invalidData:
            return "The credential file did not contain valid UTF-8 data."
        case .symbolicLinkNotAllowed:
            return "Symbolic links are not allowed for development credential files."
        case .couldNotCreateFile:
            return "The development credential file could not be created."
        }
    }
}

/// Plaintext credential storage for explicitly opted-in local debug builds.
/// Each secret is isolated in an owner-only file and excluded from backups.
struct DevelopmentFileCredentialStore: TVCredentialStore, Sendable {
    let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    func save(_ secret: String, reference: String) throws {
        guard let data = secret.data(using: .utf8) else {
            throw DevelopmentFileCredentialError.invalidData
        }

        try prepareDirectory()
        let destination = try credentialURL(reference: reference)
        try rejectSymbolicLink(at: destination)

        let temporary = directory.appendingPathComponent(".credential-\(UUID().uuidString).tmp")
        guard FileManager.default.createFile(
            atPath: temporary.path,
            contents: nil,
            attributes: [.posixPermissions: 0o600]
        ) else {
            throw DevelopmentFileCredentialError.couldNotCreateFile
        }

        do {
            let handle = try FileHandle(forWritingTo: temporary)
            try handle.write(contentsOf: data)
            try handle.synchronize()
            try handle.close()

            if FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: temporary)
            } else {
                try FileManager.default.moveItem(at: temporary, to: destination)
            }
            try hardenPermissions(at: destination, permissions: 0o600)
            try excludeFromBackup(destination)
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }

    func read(reference: String) throws -> String? {
        let url = try credentialURL(reference: reference)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        try rejectSymbolicLink(at: url)
        try hardenPermissions(at: url, permissions: 0o600)
        let data = try Data(contentsOf: url)
        guard let value = String(data: data, encoding: .utf8) else {
            throw DevelopmentFileCredentialError.invalidData
        }
        return value
    }

    func delete(reference: String) throws {
        let url = try credentialURL(reference: reference)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try rejectSymbolicLink(at: url)
        try FileManager.default.removeItem(at: url)
    }

    private func credentialURL(reference: String) throws -> URL {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        guard !reference.isEmpty,
              reference.utf8.count <= 200,
              reference.unicodeScalars.allSatisfy(allowed.contains) else {
            throw DevelopmentFileCredentialError.invalidReference
        }
        return directory.appendingPathComponent(reference).appendingPathExtension("txt")
    }

    private func prepareDirectory() throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try hardenPermissions(at: directory, permissions: 0o700)
        try excludeFromBackup(directory)
    }

    private func rejectSymbolicLink(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if values.isSymbolicLink == true {
            throw DevelopmentFileCredentialError.symbolicLinkNotAllowed
        }
    }

    private func hardenPermissions(at url: URL, permissions: Int) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: permissions],
            ofItemAtPath: url.path
        )
    }

    private func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }
}

/// Keeps production on Keychain while allowing an explicit local-development
/// file mode. File mode never touches Keychain, so local builds cannot trigger
/// a Keychain password prompt. A normal build can move a development file back
/// to Keychain on its next connection.
struct MigratingCredentialStore: TVCredentialStore, Sendable {
    let mode: CredentialStorageMode

    private let keychain: KeychainCredentialStore
    private let developmentFile: DevelopmentFileCredentialStore?

    init(
        mode: CredentialStorageMode = .configured(),
        keychain: KeychainCredentialStore = KeychainCredentialStore()
    ) {
        self.mode = mode
        self.keychain = keychain
        if case let .developmentFile(directory) = mode {
            self.developmentFile = DevelopmentFileCredentialStore(directory: directory)
        } else {
            self.developmentFile = DevelopmentFileCredentialStore(
                directory: CredentialStorageMode.developmentDirectory()
            )
        }
    }

    func save(_ secret: String, reference: String) throws {
        switch mode {
        case .keychain:
            try keychain.save(secret, reference: reference)
            try developmentFile?.delete(reference: reference)
        case .developmentFile:
            guard let developmentFile else { return }
            try developmentFile.save(secret, reference: reference)
        }
    }

    func read(reference: String) throws -> String? {
        switch mode {
        case .keychain:
            if let value = try developmentFile?.read(reference: reference) {
                try keychain.save(value, reference: reference)
                try developmentFile?.delete(reference: reference)
                return value
            }
            return try keychain.read(reference: reference)
        case .developmentFile:
            guard let developmentFile else { return nil }
            return try developmentFile.read(reference: reference)
        }
    }

    func delete(reference: String) throws {
        switch mode {
        case .keychain:
            try keychain.delete(reference: reference)
            try developmentFile?.delete(reference: reference)
        case .developmentFile:
            try developmentFile?.delete(reference: reference)
        }
    }
}
