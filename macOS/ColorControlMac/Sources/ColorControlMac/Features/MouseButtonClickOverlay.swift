import AppKit
import SwiftUI

/// Adds distinct left- and right-click actions without replacing the native
/// SwiftUI text, layout, help, or accessibility presentation underneath it.
struct MouseButtonClickOverlay: NSViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled

    let onLeftClick: @MainActor () -> Void
    let onRightClick: @MainActor () -> Void

    func makeNSView(context: Context) -> MouseButtonClickView {
        let view = MouseButtonClickView()
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ view: MouseButtonClickView, context: Context) {
        view.isInteractionEnabled = isEnabled
        view.onLeftClick = onLeftClick
        view.onRightClick = onRightClick
    }
}

@MainActor
final class MouseButtonClickView: NSView {
    var isInteractionEnabled = true {
        didSet { window?.invalidateCursorRects(for: self) }
    }
    var onLeftClick: (@MainActor () -> Void)?
    var onRightClick: (@MainActor () -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        isInteractionEnabled ? super.hitTest(point) : nil
    }

    override func mouseDown(with event: NSEvent) {
        guard isInteractionEnabled else { return }
        if event.modifierFlags.contains(.control) {
            onRightClick?()
        } else {
            onLeftClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        guard isInteractionEnabled else { return }
        onRightClick?()
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        if isInteractionEnabled {
            addCursorRect(bounds, cursor: .pointingHand)
        }
    }
}
