import Foundation

/// D'où part une carte. On ne joue jamais que la carte du dessus d'un paquet,
/// et jamais depuis les paquets de l'adversaire.
enum MoveSource: Hashable, Codable, Sendable {
    case crapette(Side)
    case waste(Side)
    case tableau(Int)

    var pile: PileRef {
        switch self {
        case .crapette(let s): .crapette(s)
        case .waste(let s): .waste(s)
        case .tableau(let i): .tableau(i)
        }
    }
}

/// Où elle atterrit. Les deux dernières valeurs sont relatives au joueur
/// qui joue : poser sur la crapette ou la défausse d'en face est un coup offensif.
enum MoveTarget: Hashable, Codable, Sendable {
    case foundation(Int)
    case tableau(Int)
    case opponentCrapette
    case opponentWaste

    func pile(playedBy side: Side) -> PileRef {
        switch self {
        case .foundation(let i): .foundation(i)
        case .tableau(let i): .tableau(i)
        case .opponentCrapette: .crapette(side.opponent)
        case .opponentWaste: .waste(side.opponent)
        }
    }
}

struct Move: Hashable, Codable, Sendable, Identifiable {
    var source: MoveSource
    var target: MoveTarget

    var id: Self { self }
}

/// Ce qu'un joueur peut décider de faire quand c'est son tour.
enum GameAction: Hashable, Sendable {
    case move(Move)
    /// Retourner une carte de son talon sur sa défausse, ce qui clôt le tour.
    case endTurn
}
