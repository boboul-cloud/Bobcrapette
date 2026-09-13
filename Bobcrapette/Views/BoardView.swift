import SwiftUI

/// Le tapis. Toutes les cartes visibles sont placées en coordonnées absolues :
/// quand l'état change, SwiftUI interpole les positions, ce qui suffit à
/// animer les coups et la distribution sans aucun code d'animation par carte.
///
/// Le placement se fait avec `position`, qui pose réellement la vue dans le
/// repère du parent. `offset` ne déplacerait que le dessin : le cadre de la
/// vue resterait au point de départ, et ni les touches ni l'accessibilité ne
/// suivraient la carte là où le joueur la voit.
struct BoardView: View {
    @Environment(GameStore.self) private var store

    @State private var drag: DragInfo?

    /// Repère fixe du tapis. Le glissement doit s'y mesurer : dans le repère
    /// de la carte, qui suit le doigt, le déplacement se replierait sur
    /// lui-même et la carte ne bougerait jamais vraiment.
    private static let boardSpace = "crapette.tapis"

    struct DragInfo: Equatable {
        var source: MoveSource
        var translation: CGSize
    }

    private var animation: Animation {
        .spring(response: 0.34, dampingFraction: 0.78)
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = BoardLayout.make(for: geometry.size, variant: store.state.variant)
            let scale = layout.scale(in: geometry.size)

            ZStack(alignment: .topLeading) {
                // Cale le ZStack sur la taille du tapis. Les décalages ne
                // comptent pas dans la mise en page : sans cette cale, le
                // ZStack ne mesure qu'une carte et les autres tombent hors
                // de ses limites, où elles ne reçoivent plus les gestes.
                Color.clear
                    .frame(width: layout.boardSize.width * scale,
                           height: layout.boardSize.height * scale)
                    .allowsHitTesting(false)
                slotsLayer(layout, scale)
                cardsLayer(layout, scale)
                labelsLayer(layout, scale)
            }
            // Le contenu est posé en coordonnées absolues depuis le coin
            // haut-gauche : le cadre doit s'y aligner, pas centrer.
            .frame(width: layout.boardSize.width * scale,
                   height: layout.boardSize.height * scale,
                   alignment: .topLeading)
            .coordinateSpace(.named(Self.boardSpace))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(animation, value: store.state)
        }
    }

    // MARK: - Emplacements vides

    private func slotsLayer(_ layout: BoardLayout, _ scale: CGFloat) -> some View {
        ForEach(allPiles(layout), id: \.self) { pile in
            let frame = layout.slot(pile)
            SlotView(
                pile: pile,
                state: store.state,
                isTarget: store.highlightedTargets.contains(pile),
                width: scale
            )
            .contentShape(Rectangle())
            .accessibilityIdentifier("slot-\(Self.identifier(for: pile))")
            .accessibilityAddTraits(.isButton)
            .onTapGesture { store.tap(pile) }
            .position(x: frame.midX * scale, y: frame.midY * scale)
            .zIndex(0)
        }
    }

    private func allPiles(_ layout: BoardLayout) -> [PileRef] {
        var piles: [PileRef] = []
        for side in Side.allCases {
            piles.append(contentsOf: [.stock(side), .waste(side), .crapette(side)])
        }
        piles.append(contentsOf: (0..<store.state.tableau.count).map { PileRef.tableau($0) })
        piles.append(contentsOf: (0..<store.state.foundations.count).map { PileRef.foundation($0) })
        return piles
    }

    // MARK: - Les cartes

    private func cardsLayer(_ layout: BoardLayout, _ scale: CGFloat) -> some View {
        ForEach(placedCards(layout)) { placed in
            let dragging = isDragging(placed)
            CardView(
                card: placed.card,
                faceUp: placed.faceUp,
                suitedRanks: store.state.variant.suitedRanks,
                width: scale,
                emphasis: emphasis(for: placed)
            )
            .contentShape(Rectangle())
            .accessibilityIdentifier(placed.isTop ? "top-\(Self.identifier(for: placed.pile))" : "")
            .accessibilityAddTraits(isSelected(placed) ? [.isSelected, .isButton] : .isButton)
            .gesture(cardGesture(placed, layout: layout, scale: scale))
            .scaleEffect(dragging ? 1.06 : 1)
            .position(
                x: placed.frame.midX * scale + (dragging ? drag?.translation.width ?? 0 : 0),
                y: placed.frame.midY * scale + (dragging ? drag?.translation.height ?? 0 : 0)
            )
            .zIndex(dragging ? 10_000 : placed.zIndex)
        }
    }

    private func isSelected(_ placed: PlacedCard) -> Bool {
        placed.isTop && store.selection?.pile == placed.pile && store.canHumanAct
    }

    /// Identifiant stable d'un paquet, pour l'accessibilité et les tests.
    static func identifier(for pile: PileRef) -> String {
        switch pile {
        case .stock(let side): "stock-\(side == .south ? "south" : "north")"
        case .waste(let side): "waste-\(side == .south ? "south" : "north")"
        case .crapette(let side): "crapette-\(side == .south ? "south" : "north")"
        case .tableau(let index): "tableau-\(index)"
        case .foundation(let index): "foundation-\(index)"
        }
    }

    private func isDragging(_ placed: PlacedCard) -> Bool {
        guard let drag, placed.isTop else { return false }
        return drag.source.pile == placed.pile
    }

    /// Tape et glissement dans un seul geste : au-delà d'un seuil le doigt
    /// emmène la carte, en deçà le relâchement vaut une tape. Deux
    /// reconnaisseurs séparés se disputeraient le toucher.
    private func cardGesture(_ placed: PlacedCard, layout: BoardLayout, scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.boardSpace))
            .onChanged { value in
                guard placed.isDraggable, let source = placed.source else { return }
                if drag == nil {
                    guard hypot(value.translation.width, value.translation.height) > scale * 0.10
                    else { return }
                    drag = DragInfo(source: source, translation: value.translation)
                    store.selection = source
                } else {
                    drag?.translation = value.translation
                }
            }
            .onEnded { value in
                let travelled = hypot(value.translation.width, value.translation.height)
                let source = drag?.source ?? placed.source

                // Doigt resté sur place : c'est une tape.
                guard travelled > scale * 0.16, placed.isDraggable, let source else {
                    withAnimation(animation) { drag = nil }
                    if travelled <= scale * 0.16 { store.tap(placed.pile) }
                    return
                }

                // Le point de chute, ramené aux coordonnées du plan.
                let dropped = CGPoint(
                    x: placed.frame.midX + value.translation.width / scale,
                    y: placed.frame.midY + value.translation.height / scale
                )
                let target = layout.dropTargets(for: store.state)
                    .first { $0.area.contains(dropped) }?.pile

                withAnimation(animation) {
                    if let target {
                        store.drop(from: source, onto: target)
                    } else {
                        store.selection = nil
                    }
                    drag = nil
                }
            }
    }

    private func emphasis(for placed: PlacedCard) -> CardEmphasis {
        guard placed.isTop else { return .none }
        if store.selection?.pile == placed.pile && store.canHumanAct { return .selected }
        if store.hintMove?.source.pile == placed.pile { return .hint }
        if store.obligationPiles.contains(placed.pile) { return .obligation }
        if let move = store.lastOpponentMove,
           move.target.pile(playedBy: .north) == placed.pile { return .opponentTrace }
        return .none
    }

    // MARK: - Étiquettes et compteurs

    private func labelsLayer(_ layout: BoardLayout, _ scale: CGFloat) -> some View {
        ForEach(labelledPiles, id: \.self) { pile in
            let frame = layout.slot(pile)
            let above = isNorth(pile)
            PileCaption(title: caption(for: pile), count: store.state.cards(in: pile).count, width: scale)
                .frame(width: scale * 1.6)
                .allowsHitTesting(false)
                .position(
                    x: frame.midX * scale,
                    y: above ? (frame.minY * scale - scale * 0.20)
                             : (frame.maxY * scale + scale * 0.20)
                )
                .zIndex(9_000)
        }
    }

    private var labelledPiles: [PileRef] {
        Side.allCases.flatMap { [PileRef.stock($0), .waste($0), .crapette($0)] }
    }

    private func isNorth(_ pile: PileRef) -> Bool {
        switch pile {
        case .stock(let side), .waste(let side), .crapette(let side): side == .north
        default: false
        }
    }

    private func caption(for pile: PileRef) -> String {
        switch pile {
        case .stock: "Talon"
        case .waste: "Défausse"
        case .crapette: "Crapette"
        default: ""
        }
    }

    // MARK: - Quelles cartes dessiner

    struct PlacedCard: Identifiable {
        let id: Int
        let card: Card
        let pile: PileRef
        let frame: CGRect
        let faceUp: Bool
        let zIndex: Double
        let isTop: Bool
        let source: MoveSource?
        let isDraggable: Bool
    }

    /// On ne dessine que ce qui se voit : quelques cartes au sommet des
    /// paquets empilés, et toutes celles des colonnes, étalées en éventail.
    private func placedCards(_ layout: BoardLayout) -> [PlacedCard] {
        let state = store.state
        var result: [PlacedCard] = []

        func add(_ pile: PileRef, visibleDepth: Int, faceUp: (Int, Int) -> Bool,
                 zBase: Double, source: MoveSource?) {
            let cards = state.cards(in: pile)
            guard !cards.isEmpty else { return }
            let first = max(0, cards.count - visibleDepth)
            for index in first..<cards.count {
                let isTop = index == cards.count - 1
                let draggable = isTop && source != nil && store.canHumanAct
                    && store.movableSources.contains(pile)
                result.append(PlacedCard(
                    id: cards[index].id,
                    card: cards[index],
                    pile: pile,
                    frame: layout.position(of: pile, index: index, count: cards.count),
                    faceUp: faceUp(index, cards.count),
                    zIndex: zBase + Double(index),
                    isTop: isTop,
                    source: source,
                    isDraggable: draggable
                ))
            }
        }

        for side in Side.allCases {
            let mine = side == .south
            // Le talon reste face cachée ; on n'en dessine que l'épaisseur.
            add(.stock(side), visibleDepth: 4, faceUp: { _, _ in false },
                zBase: 300, source: nil)
            // La défausse ne montre que sa carte du dessus.
            add(.waste(side), visibleDepth: 3, faceUp: { index, count in index == count - 1 },
                zBase: 320, source: mine ? .waste(.south) : nil)
            // La crapette : dessus retourné, le reste face cachée.
            add(.crapette(side), visibleDepth: 4, faceUp: { index, count in index == count - 1 },
                zBase: 340, source: mine ? .crapette(.south) : nil)
        }

        for index in 0..<state.foundations.count {
            add(.foundation(index), visibleDepth: 2, faceUp: { _, _ in true },
                zBase: 100, source: nil)
        }

        for index in 0..<state.tableau.count {
            add(.tableau(index), visibleDepth: state.tableau[index].count,
                faceUp: { _, _ in true }, zBase: 200 + Double(index) * 40,
                source: .tableau(index))
        }

        return result
    }
}

