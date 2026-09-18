import Cocoa

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
func c(_ h: Int, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 255)/255, green: CGFloat((h >> 8) & 255)/255, blue: CGFloat(h & 255)/255, alpha: a)
}
// لوح التطبيق بمقاس شبكة أيقونات ماك (824 داخل 1024)
let inset: CGFloat = 100
let body = NSRect(x: inset, y: inset, width: S - 2*inset, height: S - 2*inset)
let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
NSGraphicsContext.current!.saveGraphicsState()
let sh = NSShadow(); sh.shadowColor = c(0x000000, 0.45); sh.shadowBlurRadius = 28; sh.shadowOffset = NSSize(width: 0, height: -12); sh.set()
NSGradient(starting: c(0x1A1E19), ending: c(0x070907))!.draw(in: shape, angle: -90)
NSGraphicsContext.current!.restoreGraphicsState()
c(0x2A3027).setStroke(); shape.lineWidth = 3; shape.stroke()

shape.addClip()
// أسطر النص: فوق الخط باهتة، عند الخط واضحة، تحته متوسطة — محاذاة يمين
let right = body.maxX - 150
let lines: [(y: CGFloat, w: CGFloat, alpha: CGFloat, h: CGFloat)] = [
    (760, 380, 0.16, 38), (680, 470, 0.22, 38),
    (538, 560, 1.0, 58),
    (420, 430, 0.55, 42), (340, 510, 0.40, 42), (260, 330, 0.28, 42)
]
for l in lines {
    let r = NSRect(x: right - l.w, y: l.y, width: l.w, height: l.h)
    c(0xF3F1EC, l.alpha).setFill()
    NSBezierPath(roundedRect: r, xRadius: l.h/2, yRadius: l.h/2).fill()
}
// خط القراءة الذهبي مع المثلثين
let ly: CGFloat = 512
c(0xD8A23B, 0.75).setFill()
NSRect(x: body.minX, y: ly - 4, width: body.width, height: 8).fill()
c(0xD8A23B).setFill()
let t1 = NSBezierPath(); t1.move(to: NSPoint(x: body.minX, y: ly - 38)); t1.line(to: NSPoint(x: body.minX + 58, y: ly)); t1.line(to: NSPoint(x: body.minX, y: ly + 38)); t1.close(); t1.fill()
let t2 = NSBezierPath(); t2.move(to: NSPoint(x: body.maxX, y: ly - 38)); t2.line(to: NSPoint(x: body.maxX - 58, y: ly)); t2.line(to: NSPoint(x: body.maxX, y: ly + 38)); t2.close(); t2.fill()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
