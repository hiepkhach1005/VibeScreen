import AppKit
import CoreGraphics
import Foundation

struct MacDisplaySnapshot: Sendable, Equatable, Identifiable {
    let id: UInt32
    let name: String
    let pixelWidth: Int
    let pixelHeight: Int
    let scaleFactor: Double
    let isBuiltIn: Bool
    let hdrState: Bool?

    var identifier: UInt32 { id }
}

@MainActor
final class MacDisplayService {
    func snapshots() -> [MacDisplaySnapshot] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }

            let displayID = CGDirectDisplayID(number.uint32Value)
            let mode = CGDisplayCopyDisplayMode(displayID)

            return MacDisplaySnapshot(
                id: displayID,
                name: screen.localizedName,
                pixelWidth: mode?.pixelWidth ?? Int(screen.frame.width * screen.backingScaleFactor),
                pixelHeight: mode?.pixelHeight ?? Int(screen.frame.height * screen.backingScaleFactor),
                scaleFactor: screen.backingScaleFactor,
                isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
                hdrState: hdrState(for: screen)
            )
        }
    }

    private func hdrState(for screen: NSScreen) -> Bool? {
        if #available(macOS 10.15, *) {
            return screen.maximumExtendedDynamicRangeColorComponentValue > 1.0
        }
        return nil
    }
}
