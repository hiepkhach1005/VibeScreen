import AppKit

/// Monochrome template glyph for the status item, matching the Vibe app icon
/// (display + sliders). See VIBE_ICON_STYLE.md, section "Menu bar".
enum MenuBarIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            NSColor.black.set()

            let body = NSBezierPath(roundedRect: NSRect(x: 1.85, y: 2.85, width: 14.3, height: 9.8), xRadius: 2.2, yRadius: 2.2)
            body.lineWidth = 1.7
            body.stroke()

            let stand = NSBezierPath()
            stand.lineWidth = 1.7
            stand.lineCapStyle = .round
            stand.move(to: NSPoint(x: 9, y: 12.8)); stand.line(to: NSPoint(x: 9, y: 15.2))
            stand.move(to: NSPoint(x: 6, y: 15.4)); stand.line(to: NSPoint(x: 12, y: 15.4))
            stand.stroke()

            for (y, knob) in [(6.0, 7.0), (9.4, 11.2)] as [(CGFloat, CGFloat)] {
                let track = NSBezierPath()
                track.lineWidth = 1.1
                track.lineCapStyle = .round
                track.move(to: NSPoint(x: 4.8, y: y)); track.line(to: NSPoint(x: 13.2, y: y))
                track.stroke()
                NSBezierPath(ovalIn: NSRect(x: knob - 1.6, y: y - 1.6, width: 3.2, height: 3.2)).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "VibeScreen"
        return image
    }
}
