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
    (NSColor(calibratedRed: 0.999, green: 0.992, blue: 0.988, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.949, green: 0.961, blue: 0.980, alpha: 1), 0.56),
    (NSColor(calibratedRed: 0.882, green: 0.906, blue: 0.945, alpha: 1), 1.0)
)
shellGradient?.draw(in: shellPath, angle: -38)

NSColor(calibratedRed: 0.035, green: 0.067, blue: 0.121, alpha: 0.08).setStroke()
shellPath.lineWidth = max(1, size.width * 0.0013)
shellPath.stroke()

NSGraphicsContext.current?.saveGraphicsState()
shellPath.addClip()

let washRect = CGRect(
    x: shellRect.minX + size.width * 0.075,
    y: shellRect.minY + size.height * 0.55,
    width: size.width * 0.56,
    height: size.height * 0.33
)
let washPath = NSBezierPath(roundedRect: washRect, xRadius: size.width * 0.07, yRadius: size.width * 0.07)
let washGradient = NSGradient(colorsAndLocations:
    (NSColor.white.withAlphaComponent(0.92), 0.0),
    (NSColor.white.withAlphaComponent(0.32), 0.46),
    (NSColor.white.withAlphaComponent(0.0), 1.0)
)
washGradient?.draw(in: washPath, relativeCenterPosition: NSPoint(x: -0.28, y: 0.36))

let yokePath = NSBezierPath()
yokePath.move(to: CGPoint(x: size.width * 0.373, y: size.height * 0.422))
yokePath.curve(
    to: CGPoint(x: size.width * 0.5, y: size.height * 0.627),
    controlPoint1: CGPoint(x: size.width * 0.373, y: size.height * 0.545),
    controlPoint2: CGPoint(x: size.width * 0.429, y: size.height * 0.627)
)
yokePath.curve(
    to: CGPoint(x: size.width * 0.627, y: size.height * 0.422),
    controlPoint1: CGPoint(x: size.width * 0.571, y: size.height * 0.627),
    controlPoint2: CGPoint(x: size.width * 0.627, y: size.height * 0.545)
)
yokePath.lineCapStyle = .round
yokePath.lineJoinStyle = .round
yokePath.lineWidth = size.width * 0.053
NSColor(calibratedRed: 0.157, green: 0.188, blue: 0.239, alpha: 1).setStroke()
yokePath.stroke()

let capsuleRect = CGRect(
    x: size.width * 0.434,
    y: size.height * 0.230,
    width: size.width * 0.133,
    height: size.height * 0.277
)
let capsulePath = NSBezierPath(roundedRect: capsuleRect, xRadius: capsuleRect.width / 2, yRadius: capsuleRect.width / 2)
let capsuleGradient = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.267, green: 0.843, blue: 1.0, alpha: 1), 0.0),
    (NSColor(calibratedRed: 0.196, green: 0.608, blue: 1.0, alpha: 1), 0.58),
    (NSColor(calibratedRed: 0.173, green: 0.388, blue: 1.0, alpha: 1), 1.0)
)
capsuleGradient?.draw(in: capsulePath, angle: -45)

NSColor.white.withAlphaComponent(0.28).setStroke()
capsulePath.lineWidth = max(1, size.width * 0.0011)
capsulePath.stroke()

let highlightRect = CGRect(
    x: size.width * 0.461,
    y: size.height * 0.270,
    width: size.width * 0.033,
    height: size.height * 0.170
)
let highlightPath = NSBezierPath(roundedRect: highlightRect, xRadius: highlightRect.width / 2, yRadius: highlightRect.width / 2)
NSColor.white.withAlphaComponent(0.28).setFill()
highlightPath.fill()

let stemRect = CGRect(
    x: size.width * 0.480,
    y: size.height * 0.625,
    width: size.width * 0.039,
    height: size.height * 0.102
)
let stemPath = NSBezierPath(roundedRect: stemRect, xRadius: stemRect.width / 2, yRadius: stemRect.width / 2)
NSColor(calibratedRed: 0.157, green: 0.188, blue: 0.239, alpha: 1).setFill()
stemPath.fill()

let baseRect = CGRect(
    x: size.width * 0.383,
    y: size.height * 0.742,
    width: size.width * 0.234,
    height: size.height * 0.047
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
