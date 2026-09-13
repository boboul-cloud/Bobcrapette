import Foundation

/// Les cinq familles du jeu : les quatre couleurs du tarot, plus les atouts
/// qui forment une cinquième famille à part entière.
enum Family: Int, CaseIterable, Codable, Sendable, Identifiable {
    case spades = 0
    case hearts
    case diamonds
    case clubs
    case trumps

    var id: Int { rawValue }
    var isTrump: Bool { self == .trumps }
    var isSuit: Bool { self != .trumps }

    var color: CardColor {
        switch self {
        case .hearts, .diamonds: .red
        case .spades, .clubs: .black
        case .trumps: .gold
        }
    }

    var symbol: String {
        switch self {
        case .spades: "\u{2660}"
        case .hearts: "\u{2665}"
        case .diamonds: "\u{2666}"
        case .clubs: "\u{2663}"
        case .trumps: "\u{2605}"
        }
    }

    var name: String {
        switch self {
        case .spades: "Pique"
        case .hearts: "Cœur"
        case .diamonds: "Carreau"
        case .clubs: "Trèfle"
        case .trumps: "Atout"
        }
    }

    /// Ordre d'affichage des fondations au centre du tapis.
    static let displayOrder: [Family] = [.spades, .hearts, .diamonds, .clubs, .trumps]
}

enum CardColor: Int, Codable, Sendable {
    case red, black, gold
}

/// Les deux camps. `south` est toujours le joueur qui tient l'appareil.
enum Side: Int, CaseIterable, Codable, Sendable, Identifiable {
    case south = 0
    case north = 1

    var id: Int { rawValue }
    var opponent: Side { self == .south ? .north : .south }
    var index: Int { rawValue }
}

/// Une carte. `deck` identifie le jeu d'origine (donc la couleur du dos) :
/// à la crapette les deux joueurs apportent chacun leur jeu complet.
struct Card: Identifiable, Hashable, Codable, Sendable {
    var family: Family
    /// Couleurs : 1 = As, 2…10, 11 = Valet, 12 = Cavalier, 13 = Dame, 14 = Roi.
    /// En jeu classique 52 cartes, le Cavalier saute : 12 = Dame, 13 = Roi.
    /// Atouts : 1…21.
    var rank: Int
    var deck: Side

    var id: Int { deck.rawValue * 1_000 + family.rawValue * 100 + rank }
    var color: CardColor { family.color }

    /// Le libellé imprimé dans les coins de la carte.
    func label(suitedRanks: Int) -> String {
        if family.isTrump { return String(rank) }
        if rank == 1 { return "A" }
        if rank <= 10 { return String(rank) }
        let courts = suitedRanks >= 14 ? ["V", "C", "D", "R"] : ["V", "D", "R"]
        let i = rank - 11
        return i >= 0 && i < courts.count ? courts[i] : String(rank)
    }

    /// Nom complet, pour les annonces et l'accessibilité.
    func fullName(suitedRanks: Int) -> String {
        if family.isTrump { return "Atout \(rank)" }
        let names: [String]
        if suitedRanks >= 14 {
            names = ["As", "2", "3", "4", "5", "6", "7", "8", "9", "10",
                     "Valet", "Cavalier", "Dame", "Roi"]
        } else {
            names = ["As", "2", "3", "4", "5", "6", "7", "8", "9", "10",
                     "Valet", "Dame", "Roi"]
        }
        let i = rank - 1
        let r = i >= 0 && i < names.count ? names[i] : String(rank)
        return "\(r) de \(family.name)"
    }

    /// Vrai pour Valet, Cavalier, Dame et Roi : ces cartes ont un dessin plein.
    var isCourt: Bool { family.isSuit && rank > 10 }
}

/// Générateur déterministe (splitmix64) : une même graine rejoue exactement
/// la même donne, ce qui rend les parties reproductibles et les tests stables.
struct SeededRandomGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
