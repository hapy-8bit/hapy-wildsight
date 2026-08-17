import AppKit

let folder = URL(fileURLWithPath: "/Users/liuhang/Documents/Google_Project/Github/WildSight/docs/design/icon-candidates")
let output = folder.appendingPathComponent("wildsight-icon-comparison.png")
let canvasSize = NSSize(width: 1500, height: 1260)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(canvasSize.width), pixelsHigh: Int(canvasSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics

func color(_ hex: String) -> NSColor {
  let raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
  let value = UInt64(raw, radix: 16)!
  return NSColor(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255, blue: CGFloat(value & 0xFF) / 255, alpha: 1)
}

func drawText(_ text: String, x: CGFloat, y: CGFloat, font: NSFont, ink: NSColor, alignment: NSTextAlignment = .left, width: CGFloat = 0) {
  let style = NSMutableParagraphStyle()
  style.alignment = alignment
  let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: ink, .paragraphStyle: style]
  let rect = NSRect(x: x, y: canvasSize.height - y - font.pointSize * 1.4, width: width == 0 ? 600 : width, height: font.pointSize * 1.6)
  (text as NSString).draw(in: rect, withAttributes: attributes)
}

func roundedPanel(_ rect: NSRect, fill: NSColor, border: NSColor) {
  let path = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
  fill.setFill(); path.fill()
  border.setStroke(); path.lineWidth = 1; path.stroke()
}

func drawImage(_ file: String, x: CGFloat, y: CGFloat) {
  guard let image = NSImage(contentsOf: folder.appendingPathComponent(file)) else { return }
  let rect = NSRect(x: x, y: canvasSize.height - y - 250, width: 250, height: 250)
  image.draw(in: rect, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1)
}

color("F4F5F0").setFill(); NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
drawText("WildSight · 见野 图标候选", x: 80, y: 68, font: NSFont(name: "Times New Roman", size: 27) ?? .systemFont(ofSize: 27, weight: .bold), ink: color("1E251F"))
drawText("A 自然标本    B 观察取景框    C 无白边取景", x: 80, y: 106, font: .systemFont(ofSize: 19), ink: color("697269"))

let names = ["自然标本", "观察取景框", "无白边取景"]
let files = ["wildsight-icon-a-specimen.png", "wildsight-icon-b-observation.png", "wildsight-icon-c-path-camera-transparent.png"]
let xs: [CGFloat] = [194, 625, 1056]
let panelTop: CGFloat = 168
for (stageIndex, isDark) in [false, true].enumerated() {
  let panelY = panelTop + CGFloat(stageIndex) * 482
  let panel = NSRect(x: 80, y: canvasSize.height - panelY - 410, width: 1340, height: 410)
  roundedPanel(panel, fill: isDark ? color("19201C") : color("FCFCF8"), border: isDark ? color("3B493F") : color("E0E4DC"))
  drawText(isDark ? "深色桌面预览" : "浅色桌面预览", x: 114, y: panelY + 40, font: .systemFont(ofSize: 18, weight: .medium), ink: isDark ? color("B7C0B6") : color("697269"))
  for index in 0..<3 {
    drawImage(files[index], x: xs[index], y: panelY + 78)
    drawText(["A", "B", "C"][index], x: xs[index], y: panelY + 348, font: .systemFont(ofSize: 22, weight: .bold), ink: isDark ? color("E8ECE4") : color("1E251F"), alignment: .center, width: 250)
    drawText(names[index], x: xs[index], y: panelY + 380, font: .systemFont(ofSize: 16), ink: isDark ? color("B7C0B6") : color("697269"), alignment: .center, width: 250)
  }
}
drawText("仅供候选评审；尚未替换 AppScope 正式图标资源。", x: 80, y: 1154, font: .systemFont(ofSize: 16), ink: color("697269"))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: output)
