import SwiftUI

/// Couleurs et mesures du jeu, rassemblées en un seul endroit.
enum Theme {

    // MARK: - Le tapis

    static let feltLight = Color(red: 0.078, green: 0.290, blue: 0.220)
    static let feltDark = Color(red: 0.016, green: 0.110, blue: 0.086)
    static let feltEdge = Color(red: 0.008, green: 0.067, blue: 0.055)

    static var felt: some ShapeStyle {
        RadialGradient(
            colors: [feltLight, feltDark, feltEdge],
            center: .center, startRadius: 40, endRadius: 900
        )
    }

    // MARK: - Les cartes

    static let cardFace = Color(red: 0.980, green: 0.965, blue: 0.933)
    static let cardFaceShade = Color(red: 0.937, green: 0.914, blue: 0.867)
    static let cardEdge = Color(red: 0.180, green: 0.165, blue: 0.145)

    static let red = Color(red: 0.737, green: 0.114, blue: 0.157)
    static let black = Color(red: 0.098, green: 0.106, blue: 0.129)
    static let gold = Color(red: 0.639, green: 0.451, blue: 0.078)

    static func ink(_ color: CardColor) -> Color {
        switch color {
        case .red: red
        case .black: black
        case .gold: gold
        }
    }

    /// Le dos des cartes : chaque joueur apporte son jeu, donc sa couleur.
    static func backColors(for deck: Side) -> (base: Color, line: Color) {
        switch deck {
        case .south: (Color(red: 0.106, green: 0.208, blue: 0.404), Color(red: 0.235, green: 0.380, blue: 0.639))
        case .north: (Color(red: 0.420, green: 0.110, blue: 0.161), Color(red: 0.647, green: 0.263, blue: 0.294))
        }
    }

    // MARK: - Signalétique

    /// Carte choisie par le joueur.
    static let selection = Color(red: 1.0, green: 0.843, blue: 0.361)
    /// Emplacement où la carte choisie peut aller.
    static let target = Color(red: 0.451, green: 0.925, blue: 0.694)
    /// Coup obligatoire : à jouer sous peine de « Crapette ! ».
    static let obligation = Color(red: 1.0, green: 0.541, blue: 0.259)
    /// Conseil demandé par le joueur.
    static let hint = Color(red: 0.478, green: 0.749, blue: 1.0)
    /// Dernier coup de l'adversaire.
    static let opponentTrace = Color(red: 0.965, green: 0.643, blue: 0.678)

    static let parchment = Color(red: 0.976, green: 0.957, blue: 0.918)

    // MARK: - Mesures

    /// Proportions d'une carte, en unités logiques. Tout le tapis est dessiné
    /// dans ce repère puis mis à l'échelle de l'écran.
    static let cardWidth: CGFloat = 1.0
    static let cardHeight: CGFloat = 1.47

    static func cornerRadius(for width: CGFloat) -> CGFloat { width * 0.082 }
}

/// Comment une carte doit être mise en avant.
enum CardEmphasis: Equatable {
    case none
    case selected
    case obligation
    case hint
    case opponentTrace

    var color: Color? {
        switch self {
        case .none: nil
        case .selected: Theme.selection
        case .obligation: Theme.obligation
        case .hint: Theme.hint
        case .opponentTrace: Theme.opponentTrace
        }
    }
}
