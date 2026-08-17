import AppKit

let folder = URL(fileURLWithPath: "/Users/liuhang/Documents/Google_Project/Github/WildSight/docs/design/icon-candidates")
let source = folder.appendingPathComponent("wildsight-icon-c-path.png")
let output = folder.appendingPathComponent("wildsight-icon-c-path-camera-leaf.png")
let size = NSSize(width: 1024, height: 1024)

guard let icon = NSImage(contentsOf: source),
      let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
  fatalError("Unable to load the C icon")
}

let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSGraphicsContext.current!.compositingOperation = .clear
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
NSGraphicsContext.current!.compositingOperation = .sourceOver
icon.draw(in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: icon.size), operation: .sourceOver, fraction: 1)

let markColor = NSColor(calibratedRed: 0.35, green: 0.40, blue: 0.35, alpha: 0.76)
// A large framing gesture encloses the entire leaf/path motif, not only the distant skyline.
let x0: CGFloat = 176
let x1: CGFloat = 848
let y0: CGFloat = 142
let y1: CGFloat = 864
let arm: CGFloat = 44
let marks = NSBezierPath()
marks.move(to: NSPoint(x: x0, y: y1 - arm)); marks.line(to: NSPoint(x: x0, y: y1)); marks.line(to: NSPoint(x: x0 + arm, y: y1))
marks.move(to: NSPoint(x: x1 - arm, y: y1)); marks.line(to: NSPoint(x: x1, y: y1)); marks.line(to: NSPoint(x: x1, y: y1 - arm))
marks.move(to: NSPoint(x: x0, y: y0 + arm)); marks.line(to: NSPoint(x: x0, y: y0)); marks.line(to: NSPoint(x: x0 + arm, y: y0))
marks.move(to: NSPoint(x: x1 - arm, y: y0)); marks.line(to: NSPoint(x: x1, y: y0)); marks.line(to: NSPoint(x: x1, y: y0 + arm))
marks.lineWidth = 4
marks.lineCapStyle = .round
marks.lineJoinStyle = .round
markColor.setStroke(); marks.stroke()

NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: output)
