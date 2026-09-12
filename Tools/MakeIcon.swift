// Génère l'icône de l'application : deux cartes en éventail sur le tapis,
// une couleur et un atout, pour dire d'un coup d'œil « crapette au tarot ».
// Usage : swift Tools/MakeIcon.swift <dossier de sortie>

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
}

let feltTop = rgb(0.086, 0.357, 0.267)
let feltBottom = rgb(0.020, 0.098, 0.078)
let ivory = rgb(0.980, 0.965, 0.933)
let cardRed = rgb(0.737, 0.114, 0.157)
let cardGold = rgb(0.733, 0.529, 0.106)

func heartPath(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    func p(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }
    path.move(to: p(0.5, 1.0))
    path.addCurve(to: p(0.0, 0.36), control1: p(0.22, 0.82), control2: p(0.0, 0.60))
    path.addCurve(to: p(0.5, 0.20), control1: p(0.0, 0.08), control2: p(0.34, 0.0))
    path.addCurve(to: p(1.0, 0.36), control1: p(0.66, 0.0), control2: p(1.0, 0.08))
    path.addCurve(to: p(0.5, 1.0), control1: p(1.0, 0.60), control2: p(0.78, 0.82))
    path.closeSubpath()
    return path
}

func starPath(in rect: CGRect, innerRatio: Double = 0.44) -> CGPath {
    let path = CGMutablePath()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) / 2
    for step in 0..<10 {
        let radius = step % 2 == 0 ? outer : outer * innerRatio
        let angle = -Double.pi / 2 + Double(step) * .pi / 5
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        step == 0 ? path.move(to: point) : path.addLine(to: point)
    }
    path.closeSubpath()
    return path
}

func drawCard(_ ctx: CGContext, center: CGPoint, size: CGSize, angle: Double,
              pip: (CGRect) -> CGPath, pipColor: CGColor, unit: Double) {
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: angle * .pi / 180)

    let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
    let body = CGPath(roundedRect: rect, cornerWidth: size.width * 0.10,
                      cornerHeight: size.width * 0.10, transform: nil)

    ctx.setShadow(offset: CGSize(width: 0, height: unit * 0.016),
                  blur: unit * 0.045, color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.addPath(body)
    ctx.setFillColor(ivory)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // Liseré intérieur
    ctx.addPath(CGPath(roundedRect: rect.insetBy(dx: size.width * 0.075, dy: size.width * 0.075),
                       cornerWidth: size.width * 0.07, cornerHeight: size.width * 0.07, transform: nil))
    ctx.setStrokeColor(pipColor.copy(alpha: 0.28)!)
    ctx.setLineWidth(unit * 0.008)
    ctx.strokePath()

    let pipSize = size.width * 0.46
    ctx.addPath(pip(CGRect(x: -pipSize / 2, y: -pipSize / 2, width: pipSize, height: pipSize)))
    ctx.setFillColor(pipColor)
    ctx.fillPath()

    ctx.restoreGState()
}

func renderIcon(side: Int) -> CGImage? {
    let unit = Double(side)
    guard let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)

    // Le tapis
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: [feltTop, feltBottom] as CFArray,
                                 locations: [0, 1]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: unit),
                               end: CGPoint(x: 0, y: 0), options: [])
    }

    // Les deux cartes, légèrement en éventail.
    let cardSize = CGSize(width: unit * 0.40, height: unit * 0.40 * 1.47)
    drawCard(ctx, center: CGPoint(x: unit * 0.405, y: unit * 0.47), size: cardSize,
             angle: 15, pip: heartPath, pipColor: cardRed, unit: unit)
    drawCard(ctx, center: CGPoint(x: unit * 0.600, y: unit * 0.51), size: cardSize,
             angle: -11, pip: { starPath(in: $0) }, pipColor: cardGold, unit: unit)

    return ctx.makeImage()
}

for side in [16, 32, 64, 128, 256, 512, 1024] {
    guard let image = renderIcon(side: side) else { continue }
    let url = URL(fileURLWithPath: outputDirectory).appendingPathComponent("icon-\(side).png")
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { continue }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("icon-\(side).png")
}
