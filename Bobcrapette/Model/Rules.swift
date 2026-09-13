import Foundation

/// Le moteur de règles de la crapette. Sans état : toutes les fonctions
/// prennent une position et rendent un verdict, ce qui les rend testables
/// et réutilisables telles quelles par l'IA.
///
/// Règles appliquées, variante tarot avec atouts :
///
/// - **Fondations** (au centre) : montées par famille, de l'As au Roi pour les
///   quatre couleurs, de l'atout 1 à l'atout 21 pour les atouts. Deux fondations
///   par famille, puisque deux jeux sont en présence.
/// - **Colonnes** (les huit du centre, communes aux deux joueurs) : on descend
///   en alternant rouge et noir. Un atout ne se pose que sur un atout de rang
///   immédiatement supérieur, sans contrainte de couleur ; aucune carte de
///   couleur ne se pose sur un atout, et réciproquement.
/// - **Colonne vide** : n'importe quelle carte peut l'occuper.
/// - **Paquets adverses** : on peut poser sur la crapette ou la défausse d'en
///   face une carte de la même famille, de rang immédiatement supérieur ou
///   inférieur. C'est le coup offensif qui rallonge le jeu de l'adversaire.
/// - **Une seule carte à la fois** : jamais de séquence déplacée en bloc.
enum Rules {

    // MARK: - Lecture

    /// La carte jouable au sommet d'un paquet source.
    static func card(in state: GameState, at source: MoveSource) -> Card? {
        switch source {
        case .crapette(let s): state.crapette[s.index].last
        case .waste(let s): state.waste[s.index].last
        case .tableau(let i): i < state.tableau.count ? state.tableau[i].last : nil
        }
    }

    // MARK: - Légalité

    /// Une carte peut-elle être posée à cet endroit ?
    static func canPlace(_ card: Card, on target: MoveTarget, playedBy side: Side, in state: GameState) -> Bool {
        switch target {
        case .foundation(let i):
            guard i < state.foundations.count else { return false }
            guard state.foundationFamilies[i] == card.family else { return false }
            // Une fondation se monte sans trou : la carte suivante attendue
            // est toujours celle dont le rang vaut la hauteur du paquet plus un.
            return state.foundations[i].count + 1 == card.rank

        case .tableau(let j):
            guard j < state.tableau.count else { return false }
            guard let top = state.tableau[j].last else { return true }
            guard card.rank == top.rank - 1 else { return false }
            if card.family.isTrump && top.family.isTrump { return true }
            if card.family.isSuit && top.family.isSuit { return card.color != top.color }
            // Mélanger atout et couleur dans une colonne n'est pas permis.
            return false

        case .opponentCrapette:
            guard let top = state.crapette[side.opponent.index].last else { return false }
            return top.family == card.family && abs(top.rank - card.rank) == 1

        case .opponentWaste:
            guard let top = state.waste[side.opponent.index].last else { return false }
            return top.family == card.family && abs(top.rank - card.rank) == 1
        }
    }

    /// Ce coup est-il jouable par ce joueur dans cette position ?
    static func isLegal(_ move: Move, for side: Side, in state: GameState) -> Bool {
        guard state.winner == nil else { return false }

        // On ne joue que depuis ses propres crapette et défausse ;
        // les colonnes du centre appartiennent aux deux joueurs.
        switch move.source {
        case .crapette(let owner), .waste(let owner):
            guard owner == side else { return false }
        case .tableau:
            break
        }

        guard let card = card(in: state, at: move.source) else { return false }

        if case .tableau(let from) = move.source, case .tableau(let to) = move.target {
            guard from != to else { return false }
            // Déplacer une colonne d'une seule carte vers une colonne vide ne
            // fait que promener le trou : coup stérile, donc interdit.
            if state.tableau[to].isEmpty && state.tableau[from].count == 1 { return false }
        }

        return canPlace(card, on: move.target, playedBy: side, in: state)
    }