// MARK: - Emplacement vide

private struct SlotView: View {
    let pile: PileRef
    let state: GameState
    let isTarget: Bool
    let width: CGFloat

    private var height: CGFloat { width * Theme.cardHeight / Theme.cardWidth }
    private var radius: CGFloat { Theme.cornerRadius(for: width) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.black.opacity(0.18))
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16),
                              style: StrokeStyle(lineWidth: width * 0.018,
                                                 dash: [width * 0.10, width * 0.07]))
            ghost
            if isTarget {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.target, lineWidth: width * 0.05)
                    .shadow(color: Theme.target.opacity(0.8), radius: width * 0.16)
            }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
    }

    @ViewBuilder
    private var ghost: some View {
        switch pile {
        case .foundation(let index):
            if index < state.foundationFamilies.count {
                let family = state.foundationFamilies[index]
                SuitPip(family: family, tint: SuitPip.ghostTint(for: family))
                    .frame(width: width * 0.38, height: width * 0.38)
                    .opacity(0.3)
            }
        case .stock(let side):
            // Talon épuisé mais défausse pleine : elle sera retournée.
            if state.stock(side).isEmpty && !state.waste(side).isEmpty {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: width * 0.30, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Légende d'un paquet

private struct PileCaption: View {
    let title: String
    let count: Int
    let width: CGFloat

    var body: some View {
        HStack(spacing: width * 0.06) {
            Text(title.uppercased())
                .font(.system(size: width * 0.135, weight: .semibold, design: .rounded))
                .tracking(width * 0.012)
            Text("\(count)")
                .font(.system(size: width * 0.135, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.horizontal, width * 0.075)
                .padding(.vertical, width * 0.015)
                .background(Capsule().fill(Color.black.opacity(0.28)))
        }
        .foregroundStyle(Color.white.opacity(0.62))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}
