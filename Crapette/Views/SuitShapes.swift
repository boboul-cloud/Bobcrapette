import SwiftUI

/// Les enseignes, dessinées à la main dans un carré unité puis mises
/// à l'échelle : elles restent nettes à toutes les tailles, sans images.

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let p = { (x: CGFloat, y: CGFloat) in
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
}

struct SpadeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let p = { (x: CGFloat, y: CGFloat) in
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        // Le cœur retourné : pointe en haut, lobes en bas.
        path.move(to: p(0.5, 0.0))
        path.addCurve(to: p(0.0, 0.60), control1: p(0.22, 0.18), control2: p(0.0, 0.40))
        path.addCurve(to: p(0.5, 0.78), control1: p(0.0, 0.86), control2: p(0.34, 0.94))
        path.addCurve(to: p(1.0, 0.60), control1: p(0.66, 0.94), control2: p(1.0, 0.86))
        path.addCurve(to: p(0.5, 0.0), control1: p(1.0, 0.40), control2: p(0.78, 0.18))
        path.closeSubpath()
        // La queue.
        path.move(to: p(0.5, 0.58))
        path.addCurve(to: p(0.26, 1.0), control1: p(0.52, 0.80), control2: p(0.40, 0.94))
        path.addLine(to: p(0.74, 1.0))
        path.addCurve(to: p(0.5, 0.58), control1: p(0.60, 0.94), control2: p(0.48, 0.80))
        path.closeSubpath()
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let p = { (x: CGFloat, y: CGFloat) in
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.5, 0.0))
        path.addQuadCurve(to: p(1.0, 0.5), control: p(0.80, 0.20))
        path.addQuadCurve(to: p(0.5, 1.0), control: p(0.80, 0.80))
        path.addQuadCurve(to: p(0.0, 0.5), control: p(0.20, 0.80))
        path.addQuadCurve(to: p(0.5, 0.0), control: p(0.20, 0.20))
        path.closeSubpath()
        return path
    }
}

struct ClubShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let p = { (x: CGFloat, y: CGFloat) in
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        let r: CGFloat = 0.27
        let d = 2 * r
        path.addEllipse(in: CGRect(origin: p(0.5 - r, 0.0),
                                   size: CGSize(width: d * rect.width, height: d * rect.height)))
        path.addEllipse(in: CGRect(origin: p(0.0, 0.34),
                                   size: CGSize(width: d * rect.width, height: d * rect.height)))
        path.addEllipse(in: CGRect(origin: p(1.0 - d, 0.34),
                                   size: CGSize(width: d * rect.width, height: d * rect.height)))
        path.move(to: p(0.5, 0.48))
        path.addCurve(to: p(0.26, 1.0), control1: p(0.52, 0.76), control2: p(0.40, 0.94))
        path.addLine(to: p(0.74, 1.0))
        path.addCurve(to: p(0.5, 0.48), control1: p(0.60, 0.94), control2: p(0.48, 0.76))
        path.closeSubpath()
        return path
    }
}

/// L'enseigne des atouts : une étoile à cinq branches.
struct StarShape: Shape {
    var innerRatio: CGFloat = 0.44

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        for step in 0..<10 {
            let radius = step.isMultiple(of: 2) ? outer : inner
            let angle = -CGFloat.pi / 2 + CGFloat(step) * .pi / 5
            let point = CGPoint(x: center.x + cos(angle) * radius,
                                y: center.y + sin(angle) * radius)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// L'enseigne correspondant à une famille. `tint` permet de la dessiner
/// dans une autre couleur que la sienne, pour les silhouettes en filigrane.
struct SuitPip: View {
    let family: Family
    var tint: Color?

    /// Version éclaircie, lisible en filigrane sur le tapis vert.
    static func ghostTint(for family: Family) -> Color {
        switch family.color {
        case .black: Color(white: 0.88)
        case .red: Color(red: 0.96, green: 0.58, blue: 0.60)
        case .gold: Color(red: 0.96, green: 0.82, blue: 0.48)
        }
    }

    var body: some View {
        Group {
            switch family {
            case .spades: SpadeShape()
            case .hearts: HeartShape()
            case .diamonds: DiamondShape()
            case .clubs: ClubShape()
            case .trumps: StarShape()
            }
        }
        .foregroundStyle(tint ?? Theme.ink(family.color))
    }
}
