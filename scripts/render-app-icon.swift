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
graphicsContext.cgContext.translateBy(x: 0, y: size.height)
graphicsContext.cgContext.scaleBy(x: 1, y: -1)

let bounds = CGRect(origin: .zero, size: size)
let inset = size.width * 0.09375
let shellRect = bounds.insetBy(dx: inset, dy: inset)
let shellRadius = size.width * 0.22265625
let shellPath = NSBezierPath(roundedRect: shellRect, xRadius: shellRadius, yRadius: shellRadius)

let shellShadow = NSShadow()
shellShadow.shadowColor = NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.16, alpha: 0.16)
shellShadow.shadowBlurRadius = size.width * 0.05
shellShadow.shadowOffset = CGSize(width: 0, height: size.width * 0.015)

NSGraphicsContext.current?.saveGraphicsState()
shellShadow.set()
NSColor.white.setFill()
shellPath.fill()
NSGraphicsContext.current?.restoreGraphicsState()

let shellGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 1.0, green: 0.992, blue: 0.988, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.948, green: 0.957, blue: 0.973, alpha: 1), 0.58),
    (NSColor(calibratedRed: 0.894, green: 0.917, blue: 0.949, alpha: 1), 1.0)
)
shellGradient?.draw(in: shellPath, angle: -38)

NSColor(calibratedRed: 0.035, green: 0.067, blue: 0.121, alpha: 0.08).setStroke()
shellPath.lineWidth = max(1, size.width * 0.0013)
shellPath.stroke()

NSGraphicsContext.current?.saveGraphicsState()
shellPath.addClip()

let washRect = CGRect(
    x: shellRect.minX + size.width * 0.090,
    y: shellRect.minY + size.height * 0.60,
    width: size.width * 0.48,
    height: size.height * 0.22
)
let washPath = NSBezierPath(roundedRect: washRect, xRadius: size.width * 0.07, yRadius: size.width * 0.07)
let washGradient = NSGradient(colorsAndLocations:
    (NSColor.white.withAlphaComponent(0.92), 0.0),
    (NSColor.white.withAlphaComponent(0.24), 0.44),
    (NSColor.white.withAlphaComponent(0.0), 1.0)
)
washGradient?.draw(in: washPath, relativeCenterPosition: NSPoint(x: -0.28, y: 0.36))

let glowRect = CGRect(
    x: size.width * 0.392,
    y: size.height * 0.268,
    width: size.width * 0.220,
    height: size.width * 0.220
)
let glowPath = NSBezierPath(ovalIn: glowRect)
let glowGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.31, green: 0.76, blue: 1.0, alpha: 0.18), 0.0),
    (NSColor(calibratedRed: 0.31, green: 0.76, blue: 1.0, alpha: 0.0), 1.0)
)
glowGradient?.draw(in: glowPath, relativeCenterPosition: .zero)

let yokePath = NSBezierPath()
yokePath.move(to: CGPoint(x: size.width * 0.378, y: size.height * 0.418))
yokePath.curve(
    to: CGPoint(x: size.width * 0.5, y: size.height * 0.632),
    controlPoint1: CGPoint(x: size.width * 0.378, y: size.height * 0.574),
    controlPoint2: CGPoint(x: size.width * 0.434, y: size.height * 0.632)
)
yokePath.curve(
    to: CGPoint(x: size.width * 0.622, y: size.height * 0.418),
    controlPoint1: CGPoint(x: size.width * 0.566, y: size.height * 0.632),
    controlPoint2: CGPoint(x: size.width * 0.622, y: size.height * 0.574)
)
yokePath.lineCapStyle = .round
yokePath.lineJoinStyle = .round
yokePath.lineWidth = size.width * 0.051
NSColor(calibratedRed: 0.161, green: 0.192, blue: 0.231, alpha: 0.98).setStroke()
yokePath.stroke()

let capsuleRect = CGRect(
    x: size.width * 0.403,
    y: size.height * 0.214,
    width: size.width * 0.194,
    height: size.height * 0.316
)
let capsulePath = NSBezierPath(roundedRect: capsuleRect, xRadius: capsuleRect.width / 2, yRadius: capsuleRect.width / 2)
let capsuleGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.247, green: 0.298, blue: 0.361, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.136, green: 0.164, blue: 0.205, alpha: 1), 0.52),
    (NSColor(calibratedRed: 0.071, green: 0.094, blue: 0.129, alpha: 1), 1.0)
)
capsuleGradient?.draw(in: capsulePath, angle: -90)

NSColor.white.withAlphaComponent(0.12).setStroke()
capsulePath.lineWidth = max(1, size.width * 0.0014)
capsulePath.stroke()

let highlightRect = CGRect(
    x: size.width * 0.486,
    y: size.height * 0.266,
    width: size.width * 0.048,
    height: size.height * 0.214
)
let highlightPath = NSBezierPath(roundedRect: highlightRect, xRadius: highlightRect.width / 2, yRadius: highlightRect.width / 2)
let highlightGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.463, green: 0.878, blue: 1.0, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.278, green: 0.714, blue: 1.0, alpha: 1), 0.44),
    (NSColor(calibratedRed: 0.200, green: 0.471, blue: 1.0, alpha: 1), 1.0)
)
highlightGradient?.draw(in: highlightPath, angle: -90)
NSColor.white.withAlphaComponent(0.14).setStroke()
highlightPath.lineWidth = max(1, size.width * 0.0012)
highlightPath.stroke()

let stemRect = CGRect(
    x: size.width * 0.484,
    y: size.height * 0.632,
    width: size.width * 0.033,
    height: size.height * 0.096
)
let stemPath = NSBezierPath(roundedRect: stemRect, xRadius: stemRect.width / 2, yRadius: stemRect.width / 2)
NSColor(calibratedRed: 0.161, green: 0.192, blue: 0.231, alpha: 0.98).setFill()
stemPath.fill()

let baseRect = CGRect(
    x: size.width * 0.396,
    y: size.height * 0.754,
    width: size.width * 0.208,
    height: size.height * 0.041
)
let basePath = NSBezierPath(roundedRect: baseRect, xRadius: baseRect.height / 2, yRadius: baseRect.height / 2)
basePath.fill()

NSGraphicsContext.current?.restoreGraphicsState()
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
