import AppKit

let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/branding/thumbler_app_icon_master.png"
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
  fputs("Failed to create graphics context\n", stderr)
  exit(1)
}

context.translateBy(x: 0, y: size.height)
context.scaleBy(x: 1, y: -1)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
  NSColor(calibratedRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

let background = NSRect(origin: .zero, size: size)
let baseGradient = NSGradient(
  colors: [rgb(18, 21, 28), rgb(39, 45, 57), rgb(14, 16, 22)],
  atLocations: [0.0, 0.45, 1.0],
  colorSpace: .deviceRGB
)!
baseGradient.draw(in: background, relativeCenterPosition: NSPoint(x: 0, y: 0))

let centerGlow = NSGradient(
  starting: rgb(240, 197, 111, 0.16),
  ending: rgb(240, 197, 111, 0.0)
)!
centerGlow.draw(
  in: NSBezierPath(ovalIn: NSRect(x: 180, y: 180, width: 664, height: 664)),
  relativeCenterPosition: NSPoint(x: 0, y: 0)
)

func neonStroke(_ path: NSBezierPath, color: NSColor, coreWidth: CGFloat) {
  let glowWidths: [CGFloat] = [coreWidth * 3.8, coreWidth * 2.4, coreWidth * 1.5]
  let glowAlphas: [CGFloat] = [0.10, 0.16, 0.24]

  for (width, alpha) in zip(glowWidths, glowAlphas) {
    context.saveGState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = width * 2.2
    shadow.shadowColor = color.withAlphaComponent(alpha)
    shadow.shadowOffset = .zero
    shadow.set()
    path.lineWidth = width
    color.withAlphaComponent(alpha).setStroke()
    path.stroke()
    context.restoreGState()
  }

  path.lineWidth = coreWidth + 8
  color.withAlphaComponent(0.34).setStroke()
  path.stroke()

  path.lineWidth = coreWidth
  color.setStroke()
  path.stroke()
}

let neon = rgb(246, 207, 123)

let outerBulb = NSBezierPath()
outerBulb.move(to: CGPoint(x: 286, y: 287))
outerBulb.curve(
  to: CGPoint(x: 512, y: 858),
  controlPoint1: CGPoint(x: 214, y: 430),
  controlPoint2: CGPoint(x: 256, y: 772)
)
outerBulb.curve(
  to: CGPoint(x: 738, y: 287),
  controlPoint1: CGPoint(x: 768, y: 772),
  controlPoint2: CGPoint(x: 810, y: 430)
)

let innerBulb = NSBezierPath()
innerBulb.move(to: CGPoint(x: 324, y: 320))
innerBulb.curve(
  to: CGPoint(x: 512, y: 818),
  controlPoint1: CGPoint(x: 264, y: 444),
  controlPoint2: CGPoint(x: 300, y: 735)
)
innerBulb.curve(
  to: CGPoint(x: 700, y: 320),
  controlPoint1: CGPoint(x: 724, y: 735),
  controlPoint2: CGPoint(x: 760, y: 444)
)

let neckBase = NSBezierPath(roundedRect: NSRect(x: 394, y: 744, width: 236, height: 28), xRadius: 14, yRadius: 14)
let neckMid = NSBezierPath(roundedRect: NSRect(x: 382, y: 808, width: 260, height: 32), xRadius: 16, yRadius: 16)
let neckBottom = NSBezierPath()
neckBottom.move(to: CGPoint(x: 430, y: 846))
neckBottom.curve(
  to: CGPoint(x: 594, y: 846),
  controlPoint1: CGPoint(x: 468, y: 930),
  controlPoint2: CGPoint(x: 556, y: 930)
)

let wrist = NSBezierPath(roundedRect: NSRect(x: 350, y: 414, width: 66, height: 178), xRadius: 16, yRadius: 16)

let thumb = NSBezierPath()
thumb.move(to: CGPoint(x: 416, y: 592))
thumb.line(to: CGPoint(x: 416, y: 480))
thumb.curve(
  to: CGPoint(x: 494, y: 408),
  controlPoint1: CGPoint(x: 416, y: 444),
  controlPoint2: CGPoint(x: 452, y: 408)
)
thumb.line(to: CGPoint(x: 520, y: 408))
thumb.curve(
  to: CGPoint(x: 556, y: 366),
  controlPoint1: CGPoint(x: 544, y: 408),
  controlPoint2: CGPoint(x: 556, y: 392)
)
thumb.line(to: CGPoint(x: 556, y: 280))
thumb.curve(
  to: CGPoint(x: 590, y: 250),
  controlPoint1: CGPoint(x: 556, y: 262),
  controlPoint2: CGPoint(x: 570, y: 250)
)
thumb.curve(
  to: CGPoint(x: 624, y: 284),
  controlPoint1: CGPoint(x: 610, y: 250),
  controlPoint2: CGPoint(x: 624, y: 264)
)
thumb.line(to: CGPoint(x: 624, y: 404))
thumb.line(to: CGPoint(x: 726, y: 404))
thumb.curve(
  to: CGPoint(x: 774, y: 454),
  controlPoint1: CGPoint(x: 752, y: 404),
  controlPoint2: CGPoint(x: 774, y: 426)
)
thumb.curve(
  to: CGPoint(x: 738, y: 490),
  controlPoint1: CGPoint(x: 774, y: 474),
  controlPoint2: CGPoint(x: 760, y: 488)
)

let knuckles1 = NSBezierPath()
knuckles1.move(to: CGPoint(x: 738, y: 490))
knuckles1.curve(
  to: CGPoint(x: 770, y: 526),
  controlPoint1: CGPoint(x: 762, y: 492),
  controlPoint2: CGPoint(x: 776, y: 508)
)
knuckles1.curve(
  to: CGPoint(x: 724, y: 556),
  controlPoint1: CGPoint(x: 764, y: 548),
  controlPoint2: CGPoint(x: 748, y: 558)
)

let knuckles2 = NSBezierPath()
knuckles2.move(to: CGPoint(x: 724, y: 556))
knuckles2.curve(
  to: CGPoint(x: 756, y: 592),
  controlPoint1: CGPoint(x: 748, y: 558),
  controlPoint2: CGPoint(x: 762, y: 574)
)
knuckles2.curve(
  to: CGPoint(x: 706, y: 622),
  controlPoint1: CGPoint(x: 750, y: 614),
  controlPoint2: CGPoint(x: 732, y: 624)
)

let palmBottom = NSBezierPath()
palmBottom.move(to: CGPoint(x: 706, y: 622))
palmBottom.curve(
  to: CGPoint(x: 502, y: 622),
  controlPoint1: CGPoint(x: 660, y: 622),
  controlPoint2: CGPoint(x: 576, y: 624)
)
palmBottom.curve(
  to: CGPoint(x: 416, y: 592),
  controlPoint1: CGPoint(x: 466, y: 620),
  controlPoint2: CGPoint(x: 432, y: 608)
)

let innerWrist = NSBezierPath(roundedRect: NSRect(x: 372, y: 440, width: 38, height: 144), xRadius: 8, yRadius: 8)

let filamentLeft = NSBezierPath()
filamentLeft.move(to: CGPoint(x: 468, y: 594))
filamentLeft.curve(
  to: CGPoint(x: 490, y: 744),
  controlPoint1: CGPoint(x: 476, y: 646),
  controlPoint2: CGPoint(x: 488, y: 700)
)

let filamentRight = NSBezierPath()
filamentRight.move(to: CGPoint(x: 562, y: 594))
filamentRight.curve(
  to: CGPoint(x: 540, y: 744),
  controlPoint1: CGPoint(x: 554, y: 646),
  controlPoint2: CGPoint(x: 542, y: 700)
)

neonStroke(outerBulb, color: neon, coreWidth: 16)
neonStroke(innerBulb, color: neon, coreWidth: 10)
neonStroke(neckBase, color: neon, coreWidth: 10)
neonStroke(neckMid, color: neon, coreWidth: 10)
neonStroke(neckBottom, color: neon, coreWidth: 10)
neonStroke(wrist, color: neon, coreWidth: 12)
neonStroke(thumb, color: neon, coreWidth: 12)
neonStroke(knuckles1, color: neon, coreWidth: 12)
neonStroke(knuckles2, color: neon, coreWidth: 12)
neonStroke(palmBottom, color: neon, coreWidth: 12)
neonStroke(innerWrist, color: neon, coreWidth: 8)
neonStroke(filamentLeft, color: neon, coreWidth: 10)
neonStroke(filamentRight, color: neon, coreWidth: 10)

let sparkle = NSBezierPath()
sparkle.move(to: CGPoint(x: 886, y: 152))
sparkle.line(to: CGPoint(x: 896, y: 178))
sparkle.line(to: CGPoint(x: 922, y: 188))
sparkle.line(to: CGPoint(x: 896, y: 198))
sparkle.line(to: CGPoint(x: 886, y: 224))
sparkle.line(to: CGPoint(x: 876, y: 198))
sparkle.line(to: CGPoint(x: 850, y: 188))
sparkle.line(to: CGPoint(x: 876, y: 178))
sparkle.close()
neonStroke(sparkle, color: neon.withAlphaComponent(0.45), coreWidth: 3)

image.unlockFocus()

guard
  let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let data = bitmap.representation(using: .png, properties: [:])
else {
  fputs("Failed to encode PNG\n", stderr)
  exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
  at: outputURL.deletingLastPathComponent(),
  withIntermediateDirectories: true,
  attributes: nil
)
try data.write(to: outputURL)
print("Wrote \(outputURL.path)")
