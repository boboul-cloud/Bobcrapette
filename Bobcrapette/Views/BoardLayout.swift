import CoreGraphics
import Foundation

/// Le plan du tapis, calculé en unités « largeur de carte ». La vue n'a plus
/// qu'à multiplier par un facteur d'échelle pour remplir l'écran : le même
/// plan sert de l'iPhone au Mac.
///
/// Trois pliages sont possibles ; on retient celui qui donne les plus
/// grandes cartes sur l'écran courant.
struct BoardLayout {

    enum Shape: Equatable {
        /// Les huit colonnes et toutes les fondations sur une seule ligne.
        case wide
        /// Huit colonnes, fondations sur deux rangs : pour les écrans carrés.
        case medium
        /// Tout replié en deux : pour les écrans étroits.
        case tall
    }

    let shape: Shape
    let variant: GameVariant
    let boardSize: CGSize
    let slots: [PileRef: CGRect]
    /// Hauteur réservée à l'éventail d'une colonne.
    let columnSpace: CGFloat

    static let cardWidth: CGFloat = Theme.cardWidth
    static let cardHeight: CGFloat = Theme.cardHeight
    private static let gap: CGFloat = 0.16
    private static let padding: CGFloat = 0.35

    // MARK: - Choix du pliage

    static func make(for containerSize: CGSize, variant: GameVariant) -> BoardLayout {
        let candidates = [
            build(variant, shape: .wide, columnsPerRow: variant.tableauCount,
                  foundationRows: 1, columnSpace: 3.2),
            build(variant, shape: .medium, columnsPerRow: variant.tableauCount,
                  foundationRows: 2, columnSpace: 3.2),
            build(variant, shape: .tall, columnsPerRow: variant.tableauColumnsPerPlayer,
                  foundationRows: 2, columnSpace: 2.55)
        ]
        return candidates.max { $0.scale(in: containerSize) < $1.scale(in: containerSize) }
            ?? candidates[0]
    }

    /// Le facteur qui fait tenir le tapis dans l'espace disponible.
    func scale(in containerSize: CGSize) -> CGFloat {
        guard boardSize.width > 0, boardSize.height > 0 else { return 1 }
        return min(containerSize.width / boardSize.width,
                   containerSize.height / boardSize.height)
    }

    // MARK: - Construction

    private static func rowWidth(_ count: Int) -> CGFloat {
        CGFloat(count) * cardWidth + CGFloat(max(0, count - 1)) * gap
    }

    private static func rect(_ x: CGFloat, _ y: CGFloat) -> CGRect {
        CGRect(x: x, y: y, width: cardWidth, height: cardHeight)
    }

