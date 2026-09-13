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
///
/// Les proportions suivent celles d'une vraie carte à jouer, et c'est ce qui
/// garantit que rien ne se chevauche : l'index du coin tient dans un bandeau
/// étroit sur le bord, et le dessin central commence après ce bandeau.
struct CardView: View {

    // MARK: - Proportions, en fraction de la largeur de la carte

    /// Bandeau où s'inscrivent le rang et la petite enseigne du coin.
    private static let indexInset: CGFloat = 0.04
    private static let indexBand: CGFloat = 0.145
    /// Bord droit du bandeau : tout le reste du dessin commence après.
    private static var indexEdge: CGFloat { indexInset + indexBand }

    /// Colonnes d'enseignes, centrées à 30 %, 50 % et 70 % de la largeur.
    private static let pipColumnInset: CGFloat = 0.30
    private static let pipSize: CGFloat = 0.155
    /// Marge haute et basse des enseignes, en fraction de la *hauteur*.
    private static let pipRowInset: CGFloat = 0.16

    /// Panneau des figures et des atouts.
    private static let panelInsetX: CGFloat = 0.22
    private static let panelInsetY: CGFloat = 0.11

    // MARK: - Entrées

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
        .accessibilityElement(children: .ignore)
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

            cornerIndex(mirrored: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            cornerIndex(mirrored: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    /// Le rang et la petite enseigne, dans les coins opposés comme sur une
    /// vraie carte, pour qu'elle se lise dans les deux sens.
    private func cornerIndex(mirrored: Bool) -> some View {
        VStack(spacing: width * 0.01) {
            Text(label)
                .font(.system(size: width * (label.count > 1 ? 0.175 : 0.225),
                              weight: .bold, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            SuitPip(family: card.family)
                .frame(width: width * 0.105, height: width * 0.105)
        }
        .frame(width: width * Self.indexBand)
        .foregroundStyle(ink)
        .rotationEffect(.degrees(mirrored ? 180 : 0))
        .padding(width * Self.indexInset)
    }

    @ViewBuilder
    private var centre: some View {
        switch centreKind {
        case .medallion:
            trumpMedallion
                .padding(.horizontal, width * Self.panelInsetX)
                .padding(.vertical, height * Self.panelInsetY)
        case .court:
            courtPanel
                .padding(.horizontal, width * Self.panelInsetX)
                .padding(.vertical, height * Self.panelInsetY)
        case .ace:
            SuitPip(family: card.family)
                .frame(width: width * 0.42, height: width * 0.42)
        case .pips:
            pipLayout
                .padding(.horizontal, width * Self.pipColumnInset)
                .padding(.vertical, height * Self.pipRowInset)
        }
    }

    private enum CentreKind { case medallion, court, ace, pips }

    private var centreKind: CentreKind {
        if card.family.isTrump { return .medallion }
        if card.isCourt { return .court }
        if card.rank == 1 { return .ace }
        return .pips
    }

    // MARK: - Cartes numérales

    private var pipLayout: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.pipPositions(for: card.rank).enumerated()), id: \.offset) { _, spot in
                    SuitPip(family: card.family)
                        .frame(width: width * Self.pipSize, height: width * Self.pipSize)
                        // Comme sur une vraie carte, la moitié basse est à l'envers.
                        .rotationEffect(.degrees(spot.y > 0.52 ? 180 : 0))
                        .position(x: spot.x * geo.size.width, y: spot.y * geo.size.height)
                }
            }
        }
    }

    /// Disposition traditionnelle des enseignes, en coordonnées normalisées
    /// dans la zone centrale. `x` vaut 0, 0,5 ou 1 : les trois colonnes.
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
        panel(accent: ink) {
            VStack(spacing: 0) {
                SuitPip(family: card.family)
                    .frame(width: width * 0.12, height: width * 0.12)
                Spacer(minLength: 0)
                Text(label)
                    .font(.system(size: width * 0.38, weight: .semibold, design: .serif))
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Spacer(minLength: 0)
                SuitPip(family: card.family)
                    .frame(width: width * 0.12, height: width * 0.12)
                    .rotationEffect(.degrees(180))
            }
            .padding(.vertical, width * 0.06)
        }
    }

    // MARK: - Atouts

    /// Les atouts 1 et 21 sont les bouts : on leur donne un liseré double.
    private var isEndTrump: Bool {
        card.family.isTrump && (card.rank == 1 || card.rank == suitedTrumpTop)
    }

    private var suitedTrumpTop: Int { 21 }

    private var trumpMedallion: some View {
        panel(accent: Theme.gold, doubleBorder: isEndTrump) {
            VStack(spacing: 0) {
                StarShape()
                    .fill(Theme.gold)
                    .frame(width: width * 0.11, height: width * 0.11)
                Spacer(minLength: 0)
                Text("\(card.rank)")
                    .font(.system(size: width * (card.rank > 9 ? 0.32 : 0.38),
                                  weight: .bold, design: .serif))
                    .foregroundStyle(Theme.gold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Spacer(minLength: 0)
                StarShape()
                    .fill(Theme.gold)
                    .frame(width: width * 0.11, height: width * 0.11)
            }
            .padding(.vertical, width * 0.06)
        }
    }

    /// Le cadre commun aux figures et aux atouts.
    private func panel<Content: View>(accent: Color, doubleBorder: Bool = false,
                                      @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.06, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.13), accent.opacity(0.03)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: width * 0.06, style: .continuous)
                .strokeBorder(accent.opacity(0.45), lineWidth: width * 0.015)
            if doubleBorder {
                RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
                    .strokeBorder(accent.opacity(0.28), lineWidth: width * 0.008)
                    .padding(width * 0.035)
            }
            content()
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
        }
        .padding(30)
    }
}
