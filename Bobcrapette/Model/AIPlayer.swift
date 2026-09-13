import Foundation

enum Difficulty: String, CaseIterable, Codable, Sendable, Identifiable {
    case beginner, normal, expert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "Débutant"
        case .normal: "Normal"
        case .expert: "Fort"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: "Joue au plus pressé, oublie souvent ses coups obligatoires — à vous de crier « Crapette ! »"
        case .normal: "Joue proprement, respecte ses obligations et vous surveille"
        case .expert: "Anticipe d'un coup, joue offensif et ne rate jamais une faute"
        }
    }

    /// Probabilité que l'IA néglige ses coups obligatoires pendant un tour,
    /// offrant au joueur l'occasion de crier « Crapette ! ». Rien ne le lui
    /// signale : le niveau débutant fournit donc de quoi s'exercer l'œil.
    var sloppinessPerTurn: Double {
        switch self {
        case .beginner: 0.50
        case .normal: 0.07
        case .expert: 0.0
        }
    }

    /// Probabilité que l'IA repère une faute du joueur.
    var vigilance: Double {
        switch self {
        case .beginner: 0.45
        case .normal: 0.85
        case .expert: 1.0
        }
    }

    /// En dessous de cette valeur, l'IA préfère retourner son talon
    /// plutôt que de jouer un coup sans intérêt.
    var stopThreshold: Double {
        switch self {
        case .beginner: 34
        case .normal: 20
        case .expert: 12
        }
    }

    /// Part de hasard dans le choix du coup.
    var noise: Double {
        switch self {
        case .beginner: 0.40
        case .normal: 0.08
        case .expert: 0.0
        }
    }

    var looksAhead: Bool { self == .expert }
}

/// L'adversaire. Choisit un coup à la fois, comme un joueur humain :
/// le magasin lui redemande une décision après chaque coup joué, ce qui
/// permet d'animer le tour geste par geste.
struct AIPlayer: Sendable {
    var side: Side
    var difficulty: Difficulty
    private var rng: SeededRandomGenerator
    /// Vrai quand l'IA a décidé de bâcler ce tour-ci : elle ignorera ses
    /// coups obligatoires, et s'expose donc à un « Crapette ! ».
    private(set) var isSloppyTurn = false

    /// Au delà, on coupe court : une position ne devrait jamais demander autant de gestes.
    private let maxMovesPerTurn = 45

    init(side: Side, difficulty: Difficulty, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.side = side
        self.difficulty = difficulty
        self.rng = SeededRandomGenerator(seed: seed)
    }

    // MARK: - Décisions

    /// À appeler au début de chaque tour de l'IA.
    mutating func beginTurn() {
        isSloppyTurn = Double.random(in: 0..<1, using: &rng) < difficulty.sloppinessPerTurn
    }

    /// L'IA repère-t-elle la faute que le joueur vient de commettre ?
    mutating func noticesFault() -> Bool {
        Double.random(in: 0..<1, using: &rng) < difficulty.vigilance
    }

    /// Le coup suivant, ou la fin du tour.
    /// `visited` contient les empreintes des positions déjà traversées
    /// pendant ce tour : on n'y retourne pas.
    mutating func chooseAction(in state: GameState, visited: Set<Int>, movesPlayed: Int) -> GameAction {
        guard state.winner == nil else { return .endTurn }

        // Une liste, pas un ensemble : l'ordre doit rester le même d'une
        // exécution à l'autre pour que les parties tirées d'une graine
        // se rejouent à l'identique.
        let obligations = Rules.obligations(for: side, in: state)
        if !isSloppyTurn, let obligation = obligations.first {
            return .move(obligation)
        }
        guard movesPlayed < maxMovesPerTurn else { return .endTurn }

        var candidates: [(move: Move, value: Double)] = []
        for move in Rules.legalMoves(for: side, in: state, deduplicating: true) {
            // Un tour bâclé doit l'être pour de bon : sans cette mise à
            // l'écart, l'IA rejouerait ses obligations d'elle-même — ce sont
            // des montées sur fondation, donc les coups les mieux notés — et
            // le joueur n'aurait jamais l'occasion de crier « Crapette ! ».
            guard !obligations.contains(move) else { continue }
            var next = state
            Rules.apply(move, by: side, to: &next)
            guard !visited.contains(next.positionSignature) else { continue }
            candidates.append((move, value(of: move, before: state, after: next)))
        }
        guard !candidates.isEmpty else { return .endTurn }

        candidates.sort { $0.value > $1.value }

        // Un peu de bruit aux niveaux faibles : l'IA prend parfois
        // le deuxième ou le troisième meilleur coup.
        var pick = candidates[0]
        if difficulty.noise > 0, candidates.count > 1,
           Double.random(in: 0..<1, using: &rng) < difficulty.noise {
            let window = min(candidates.count, 3)
            pick = candidates[Int.random(in: 0..<window, using: &rng)]
        }

        // Un coup qui gagne la partie se joue quoi qu'il arrive.
        var after = state
        Rules.apply(pick.move, by: side, to: &after)
        if after.winner == side { return .move(pick.move) }

        return pick.value >= difficulty.stopThreshold ? .move(pick.move) : .endTurn
    }

