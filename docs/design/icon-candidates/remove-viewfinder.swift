import AppKit

let folder = URL(fileURLWithPath: "/Users/liuhang/Documents/Google_Project/Github/WildSight/docs/design/icon-candidates")
let source = folder.appendingPathComponent("wildsight-icon-c-path-camera-transparent.png")
let output = folder.appendingPathComponent("wildsight-icon-c-path-transparent.png")
guard let icon = NSImage(contentsOf: source),
      let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
  fatalError("Unable to load the viewfinder icon")
}

let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
icon.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024), from: NSRect(x: 0, y: 0, width: icon.size.width, height: icon.size.height), operation: .sourceOver, fraction: 1)

// Remove the four marks by colour within their local areas. This leaves the nearby
// lower-left leaf stem untouched, unlike clearing the whole corner rectangle.
let frameAreas = [
  NSRect(x: 70, y: 875, width: 120, height: 100),
  NSRect(x: 840, y: 875, width: 125, height: 100),
  NSRect(x: 70, y: 55, width: 120, height: 100),
  NSRect(x: 840, y: 55, width: 125, height: 100)
]
let pixels = bitmap.bitmapData!
for area in frameAreas {
  for x in Int(area.minX)..<Int(area.maxX) {
    for y in Int(area.minY)..<Int(area.maxY) {
      guard let color = bitmap.colorAt(x: x, y: y) else { continue }
      let red = color.redComponent
      let green = color.greenComponent
      let blue = color.blueComponent
      let isViewfinderInk = color.alphaComponent > 0.001
        && red > 0.20 && red < 0.55
        && green > 0.25 && green < 0.62
        && blue > 0.20 && blue < 0.60
        && abs(red - blue) < 0.25
      if (isViewfinderInk) {
        let pixel = pixels.advanced(by: y * bitmap.bytesPerRow + x * 4)
        pixel[0] = 0
        pixel[1] = 0
        pixel[2] = 0
        pixel[3] = 0
      }
    }
  }
}
// The three clear corners contain no illustration; the lower-left rectangle stops
// just before the leaf stem at x=170.
let finalEraseAreas = [
  NSRect(x: 70, y: 55, width: 120, height: 100),
  NSRect(x: 840, y: 55, width: 125, height: 100),
  NSRect(x: 70, y: 875, width: 90, height: 149),
  NSRect(x: 840, y: 875, width: 125, height: 100)
]
for area in finalEraseAreas {
  for x in Int(area.minX)..<Int(area.maxX) {
    for y in Int(area.minY)..<Int(area.maxY) {
      let pixel = pixels.advanced(by: y * bitmap.bytesPerRow + x * 4)
      pixel[0] = 0
      pixel[1] = 0
      pixel[2] = 0
      pixel[3] = 0
    }
  }
}
NSGraphicsContext.restoreGraphicsState()

try bitmap.representation(using: .png, properties: [:])!.write(to: output)
