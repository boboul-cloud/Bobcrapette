import SwiftUI

/// Le quadrillage du dos des cartes.
struct LatticePattern: Shape {
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX + rect.height {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.maxY))
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += spacing
        }
        return path
    }
}

/// Une carte, dessinée entièrement en vectoriel : elle reste nette de
/// l'iPhone au Mac et ne coûte aucune image au projet.
struct CardView: View {
    let card: Card
    let faceUp: Bool
    let suitedRanks: Int
    let width: CGFloat
    var emphasis: CardEmphasis = .none

    private var height: CGFloat { width * Theme.cardHeight / Theme.cardWidth }
    private var radius: CGFloat { Theme.cornerRadius(for: width) }
    private var ink: Color { Theme.ink(card.family.color) }
    private var label: String { card.label(suitedRanks: suitedRanks) }

    var body: some View {
        ZStack {
            if faceUp { face } else { back }
            if let color = emphasis.color {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(color, lineWidth: width * 0.05)
                    .shadow(color: color.opacity(0.75), radius: width * 0.14)
            }
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.34), radius: width * 0.055, x: 0, y: width * 0.022)
        .accessibilityLabel(faceUp ? card.fullName(suitedRanks: suitedRanks) : "Carte face cachée")
    }

    // MARK: - La face

    private var face: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: [Theme.cardFace, Theme.cardFaceShade],
                                     startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Theme.cardEdge.opacity(0.22), lineWidth: width * 0.012)

            centre
                .padding(.horizontal, width * 0.215)
                .padding(.vertical, height * 0.085)

            cornerIndex(mirrored: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            cornerIndex(mirrored: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private func cornerIndex(mirrored: Bool) -> some View {
        VStack(spacing: width * 0.02) {
            Text(label)
                .font(.system(size: width * (label.count > 1 ? 0.24 : 0.29),
                              weight: .bold, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            SuitPip(family: card.family)
                .frame(width: width * 0.155, height: width * 0.155)
        }
        .foregroundStyle(ink)
        .rotationEffect(.degrees(mirrored ? 180 : 0))
        .padding(.horizontal, width * 0.055)
        .padding(.vertical, width * 0.05)
    }

    @ViewBuilder
    private var centre: some View {
        if card.family.isTrump {
            trumpMedallion
        } else if card.isCourt {
            courtPanel
        } else if card.rank == 1 {
            SuitPip(family: card.family)
                .frame(width: width * 0.42, height: width * 0.42)
        } else {
            pipLayout
        }
    }

    // MARK: - Cartes numérales

    private var pipLayout: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.pipPositions(for: card.rank).enumerated()), id: \.offset) { _, spot in
                    SuitPip(family: card.family)
                        .frame(width: width * 0.185, height: width * 0.185)
                        // Comme sur une vraie carte, la moitié basse est à l'envers.
                        .rotationEffect(.degrees(spot.y > 0.52 ? 180 : 0))
                        .position(x: spot.x * geo.size.width, y: spot.y * geo.size.height)
                }
            }
        }
    }

    /// Disposition traditionnelle des enseignes, en coordonnées normalisées.
    static func pipPositions(for rank: Int) -> [CGPoint] {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        let third = 1.0 / 3.0, sixth = 1.0 / 6.0
        switch rank {
        case 2: return [p(0.5, 0), p(0.5, 1)]
        case 3: return [p(0.5, 0), p(0.5, 0.5), p(0.5, 1)]
        case 4: return [p(0, 0), p(1, 0), p(0, 1), p(1, 1)]
        case 5: return [p(0, 0), p(1, 0), p(0.5, 0.5), p(0, 1), p(1, 1)]
        case 6: return [p(0, 0), p(1, 0), p(0, 0.5), p(1, 0.5), p(0, 1), p(1, 1)]
        case 7: return [p(0, 0), p(1, 0), p(0.5, 0.25), p(0, 0.5), p(1, 0.5), p(0, 1), p(1, 1)]
        case 8: return [p(0, 0), p(1, 0), p(0.5, 0.25), p(0, 0.5), p(1, 0.5),
                        p(0.5, 0.75), p(0, 1), p(1, 1)]
        case 9: return [p(0, 0), p(1, 0), p(0, third), p(1, third), p(0.5, 0.5),
                        p(0, 2 * third), p(1, 2 * third), p(0, 1), p(1, 1)]
        case 10: return [p(0, 0), p(1, 0), p(0.5, sixth), p(0, third), p(1, third),
                         p(0, 2 * third), p(1, 2 * third), p(0.5, 5 * sixth), p(0, 1), p(1, 1)]
        default: return [p(0.5, 0.5)]
        }
    }

    // MARK: - Figures

    private var courtPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.06, style: .continuous)
                .fill(LinearGradient(colors: [ink.opacity(0.13), ink.opacity(0.03)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: width * 0.06, style: .continuous)
                .strokeBorder(ink.opacity(0.42), lineWidth: width * 0.016)
            RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
                .strokeBorder(ink.opacity(0.22), lineWidth: width * 0.008)
                .padding(width * 0.035)

            VStack(spacing: 0) {
                SuitPip(family: card.family)
                    .frame(width: width * 0.15, height: width * 0.15)
                Spacer(minLength: 0)
                Text(label)
                    .font(.system(size: width * 0.44, weight: .semibold, design: .serif))
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Spacer(minLength: 0)
                SuitPip(family: card.family)
                    .frame(width: width * 0.15, height: width * 0.15)
                    .rotationEffect(.degrees(180))
            }
            .padding(.vertical, width * 0.09)
        }
    }

    // MARK: - Atouts

    /// Les atouts 1 et 21 sont les bouts : on leur donne un liseré double.
    private var isEndTrump: Bool {
        card.family.isTrump && (card.rank == 1 || card.rank == 21)
    }

    private var trumpMedallion: some View {
        ZStack {
            StarShape(innerRatio: 0.52)
                .fill(Theme.gold.opacity(0.14))
            Circle()
                .strokeBorder(Theme.gold.opacity(0.5), lineWidth: width * 0.018)
                .padding(width * 0.03)
            if isEndTrump {
                Circle()
                    .strokeBorder(Theme.gold.opacity(0.34), lineWidth: width * 0.010)
                    .padding(width * 0.085)
            }
            Text("\(card.rank)")
                .font(.system(size: width * 0.42, weight: .bold, design: .serif))
                .foregroundStyle(Theme.gold)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }

    // MARK: - Le dos

    private var back: some View {
        let colors = Theme.backColors(for: card.deck)
        return ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: [colors.base, colors.base.opacity(0.78)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            LatticePattern(spacing: width * 0.17)
                .stroke(colors.line.opacity(0.6), lineWidth: width * 0.011)
                .clipShape(RoundedRectangle(cornerRadius: radius * 0.7, style: .continuous))
                .padding(width * 0.07)
            RoundedRectangle(cornerRadius: radius * 0.7, style: .continuous)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: width * 0.014)
                .padding(width * 0.07)
            Circle()
                .fill(colors.base.opacity(0.85))
                .frame(width: width * 0.36, height: width * 0.36)
            StarShape()
                .fill(Color.white.opacity(0.28))
                .frame(width: width * 0.21, height: width * 0.21)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.28), lineWidth: width * 0.012)
        }
    }
}

#Preview("Cartes") {
    let ranks: [(Family, Int)] = [(.hearts, 1), (.spades, 7), (.diamonds, 10),
                                  (.clubs, 11), (.hearts, 12), (.spades, 14),
                                  (.trumps, 1), (.trumps, 13), (.trumps, 21)]
    return ZStack {
        Rectangle().fill(Theme.felt).ignoresSafeArea()
        VStack(spacing: 14) {
            ForEach(0..<3) { row in
                HStack(spacing: 14) {
                    ForEach(0..<3) { column in
                        let item = ranks[row * 3 + column]
                        CardView(card: Card(family: item.0, rank: item.1, deck: .south),
                                 faceUp: true, suitedRanks: 14, width: 96)
                    }
                }
            }
            HStack(spacing: 14) {
                CardView(card: Card(family: .spades, rank: 1, deck: .south),
                         faceUp: false, suitedRanks: 14, width: 96)
                CardView(card: Card(family: .spades, rank: 1, deck: .north),
                         faceUp: false, suitedRanks: 14, width: 96)
            }
        }
        .padding(30)
    }
}
