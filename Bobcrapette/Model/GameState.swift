import Foundation

/// Désigne n'importe quel paquet du tapis, de façon absolue.
/// Sert à l'affichage et au repérage des zones de dépôt.
enum PileRef: Hashable, Codable, Sendable {
    case stock(Side)
    case waste(Side)
    case crapette(Side)
    case tableau(Int)
    case foundation(Int)
}

/// L'état complet d'une partie. Valeur pure, sans dépendance à l'interface :
/// tout le moteur de règles et l'IA travaillent dessus, et il se sérialise
/// tel quel pour la reprise de partie.
struct GameState: Hashable, Codable, Sendable {
    var variant: GameVariant

    /// Indexés par `Side.rawValue`.
    var stock: [[Card]]
    var waste: [[Card]]
    var crapette: [[Card]]

    /// Les huit colonnes communes du centre. Toutes les cartes y sont face visible.
    var tableau: [[Card]]
    /// Les fondations, montées de l'As au Roi et de l'atout 1 à l'atout 21.
    var foundations: [[Card]]
    var foundationFamilies: [Family]

    var current: Side
    var movesThisTurn: Int
    var turnNumber: Int
    var winner: Side?

    // MARK: - Accès

    func stock(_ side: Side) -> [Card] { stock[side.index] }
    func waste(_ side: Side) -> [Card] { waste[side.index] }
    func crapette(_ side: Side) -> [Card] { crapette[side.index] }

    func cards(in pile: PileRef) -> [Card] {
        switch pile {
        case .stock(let s): stock[s.index]
        case .waste(let s): waste[s.index]
        case .crapette(let s): crapette[s.index]
        case .tableau(let i): i < tableau.count ? tableau[i] : []
        case .foundation(let i): i < foundations.count ? foundations[i] : []
        }
    }

    func top(of pile: PileRef) -> Card? { cards(in: pile).last }

    /// Cartes qu'il reste à un joueur à écouler pour gagner.
    func remainingCards(for side: Side) -> Int {
        crapette[side.index].count + stock[side.index].count + waste[side.index].count
    }

    /// La condition de victoire : plus de crapette, plus de talon, plus de défausse.
    func hasWon(_ side: Side) -> Bool { remainingCards(for: side) == 0 }

    /// Empreinte de la position, compteurs de tour exclus. Deux positions
    /// identiques donnent la même empreinte, ce qui permet à l'IA de repérer
    /// qu'elle tourne en rond et d'arrêter son tour.
    var positionSignature: Int {
        var hasher = Hasher()
        hasher.combine(current)
        for pile in tableau { hasher.combine(pile) }
        for pile in foundations { hasher.combine(pile.count) }
        for side in Side.allCases {
            hasher.combine(crapette[side.index].count)
            hasher.combine(crapette[side.index].last)
            hasher.combine(waste[side.index].count)
            hasher.combine(waste[side.index].last)
            hasher.combine(stock[side.index].count)
        }
        return hasher.finalize()
    }

    /// Les colonnes apportées par un joueur, pour l'orientation du tapis.
    func tableauIndices(for side: Side) -> Range<Int> {
        let n = variant.tableauColumnsPerPlayer
        return side == .south ? 0..<n : n..<(2 * n)
    }

    // MARK: - Création

    /// Le jeu complet d'un joueur, dans l'ordre.
    static func fullDeck(for side: Side, variant: GameVariant) -> [Card] {
        var cards: [Card] = []
        cards.reserveCapacity(variant.deckSize)
        for family in Family.displayOrder where family.isSuit {
            for rank in 1...variant.suitedRanks {
                cards.append(Card(family: family, rank: rank, deck: side))
            }
        }
        if variant.hasTrumps {
            for rank in 1...variant.trumpCount {
                cards.append(Card(family: .trumps, rank: rank, deck: side))
            }
        }
        return cards
    }

    /// Partie battue mais pas encore distribuée : tout est au talon.
    /// La distribution se fait ensuite carte par carte, pour l'animation.
    static func undealt(variant: GameVariant, seed: UInt64, firstPlayer: Side) -> GameState {
        var rng = SeededRandomGenerator(seed: seed)
        var stocks: [[Card]] = []
        for side in Side.allCases {
            stocks.append(fullDeck(for: side, variant: variant).shuffled(using: &rng))
        }
        return GameState(
            variant: variant,
            stock: stocks,
            waste: [[], []],
            crapette: [[], []],
            tableau: Array(repeating: [], count: variant.tableauCount),
            foundations: Array(repeating: [], count: variant.foundationCount),
            foundationFamilies: variant.foundationFamilies,
            current: firstPlayer,
            movesThisTurn: 0,
            turnNumber: 1,
            winner: nil
        )
    }

    /// Un geste de distribution : le donneur sert une carte du talon d'un joueur.
    struct DealStep: Equatable, Sendable {
        var side: Side
        var destination: Destination

        enum Destination: Equatable, Sendable {
            case crapette
            case tableau(Int)
        }
    }

    /// La donne complète, dans l'ordre où le donneur la sert :
    /// d'abord les crapettes en alternance, puis les quatre colonnes de chacun.
    static func dealPlan(variant: GameVariant, firstPlayer: Side) -> [DealStep] {
        var plan: [DealStep] = []
        let order: [Side] = [firstPlayer, firstPlayer.opponent]
        for _ in 0..<variant.crapetteSize {
            for side in order { plan.append(DealStep(side: side, destination: .crapette)) }
        }
        for column in 0..<variant.tableauColumnsPerPlayer {
            for side in order {
                let base = side == .south ? 0 : variant.tableauColumnsPerPlayer
                plan.append(DealStep(side: side, destination: .tableau(base + column)))
            }
        }
        return plan
    }

    /// Joue un geste de distribution.
    mutating func apply(_ step: DealStep) {
        guard let card = stock[step.side.index].popLast() else { return }
        switch step.destination {
        case .crapette: crapette[step.side.index].append(card)
        case .tableau(let i): tableau[i].append(card)
        }
    }

    /// Partie prête à jouer, distribution déjà faite. Utilisé par les tests.
    static func dealt(variant: GameVariant, seed: UInt64, firstPlayer: Side) -> GameState {
        var state = undealt(variant: variant, seed: seed, firstPlayer: firstPlayer)
        for step in dealPlan(variant: variant, firstPlayer: firstPlayer) { state.apply(step) }
        return state
    }
}
