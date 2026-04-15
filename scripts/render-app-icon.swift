import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: render-app-icon.swift <output-path> <size>\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments[1]
guard let iconSize = Double(CommandLine.arguments[2]), iconSize > 0 else {
    fputs("invalid icon size\n", stderr)
    exit(1)
}

let size = CGSize(width: iconSize, height: iconSize)
let pixels = Int(iconSize.rounded())
guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
else {
    fputs("failed to allocate bitmap\n", stderr)
    exit(1)
}

bitmap.size = size

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("failed to create graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let bounds = CGRect(origin: .zero, size: size)
let inset = size.width * 0.09375
let shellRect = bounds.insetBy(dx: inset, dy: inset)
let radius = size.width * 0.22265625

let shellPath = NSBezierPath(roundedRect: shellRect, xRadius: radius, yRadius: radius)
let shellGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.176, green: 0.180, blue: 0.204, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.094, green: 0.098, blue: 0.114, alpha: 1), 0.52),
    (NSColor(calibratedRed: 0.055, green: 0.059, blue: 0.071, alpha: 1), 1.0)
)
shellGradient?.draw(in: shellPath, angle: -38)

NSGraphicsContext.current?.saveGraphicsState()
shellPath.addClip()

let washRect = CGRect(
    x: shellRect.minX + size.width * 0.08,
    y: shellRect.minY + size.height * 0.53,
    width: size.width * 0.56,
    height: size.height * 0.34
)
let washPath = NSBezierPath(roundedRect: washRect, xRadius: size.width * 0.07, yRadius: size.width * 0.07)
let washGradient = NSGradient(colorsAndLocations:
    (NSColor.white.withAlphaComponent(0.17), 0.0),
    (NSColor.white.withAlphaComponent(0.07), 0.42),
    (NSColor.white.withAlphaComponent(0.0), 1.0)
)
washGradient?.draw(in: washPath, relativeCenterPosition: NSPoint(x: -0.3, y: 0.4))

NSGraphicsContext.current?.restoreGraphicsState()

NSColor.white.withAlphaComponent(0.12).setStroke()
shellPath.lineWidth = max(1, size.width * 0.0014)
shellPath.stroke()

let baseBarWidth = size.width * 0.076
let barSpacing = size.width * 0.032
let barsHeight: [CGFloat] = [
    size.height * 0.146,
    size.height * 0.264,
    size.height * 0.352,
    size.height * 0.205,
]
let barsXStart = size.width * 0.324
let barsBaseline = size.height * 0.662
let barsGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 1.0, green: 0.992, blue: 0.976, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.945, green: 0.925, blue: 0.890, alpha: 1), 1.0)
)

for (index, height) in barsHeight.enumerated() {
    let x = barsXStart + CGFloat(index) * (baseBarWidth + barSpacing)
    let rect = CGRect(x: x, y: barsBaseline - height, width: baseBarWidth, height: height)
    let path = NSBezierPath(roundedRect: rect, xRadius: baseBarWidth / 2, yRadius: baseBarWidth / 2)
    barsGradient?.draw(in: path, angle: 90)
}

let pulseDiameter = size.width * 0.141
let pulseRect = CGRect(
    x: size.width * 0.672,
    y: size.height * 0.672,
    width: pulseDiameter,
    height: pulseDiameter
)
let pulsePath = NSBezierPath(ovalIn: pulseRect)
let pulseGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.553, green: 0.761, blue: 1.0, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.247, green: 0.525, blue: 1.0, alpha: 1), 1.0)
)
pulseGradient?.draw(in: pulsePath, angle: -40)

NSColor.white.withAlphaComponent(0.28).setStroke()
pulsePath.lineWidth = max(1, size.width * 0.0012)
pulsePath.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("failed to encode icon image\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true,
    attributes: nil
)
try pngData.write(to: outputURL)