    // MARK: - Évaluation

    private func value(of move: Move, before: GameState, after: GameState) -> Double {
        var total = immediateScore(of: move, in: before)
        guard difficulty.looksAhead else { return total }

        // Un coup d'anticipation : ce que la position vaut après, plus
        // la meilleure suite immédiate qu'il ouvre.
        total += (evaluate(after) - evaluate(before)) * 2.5
        let followUp = Rules.legalMoves(for: side, in: after, deduplicating: true)
            .map { immediateScore(of: $0, in: after) }
            .max() ?? 0
        return total + followUp * 0.22
    }

    /// Le mérite d'un coup, jugé sur sa seule apparence.
    private func immediateScore(of move: Move, in state: GameState) -> Double {
        guard let card = Rules.card(in: state, at: move.source) else { return -.infinity }
        var score = 0.0

        switch move.target {
        case .foundation:
            score += 100
            // Un As ouvre toute une famille : rien ne presse davantage.
            if card.rank == 1 { score += 40 }
            // À valeur égale on monte les petites cartes d'abord, elles
            // débloquent la suite du paquet.
            score += Double(max(0, 8 - card.rank)) * 1.5
        case .opponentCrapette:
            // Enterrer la carte retournée de la crapette adverse est le
            // coup le plus rentable après une fondation : il lui rallonge le jeu.
            score += 76
        case .opponentWaste:
            score += 60
        case .tableau(let column):
            score += state.tableau[column].isEmpty ? 14 : 26
        }

        switch move.source {
        case .crapette:
            // Vider sa crapette est la condition de la victoire.
            score += 55
        case .waste:
            score += 20
        case .tableau(let column):
            // Vider une colonne crée de la place à manœuvrer.
            score += state.tableau[column].count == 1 ? 22 : -5
        }

        // Poser une carte haute sur une colonne vide la stérilise :
        // plus rien ne viendra dessus avant longtemps.
        if case .tableau(let column) = move.target, state.tableau[column].isEmpty {
            score -= Double(card.rank) * 1.2
        }
        return score
    }

    /// Valeur statique d'une position pour ce joueur.
    private func evaluate(_ state: GameState) -> Double {
        if state.winner == side { return 10_000 }
        if state.winner == side.opponent { return -10_000 }

        let me = side.index, them = side.opponent.index
        var value = 0.0
        value -= Double(state.crapette[me].count) * 12
        value -= Double(state.stock[me].count) * 3
        value -= Double(state.waste[me].count) * 4
        value += Double(state.crapette[them].count) * 10
        value += Double(state.stock[them].count) * 2.5
        value += Double(state.waste[them].count) * 3.5
        value += Double(state.foundations.reduce(0) { $0 + $1.count })
        value += Double(state.tableau.count(where: \.isEmpty)) * 4
        return value
    }
}

extension AIPlayer {
    /// Le meilleur coup pour un joueur donné, sans bruit ni obligation ratée.
    /// Sert au bouton « Indice ».
    static func suggestion(for side: Side, in state: GameState) -> Move? {
        if let obligation = Rules.obligations(for: side, in: state).first { return obligation }
        var advisor = AIPlayer(side: side, difficulty: .expert, seed: 1)
        if case .move(let move) = advisor.chooseAction(in: state, visited: [], movesPlayed: 0) {
            return move
        }
        return nil
    }
}
