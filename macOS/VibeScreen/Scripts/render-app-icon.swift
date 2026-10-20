import AppKit
import Foundation

// Shared "Vibe" family icon renderer: macOS icon grid (824pt body on a 1024 canvas),
// diagonal two-tone gradient, soft top sheen, white glyph with a gentle drop shadow.

let canvasSize: CGFloat = 1_024
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 186
let stroke: CGFloat = 46

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

struct IconSpec {
    let name: String
    let top: NSColor
    let bottom: NSColor
    let accent: NSColor
    let glyph: (IconSpec) -> Void
}

func roundedLine(_ from: NSPoint, _ to: NSPoint, width: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: from)
    path.line(to: to)
    path.lineWidth = width
    path.lineCapStyle = .round
    return path
}

func drawMonitor(_ spec: IconSpec) {
    let screen = NSRect(x: 232, y: 372, width: 560, height: 384)
    let frame = NSBezierPath(roundedRect: screen, xRadius: 64, yRadius: 64)
    NSColor.white.withAlphaComponent(0.14).setFill()
    frame.fill()
    NSColor.white.setStroke()
    frame.lineWidth = stroke
    frame.stroke()

    roundedLine(NSPoint(x: 512, y: 372), NSPoint(x: 512, y: 300), width: stroke).stroke()
    roundedLine(NSPoint(x: 400, y: 280), NSPoint(x: 624, y: 280), width: stroke).stroke()

    let rows: [(CGFloat, CGFloat)] = [(660, 0.32), (564, 0.70), (468, 0.50)]
    for (y, fraction) in rows {
        let start: CGFloat = 322, length: CGFloat = 380
        NSColor.white.withAlphaComponent(0.55).setStroke()
        roundedLine(NSPoint(x: start, y: y), NSPoint(x: start + length, y: y), width: 20).stroke()
        let x = start + length * fraction
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: x - 30, y: y - 30, width: 60, height: 60)).fill()
        spec.accent.setFill()
        NSBezierPath(ovalIn: NSRect(x: x - 15, y: y - 15, width: 30, height: 30)).fill()
    }
}

