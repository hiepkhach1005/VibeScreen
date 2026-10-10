import AppKit
import Darwin
import Foundation

private enum RenderError: Error {
    case missingBitmapContext
    case missingBitmap
    case missingPNG
}

private func renderIcon(to outputURL: URL) throws {
    let canvasSize: CGFloat = 1_024
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize),
        pixelsHigh: Int(canvasSize),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw RenderError.missingBitmap
    }
    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw RenderError.missingBitmapContext
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer { NSGraphicsContext.restoreGraphicsState() }

    let canvas = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
    let background = NSBezierPath(roundedRect: canvas, xRadius: 210, yRadius: 210)
    background.addClip()

    guard let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.35, blue: 0.95, alpha: 1),
        NSColor(calibratedRed: 0.35, green: 0.16, blue: 0.78, alpha: 1)
    ]) else {
        throw RenderError.missingBitmapContext
    }
    gradient.draw(in: canvas, angle: -35)

    NSColor.white.withAlphaComponent(0.08).setFill()
    NSBezierPath(ovalIn: NSRect(x: 600, y: 620, width: 600, height: 600)).fill()

    let monitorRect = NSRect(x: 132, y: 306, width: 760, height: 478)
    let monitor = NSBezierPath(roundedRect: monitorRect, xRadius: 82, yRadius: 82)
    NSColor.white.withAlphaComponent(0.09).setFill()
    monitor.fill()
    NSColor.white.setStroke()
    monitor.lineWidth = 34
    monitor.stroke()

    let trackStart: CGFloat = 294
    let trackLength: CGFloat = 438
    let lineWidth: CGFloat = 24
    let rows: [(y: CGFloat, fraction: CGFloat, color: NSColor)] = [
        (650, 0.30, NSColor(calibratedRed: 0.25, green: 0.89, blue: 1, alpha: 1)),
        (546, 0.68, NSColor(calibratedRed: 0.38, green: 0.98, blue: 0.63, alpha: 1)),
        (442, 0.47, NSColor(calibratedRed: 1, green: 0.70, blue: 0.29, alpha: 1))
    ]

    for row in rows {
        let track = NSBezierPath()
        track.move(to: NSPoint(x: trackStart, y: row.y))
        track.line(to: NSPoint(x: trackStart + trackLength, y: row.y))
        track.lineWidth = lineWidth
        track.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.52).setStroke()
        track.stroke()

        let knobX = trackStart + trackLength * row.fraction
        let knob = NSBezierPath(ovalIn: NSRect(x: knobX - 35, y: row.y - 35, width: 70, height: 70))
        row.color.setFill()
        knob.fill()
        NSColor.white.withAlphaComponent(0.9).setStroke()
        knob.lineWidth = 8
        knob.stroke()
    }

    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: 470, y: 188, width: 84, height: 132), xRadius: 26, yRadius: 26).fill()
    NSBezierPath(roundedRect: NSRect(x: 344, y: 122, width: 336, height: 54), xRadius: 27, yRadius: 27).fill()

    guard let pngData = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
        throw RenderError.missingPNG
    }
    try pngData.write(to: outputURL, options: Data.WritingOptions.atomic)
}

let outputPath = CommandLine.arguments.dropFirst().first ?? "Sources/ColorControlMac/Resources/AppIcon-1024.png"
do {
    try renderIcon(to: URL(fileURLWithPath: outputPath))
} catch {
    fputs("Unable to render ColorControl icon: \(error)\n", stderr)
    exit(EXIT_FAILURE)
}
