// Usage: swift Tools/GenerateIcon.swift
// Generates Assets/AppIcon.iconset, Assets/AppIcon.icns and Assets/AppIcon-preview.png.
import AppKit
import CoreGraphics

func draw(size s: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    let cs = CGColorSpaceCreateDeviceRGB()
    func col(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(colorSpace: cs, components: [r, g, b, a])!
    }
    let u = s / 1024
    // macOS squircle with standard margin
    let rect = CGRect(x: 100 * u, y: 100 * u, width: 824 * u, height: 824 * u)
    let path = CGPath(roundedRect: rect, cornerWidth: 185 * u, cornerHeight: 185 * u, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * u), blur: 28 * u, color: col(0, 0, 0, 0.35))
    ctx.addPath(path); ctx.setFillColor(col(0, 0, 0)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path); ctx.clip()
    let bg = CGGradient(colorsSpace: cs, colors: [col(0.98, 0.72, 0.38), col(0.80, 0.42, 0.20), col(0.36, 0.18, 0.10)] as CFArray,
                        locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
    // soft top glow
    let glow = CGGradient(colorsSpace: cs, colors: [col(1, 1, 1, 0.35), col(1, 1, 1, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 400 * u, y: 900 * u), startRadius: 0,
                           endCenter: CGPoint(x: 400 * u, y: 900 * u), endRadius: 600 * u, options: [])

    let white = col(1, 1, 1)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * u), blur: 18 * u, color: col(0, 0, 0, 0.3))
    // one layer so the cup, handle and saucer share a single shadow
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    // saucer
    let saucer = CGPath(ellipseIn: CGRect(x: 230 * u, y: 225 * u, width: 520 * u, height: 90 * u), transform: nil)
    ctx.addPath(saucer); ctx.setFillColor(white); ctx.fillPath()
    // handle (ring on the right)
    ctx.setStrokeColor(white); ctx.setLineWidth(46 * u)
    ctx.addEllipse(in: CGRect(x: 600 * u, y: 395 * u, width: 150 * u, height: 150 * u))
    ctx.strokePath()
    // cup body: flat rim, rounded bottom
    let cup = CGMutablePath()
    cup.move(to: CGPoint(x: 280 * u, y: 600 * u))
    cup.addLine(to: CGPoint(x: 680 * u, y: 600 * u))
    cup.addCurve(to: CGPoint(x: 540 * u, y: 290 * u),
                 control1: CGPoint(x: 680 * u, y: 420 * u), control2: CGPoint(x: 640 * u, y: 290 * u))
    cup.addLine(to: CGPoint(x: 420 * u, y: 290 * u))
    cup.addCurve(to: CGPoint(x: 280 * u, y: 600 * u),
                 control1: CGPoint(x: 320 * u, y: 290 * u), control2: CGPoint(x: 280 * u, y: 420 * u))
    cup.closeSubpath()
    ctx.addPath(cup); ctx.setFillColor(white); ctx.fillPath()
    ctx.endTransparencyLayer()
    ctx.restoreGState()

    // espresso crema visible at the rim
    let crema = CGPath(ellipseIn: CGRect(x: 300 * u, y: 575 * u, width: 360 * u, height: 46 * u), transform: nil)
    ctx.addPath(crema); ctx.setFillColor(col(0.55, 0.30, 0.15)); ctx.fillPath()

    // steam
    ctx.setStrokeColor(col(1, 1, 1, 0.9)); ctx.setLineWidth(30 * u); ctx.setLineCap(.round)
    for x in [400.0, 480.0, 560.0] as [CGFloat] {
        ctx.move(to: CGPoint(x: x * u, y: 660 * u))
        ctx.addCurve(to: CGPoint(x: x * u, y: 820 * u),
                     control1: CGPoint(x: (x - 45) * u, y: 715 * u), control2: CGPoint(x: (x + 45) * u, y: 765 * u))
        ctx.strokePath()
    }
    ctx.restoreGState()

    // rim highlight
    ctx.addPath(path); ctx.setStrokeColor(col(1, 1, 1, 0.25)); ctx.setLineWidth(3 * u); ctx.strokePath()
    img.unlockFocus()
    return img
}

func writePNG(_ img: NSImage, px: Int, to url: URL) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    img.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let assets = root.appendingPathComponent("Assets")
let iconset = assets.appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
let master = draw(size: 1024)
for base in [16, 32, 128, 256, 512] {
    try writePNG(master, px: base, to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try writePNG(master, px: base * 2, to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try writePNG(master, px: 1024, to: assets.appendingPathComponent("AppIcon-preview.png"))
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", assets.appendingPathComponent("AppIcon.icns").path]
try p.run(); p.waitUntilExit()
print("done, iconutil exit \(p.terminationStatus)")