func drawShot(_ spec: IconSpec) {
    // Screenshot viewfinder corners around a lens.
    NSColor.white.setStroke()
    let inset: CGFloat = 250, arm: CGFloat = 130
    let minP = inset, maxP = canvasSize - inset
    let corners: [(NSPoint, NSPoint, NSPoint)] = [
        (NSPoint(x: minP, y: minP + arm), NSPoint(x: minP, y: minP), NSPoint(x: minP + arm, y: minP)),
        (NSPoint(x: maxP - arm, y: minP), NSPoint(x: maxP, y: minP), NSPoint(x: maxP, y: minP + arm)),
        (NSPoint(x: maxP, y: maxP - arm), NSPoint(x: maxP, y: maxP), NSPoint(x: maxP - arm, y: maxP)),
        (NSPoint(x: minP + arm, y: maxP), NSPoint(x: minP, y: maxP), NSPoint(x: minP, y: maxP - arm))
    ]
    for (a, b, c) in corners {
        let path = NSBezierPath()
        path.move(to: a); path.line(to: b); path.line(to: c)
        path.lineWidth = stroke
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
    let lens = NSBezierPath(ovalIn: NSRect(x: 512 - 138, y: 512 - 138, width: 276, height: 276))
    NSColor.white.withAlphaComponent(0.14).setFill()
    lens.fill()
    lens.lineWidth = stroke
    lens.stroke()
    spec.accent.setFill()
    NSBezierPath(ovalIn: NSRect(x: 512 - 58, y: 512 - 58, width: 116, height: 116)).fill()
    NSColor.white.withAlphaComponent(0.9).setFill()
    NSBezierPath(ovalIn: NSRect(x: 540, y: 540, width: 36, height: 36)).fill()
}

func drawPad(_ spec: IconSpec) {
    // Page with folded corner and text lines.
    let left: CGFloat = 292, right: CGFloat = 732, bottom: CGFloat = 228, top: CGFloat = 796, fold: CGFloat = 132
    let page = NSBezierPath()
    page.move(to: NSPoint(x: left, y: bottom + 40))
    page.appendArc(from: NSPoint(x: left, y: bottom), to: NSPoint(x: left + 40, y: bottom), radius: 40)
    page.appendArc(from: NSPoint(x: right, y: bottom), to: NSPoint(x: right, y: bottom + 40), radius: 40)
    page.line(to: NSPoint(x: right, y: top - fold))
    page.line(to: NSPoint(x: right - fold, y: top))
    page.appendArc(from: NSPoint(x: left, y: top), to: NSPoint(x: left, y: top - 40), radius: 40)
    page.close()
    NSColor.white.withAlphaComponent(0.14).setFill()
    page.fill()
    NSColor.white.setStroke()
    page.lineWidth = stroke
    page.lineJoinStyle = .round
    page.stroke()

    let foldPath = NSBezierPath()
    foldPath.move(to: NSPoint(x: right - fold, y: top))
    foldPath.line(to: NSPoint(x: right - fold, y: top - fold))
    foldPath.line(to: NSPoint(x: right, y: top - fold))
    foldPath.lineWidth = stroke
    foldPath.lineJoinStyle = .round
    foldPath.lineCapStyle = .round
    foldPath.stroke()

    let lines: [(CGFloat, CGFloat)] = [(580, 300), (480, 300), (380, 200)]
    for (y, length) in lines {
        NSColor.white.withAlphaComponent(0.85).setStroke()
        roundedLine(NSPoint(x: 372, y: y), NSPoint(x: 372 + length, y: y), width: 34).stroke()
    }
    // Accent cursor.
    spec.accent.setStroke()
    roundedLine(NSPoint(x: 612, y: 345), NSPoint(x: 612, y: 415), width: 30).stroke()
}

let specs: [IconSpec] = [
    IconSpec(name: "VibeScreen", top: color(0x5B7CFF), bottom: color(0x7A2BE2), accent: color(0x38E1FF), glyph: drawMonitor),
    IconSpec(name: "VibeShot", top: color(0xFF6FA5), bottom: color(0xFF6A3D), accent: color(0xFFE066), glyph: drawShot),
    IconSpec(name: "MacPad", top: color(0x2FD6A3), bottom: color(0x0E8FB8), accent: color(0xFFD23F), glyph: drawPad)
]

func render(_ spec: IconSpec, to url: URL) throws {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(canvasSize), pixelsHigh: Int(canvasSize),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let squircle = NSBezierPath(roundedRect: body, xRadius: cornerRadius, yRadius: cornerRadius)

    // Drop shadow under the tile.
    NSGraphicsContext.saveGraphicsState()
    let tileShadow = NSShadow()
    tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    tileShadow.shadowOffset = NSSize(width: 0, height: -12)
    tileShadow.shadowBlurRadius = 28
    tileShadow.set()
    spec.bottom.setFill()
    squircle.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    NSGradient(starting: spec.top, ending: spec.bottom)!.draw(in: body, angle: -60)
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), NSColor.white.withAlphaComponent(0)])!
        .draw(in: NSRect(x: body.minX, y: body.midY, width: body.width, height: body.height / 2), angle: -90)

    let glyphShadow = NSShadow()
    glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    glyphShadow.shadowOffset = NSSize(width: 0, height: -8)
    glyphShadow.shadowBlurRadius = 18
    glyphShadow.set()
    spec.glyph(spec)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.25).setStroke()
    let rim = NSBezierPath(roundedRect: body.insetBy(dx: 2, dy: 2), xRadius: cornerRadius - 2, yRadius: cornerRadius - 2)
    rim.lineWidth = 3
    rim.stroke()

    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: url)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
for spec in specs {
    try render(spec, to: outputDirectory.appendingPathComponent("\(spec.name)-1024.png"))
}