    private static func build(_ variant: GameVariant, shape: Shape, columnsPerRow: Int,
                              foundationRows: Int, columnSpace: CGFloat) -> BoardLayout {
        let foundationCount = variant.foundationCount
        let foundationsPerRow = Int((Double(foundationCount) / Double(foundationRows)).rounded(.up))
        let columnRows = Int((Double(variant.tableauCount) / Double(columnsPerRow)).rounded(.up))

        let foundationsWidth = rowWidth(foundationsPerRow)
        let columnsWidth = rowWidth(columnsPerRow)
        // La rangée d'un joueur tient trois paquets : talon, défausse, crapette.
        let contentWidth = max(foundationsWidth, columnsWidth, rowWidth(3) + gap * 2)
        let boardWidth = contentWidth + 2 * padding

        var cursor = padding
        let opponentRow = cursor
        cursor += cardHeight + 0.30

        var foundationYs: [CGFloat] = []
        for row in 0..<foundationRows {
            foundationYs.append(cursor)
            cursor += cardHeight + (row == foundationRows - 1 ? 0.34 : 0.14)
        }

        var columnYs: [CGFloat] = []
        for row in 0..<columnRows {
            columnYs.append(cursor)
            cursor += columnSpace + (row == columnRows - 1 ? 0.30 : 0.24)
        }

        let playerRow = cursor
        let boardHeight = playerRow + cardHeight + padding

        var slots: [PileRef: CGRect] = [:]

        // L'adversaire est vu d'en face : ses paquets sont en miroir des nôtres.
        slots[.crapette(.north)] = rect(padding, opponentRow)
        slots[.waste(.north)] = rect(boardWidth - padding - 2 * cardWidth - gap, opponentRow)
        slots[.stock(.north)] = rect(boardWidth - padding - cardWidth, opponentRow)

        slots[.stock(.south)] = rect(padding, playerRow)
        slots[.waste(.south)] = rect(padding + cardWidth + gap, playerRow)
        slots[.crapette(.south)] = rect(boardWidth - padding - cardWidth, playerRow)

        let foundationX = (boardWidth - foundationsWidth) / 2
        for index in 0..<foundationCount {
            let row = min(index / foundationsPerRow, foundationRows - 1)
            let column = index % foundationsPerRow
            slots[.foundation(index)] = rect(
                foundationX + CGFloat(column) * (cardWidth + gap), foundationYs[row]
            )
        }

        // Sur deux rangs, les colonnes de l'adversaire passent au-dessus.
        let columnX = (boardWidth - columnsWidth) / 2
        for index in 0..<variant.tableauCount {
            let row = columnRows == 1 ? 0 : (index < variant.tableauColumnsPerPlayer ? 1 : 0)
            let column = index % columnsPerRow
            slots[.tableau(index)] = rect(
                columnX + CGFloat(column) * (cardWidth + gap), columnYs[row]
            )
        }

        return BoardLayout(shape: shape, variant: variant,
                           boardSize: CGSize(width: boardWidth, height: boardHeight),
                           slots: slots, columnSpace: columnSpace)
    }

    // MARK: - Positions

    func slot(_ pile: PileRef) -> CGRect { slots[pile] ?? .zero }

    /// L'écart entre deux cartes d'une colonne. Il se resserre quand la colonne
    /// s'allonge, pour que l'éventail reste dans la place prévue.
    func columnFanStep(cardCount: Int) -> CGFloat {
        guard cardCount > 1 else { return 0 }
        let available = columnSpace - Self.cardHeight
        // 0,36 unité laisse apparaître l'index complet du coin de la carte.
        return max(0.075, min(0.36, available / CGFloat(cardCount - 1)))
    }

    /// Le léger décalage qui donne de l'épaisseur aux paquets empilés.
    func stackOffset(index: Int, count: Int) -> CGFloat {
        let visible = min(count, 6)
        let depth = max(0, visible - (count - index))
        return CGFloat(depth) * 0.016
    }

    func position(of pile: PileRef, index: Int, count: Int) -> CGRect {
        let base = slot(pile)
        switch pile {
        case .tableau:
            return base.offsetBy(dx: 0, dy: CGFloat(index) * columnFanStep(cardCount: count))
        case .stock, .waste, .crapette, .foundation:
            let offset = stackOffset(index: index, count: count)
            return base.offsetBy(dx: -offset, dy: -offset)
        }
    }

    /// Les zones de dépôt, de la plus petite à la plus grande, pour retrouver
    /// le paquet visé quand le joueur lâche une carte.
    func dropTargets(for state: GameState) -> [(pile: PileRef, area: CGRect)] {
        var areas: [(PileRef, CGRect)] = []
        for (pile, frame) in slots {
            switch pile {
            case .tableau(let index):
                let count = index < state.tableau.count ? state.tableau[index].count : 0
                let span = CGFloat(max(0, count - 1)) * columnFanStep(cardCount: count)
                areas.append((pile, frame.insetBy(dx: -Self.gap / 2, dy: 0)
                    .union(frame.offsetBy(dx: 0, dy: span))))
            default:
                areas.append((pile, frame.insetBy(dx: -Self.gap / 2, dy: -Self.gap / 2)))
            }
        }
        // Les plus petites zones d'abord : une colonne longue ne doit pas
        // avaler le paquet qui se trouve en dessous.
        return areas.sorted { $0.1.width * $0.1.height < $1.1.width * $1.1.height }
            .map { (pile: $0.0, area: $0.1) }
    }
}