    /// Tous les coups jouables. `deduplicating` écarte les coups strictement
    /// équivalents — deux colonnes vides, deux fondations au même niveau —
    /// ce qui allège la recherche de l'IA sans rien changer au jeu.
    static func legalMoves(for side: Side, in state: GameState, deduplicating: Bool = false) -> [Move] {
        guard state.winner == nil else { return [] }

        var sources: [MoveSource] = [.crapette(side), .waste(side)]
        sources.append(contentsOf: (0..<state.tableau.count).map { MoveSource.tableau($0) })

        var targets: [MoveTarget] = (0..<state.foundations.count).map { MoveTarget.foundation($0) }
        targets.append(contentsOf: (0..<state.tableau.count).map { MoveTarget.tableau($0) })
        targets.append(.opponentCrapette)
        targets.append(.opponentWaste)

        var moves: [Move] = []
        for source in sources {
            guard card(in: state, at: source) != nil else { continue }
            var emptyColumnUsed = false
            var foundationsSeen = Set<Int>()

            for target in targets {
                let move = Move(source: source, target: target)
                guard isLegal(move, for: side, in: state) else { continue }

                if deduplicating {
                    if case .tableau(let j) = target, state.tableau[j].isEmpty {
                        if emptyColumnUsed { continue }
                        emptyColumnUsed = true
                    }
                    if case .foundation(let i) = target {
                        let key = state.foundationFamilies[i].rawValue * 100 + state.foundations[i].count
                        if foundationsSeen.contains(key) { continue }
                        foundationsSeen.insert(key)
                    }
                }
                moves.append(move)
            }
        }
        return moves
    }

    /// Les destinations légales pour une carte donnée — sert à allumer
    /// les zones de dépôt quand le joueur saisit une carte.
    static func legalTargets(from source: MoveSource, for side: Side, in state: GameState) -> [MoveTarget] {
        legalMoves(for: side, in: state)
            .filter { $0.source == source }
            .map(\.target)
    }

    // MARK: - Obligations

    /// Les coups qu'un joueur n'a pas le droit de laisser passer. S'il termine
    /// son tour alors qu'il en reste un, l'adversaire crie « Crapette ! ».
    ///
    /// Deux obligations :
    /// 1. poser un As ou l'atout 1 disponible sur une fondation ;
    /// 2. poser sur une fondation la carte retournée de sa propre crapette.
    static func obligations(for side: Side, in state: GameState) -> [Move] {
        legalMoves(for: side, in: state, deduplicating: true).filter { move in
            guard case .foundation = move.target else { return false }
            guard let card = card(in: state, at: move.source) else { return false }
            if card.rank == 1 { return true }
            if case .crapette(let owner) = move.source, owner == side { return true }
            return false
        }
    }

    /// La raison, en clair, pour laquelle un coup est obligatoire.
    static func obligationReason(for move: Move, side: Side, in state: GameState) -> String {
        guard let card = card(in: state, at: move.source) else { return "" }
        if card.rank == 1 {
            return card.family.isTrump
                ? "L'atout 1 doit être posé au centre dès qu'il est disponible."
                : "Un As doit être posé au centre dès qu'il est disponible."
        }
        return "La carte retournée de votre crapette doit être posée au centre si elle le peut."
    }

    // MARK: - Application

    @discardableResult
    private static func removeTop(from source: MoveSource, in state: inout GameState) -> Card? {
        switch source {
        case .crapette(let s): return state.crapette[s.index].popLast()
        case .waste(let s): return state.waste[s.index].popLast()
        case .tableau(let i): return i < state.tableau.count ? state.tableau[i].popLast() : nil
        }
    }

    /// Joue un coup. L'appelant est censé l'avoir validé avec `isLegal`.
    static func apply(_ move: Move, by side: Side, to state: inout GameState) {
        guard let card = removeTop(from: move.source, in: &state) else { return }

        switch move.target {
        case .foundation(let i): state.foundations[i].append(card)
        case .tableau(let j): state.tableau[j].append(card)
        case .opponentCrapette: state.crapette[side.opponent.index].append(card)
        case .opponentWaste: state.waste[side.opponent.index].append(card)
        }

        state.movesThisTurn += 1
        if state.hasWon(side) { state.winner = side }
    }

    /// Reste-t-il de quoi retourner une carte ? Quand le talon est vide on
    /// retourne la défausse pour en refaire un talon.
    static func canDraw(_ side: Side, in state: GameState) -> Bool {
        !state.stock[side.index].isEmpty || !state.waste[side.index].isEmpty
    }

    /// Clôt le tour. `drawing` est faux quand une faute prive le joueur
    /// de sa carte retournée, ou quand il n'a plus rien à retourner.
    static func endTurn(for side: Side, in state: inout GameState, drawing: Bool = true) {
        if drawing {
            if state.stock[side.index].isEmpty && !state.waste[side.index].isEmpty {
                state.stock[side.index] = state.waste[side.index].reversed()
                state.waste[side.index] = []
            }
            if let card = state.stock[side.index].popLast() {
                state.waste[side.index].append(card)
            }
        }
        if state.hasWon(side) { state.winner = side; return }
        state.current = side.opponent
        state.movesThisTurn = 0
        state.turnNumber += 1
    }
}
