import AppKit
import CoreGraphics
import Foundation

struct MacDisplayModeSnapshot: Sendable, Equatable, Identifiable {
    let id: String
    let pixelWidth: Int
    let pixelHeight: Int
    let refreshRate: Double

    init(pixelWidth: Int, pixelHeight: Int, refreshRate: Double) {
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.refreshRate = refreshRate
        self.id = "\(pixelWidth)x\(pixelHeight)@\(Int((refreshRate * 100).rounded()))"
    }
}

enum MacDisplayControlError: Error, LocalizedError, Sendable, Equatable {
    case displayNotFound(UInt32)
    case modeNotFound(String)
    case operationFailed(Int32)

    var errorDescription: String? {
        switch self {
        case let .displayNotFound(id): return "Display \(id) is no longer available."
        case let .modeNotFound(id): return "Display mode \(id) is no longer available."
        case let .operationFailed(code): return "macOS rejected the display operation (CoreGraphics error \(code))."
        }
    }
}

/// Uses public CoreGraphics display-mode APIs. The adapter never changes a
/// display until the caller explicitly selects a mode.
@MainActor
final class MacDisplayControl {
    func modes(for displayID: UInt32) -> [MacDisplayModeSnapshot] {
        let id = CGDirectDisplayID(displayID)
        guard CGDisplayIsOnline(id) != 0,
              let modes = CGDisplayCopyAllDisplayModes(id, nil) as? [CGDisplayMode] else {
            return []
        }

        var snapshots: [MacDisplayModeSnapshot] = []
        var seen: Set<String> = []
        for mode in modes {
            let snapshot = MacDisplayModeSnapshot(
                pixelWidth: CGDisplayModeGetPixelWidth(mode),
                pixelHeight: CGDisplayModeGetPixelHeight(mode),
                refreshRate: CGDisplayModeGetRefreshRate(mode)
            )
            guard seen.insert(snapshot.id).inserted else { continue }
            snapshots.append(snapshot)
        }
        return snapshots.sorted {
            if $0.pixelWidth != $1.pixelWidth { return $0.pixelWidth < $1.pixelWidth }
            if $0.pixelHeight != $1.pixelHeight { return $0.pixelHeight < $1.pixelHeight }
            return $0.refreshRate < $1.refreshRate
        }
    }

    func apply(_ mode: MacDisplayModeSnapshot, to displayID: UInt32) throws {
        let id = CGDirectDisplayID(displayID)
        guard CGDisplayIsOnline(id) != 0,
              let modes = CGDisplayCopyAllDisplayModes(id, nil) as? [CGDisplayMode] else {
            throw MacDisplayControlError.displayNotFound(displayID)
        }

        guard let selected = modes.first(where: { candidate in
            let candidateMode = MacDisplayModeSnapshot(
                pixelWidth: CGDisplayModeGetPixelWidth(candidate),
                pixelHeight: CGDisplayModeGetPixelHeight(candidate),
                refreshRate: CGDisplayModeGetRefreshRate(candidate)
            )
            return candidateMode.id == mode.id
        }) else {
            throw MacDisplayControlError.modeNotFound(mode.id)
        }

        let result = CGDisplaySetDisplayMode(id, selected, nil)
        guard result == .success else {
            throw MacDisplayControlError.operationFailed(Int32(result.rawValue))
        }
    }
}

struct MacColorProfileSnapshot: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let url: URL
}

enum MacColorProfileError: Error, LocalizedError, Sendable, Equatable {
    case unreadableProfile

    var errorDescription: String? {
        switch self {
        case .unreadableProfile: return "The ICC profile could not be read by ColorSync."
        }
    }
}

/// Enumerates user/system ICC profiles and validates them through AppKit's
/// ColorSync-backed color-space loader. Association/default-profile writes are
/// intentionally kept behind a later, verified ColorSync adapter.
@MainActor
final class MacColorProfileService {
    func installedProfiles() -> [MacColorProfileSnapshot] {
        let fileManager = FileManager.default
        let directories = [
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/ColorSync/Profiles", isDirectory: true),
            URL(fileURLWithPath: "/Library/ColorSync/Profiles", isDirectory: true),
            URL(fileURLWithPath: "/System/Library/ColorSync/Profiles", isDirectory: true)
        ]

        var result: [MacColorProfileSnapshot] = []
        var seen: Set<String> = []
        for directory in directories {
            guard let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in urls where ["icc", "icm"].contains(url.pathExtension.lowercased()) {
                guard seen.insert(url.standardizedFileURL.path).inserted else { continue }
                result.append(
                    MacColorProfileSnapshot(
                        id: url.standardizedFileURL.path,
                        name: url.deletingPathExtension().lastPathComponent,
                        url: url
                    )
                )
            }
        }
        return result.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func validate(_ profile: MacColorProfileSnapshot) throws {
        guard let data = try? Data(contentsOf: profile.url),
              NSColorSpace(iccProfileData: data) != nil else {
            throw MacColorProfileError.unreadableProfile
        }
    }
}
