import Foundation

/// Paramètres de la variante jouée. Le moteur de règles est entièrement
/// piloté par cette structure : changer le nombre de rangs ou d'atouts
/// suffit à passer du tarot au jeu de 52.
struct GameVariant: Codable, Hashable, Sendable {
    /// Nombre de rangs par couleur : 14 au tarot (avec le Cavalier), 13 au jeu classique.
    var suitedRanks: Int
    /// Nombre d'atouts : 21 au tarot, 0 sinon.
    var trumpCount: Int
    /// Taille du talon face cachée posé à droite de chaque joueur : sa crapette.
    var crapetteSize: Int
    /// Colonnes distribuées par chaque joueur au centre du tapis.
    var tableauColumnsPerPlayer: Int

    var hasTrumps: Bool { trumpCount > 0 }

    /// Les familles réellement présentes dans la donne.
    var families: [Family] {
        hasTrumps ? Family.displayOrder : Family.displayOrder.filter(\.isSuit)
    }

    /// Rang le plus haut d'une famille : Roi pour une couleur, 21 pour les atouts.
    func topRank(of family: Family) -> Int {
        family.isTrump ? trumpCount : suitedRanks
    }

    /// Cartes par joueur. Tarot complet sans l'Excuse : 4 × 14 + 21 = 77.
    var deckSize: Int { 4 * suitedRanks + trumpCount }

    /// Deux fondations par famille, car deux jeux sont en présence donc deux As par couleur.
    var foundationCount: Int { families.count * 2 }

    /// Huit colonnes communes, quatre apportées par chaque joueur.
    var tableauCount: Int { tableauColumnsPerPlayer * 2 }

    /// Cartes restant au talon après la distribution.
    var stockSize: Int { deckSize - crapetteSize - tableauColumnsPerPlayer }

    /// La famille attachée à chaque emplacement de fondation, dans l'ordre d'affichage.
    var foundationFamilies: [Family] {
        families.flatMap { [$0, $0] }
    }
}

/// Les variantes proposées dans les réglages.
enum VariantPreset: String, CaseIterable, Codable, Sendable, Identifiable {
    case tarot77
    case tarot56
    case classic52

    var id: String { rawValue }

    var variant: GameVariant {
        switch self {
        case .tarot77:
            GameVariant(suitedRanks: 14, trumpCount: 21, crapetteSize: 13, tableauColumnsPerPlayer: 4)
        case .tarot56:
            GameVariant(suitedRanks: 14, trumpCount: 0, crapetteSize: 13, tableauColumnsPerPlayer: 4)
        case .classic52:
            GameVariant(suitedRanks: 13, trumpCount: 0, crapetteSize: 13, tableauColumnsPerPlayer: 4)
        }
    }

    var title: String {
        switch self {
        case .tarot77: "Tarot avec atouts"
        case .tarot56: "Tarot sans atouts"
        case .classic52: "Jeu de 52 classique"
        }
    }

    var subtitle: String {
        switch self {
        case .tarot77: "77 cartes par joueur — les 21 atouts forment une cinquième famille"
        case .tarot56: "56 cartes par joueur — quatre couleurs avec le Cavalier"
        case .classic52: "52 cartes par joueur — la crapette telle qu'on la joue au poker deck"
        }
    }
}
