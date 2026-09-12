import Testing
@testable import Crapette

private let tarot = VariantPreset.tarot77.variant

/// Fondations, dans l'ordre : ♠ ♠ ♥ ♥ ♦ ♦ ♣ ♣ ★ ★
private enum F {
    static let spades = 0, spades2 = 1
    static let hearts = 2, hearts2 = 3
    static let diamonds = 4
    static let clubs = 6
    static let trumps = 8, trumps2 = 9
}

private func emptyState(_ variant: GameVariant = tarot, current: Side = .south) -> GameState {
    GameState(
        variant: variant,
        stock: [[], []], waste: [[], []], crapette: [[], []],
        tableau: Array(repeating: [], count: variant.tableauCount),
        foundations: Array(repeating: [], count: variant.foundationCount),
        foundationFamilies: variant.foundationFamilies,
        current: current, movesThisTurn: 0, turnNumber: 1, winner: nil
    )
}

private func card(_ family: Family, _ rank: Int, _ deck: Side = .south) -> Card {
    Card(family: family, rank: rank, deck: deck)
}

// MARK: - Composition du jeu

@Suite("Composition du jeu")
struct DeckTests {

    @Test("Le jeu de tarot compte 77 cartes : 4 × 14 couleurs plus 21 atouts")
    func tarotDeckSize() {
        let deck = GameState.fullDeck(for: .south, variant: tarot)
        #expect(deck.count == 77)
        #expect(tarot.deckSize == 77)
        for family in Family.displayOrder where family.isSuit {
            #expect(deck.count(where: { $0.family == family }) == 14)
        }
        #expect(deck.count(where: { $0.family == .trumps }) == 21)
    }

    @Test("Chaque carte est unique et le jeu de 52 retombe sur ses pieds")
    func deckIntegrity() {
        #expect(Set(GameState.fullDeck(for: .south, variant: tarot).map(\.id)).count == 77)
        let classic = VariantPreset.classic52.variant
        #expect(GameState.fullDeck(for: .north, variant: classic).count == 52)
        #expect(classic.foundationCount == 8)
        #expect(tarot.foundationCount == 10)
    }

    @Test("La distribution donne 13 cartes en crapette, 4 colonnes et le reste au talon")
    func dealing() {
        let state = GameState.dealt(variant: tarot, seed: 42, firstPlayer: .south)
        for side in Side.allCases {
            #expect(state.crapette(side).count == 13)
            #expect(state.stock(side).count == 77 - 13 - 4)
            #expect(state.waste(side).isEmpty)
        }
        #expect(state.tableau.count == 8)
        #expect(state.tableau.allSatisfy { $0.count == 1 })
        // Les 154 cartes sont toutes sur le tapis, aucune perdue.
        let dealt = state.tableau.flatMap { $0 }.count
            + Side.allCases.reduce(0) { $0 + state.remainingCards(for: $1) }
        #expect(dealt == 154)
    }
}

// MARK: - Fondations

@Suite("Fondations")
struct FoundationTests {

    @Test("Une fondation démarre par l'As et se monte sans trou")
    func foundationSequence() {
        var state = emptyState()
        state.crapette[0] = [card(.hearts, 1)]
        #expect(Rules.canPlace(card(.hearts, 1), on: .foundation(F.hearts), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.hearts, 2), on: .foundation(F.hearts), playedBy: .south, in: state))

        state.foundations[F.hearts] = [card(.hearts, 1)]
        #expect(Rules.canPlace(card(.hearts, 2), on: .foundation(F.hearts), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.hearts, 3), on: .foundation(F.hearts), playedBy: .south, in: state))
    }

    @Test("Une fondation n'accepte que sa propre famille")
    func foundationFamily() {
        var state = emptyState()
        state.foundations[F.hearts] = [card(.hearts, 1)]
        #expect(!Rules.canPlace(card(.diamonds, 2), on: .foundation(F.hearts), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.trumps, 2), on: .foundation(F.hearts), playedBy: .south, in: state))
    }

    @Test("Les atouts ont leur propre fondation, montée de 1 à 21")
    func trumpFoundation() {
        var state = emptyState()
        #expect(Rules.canPlace(card(.trumps, 1), on: .foundation(F.trumps), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.trumps, 1), on: .foundation(F.hearts), playedBy: .south, in: state))
        state.foundations[F.trumps] = (1...20).map { card(.trumps, $0) }
        #expect(Rules.canPlace(card(.trumps, 21), on: .foundation(F.trumps), playedBy: .south, in: state))
    }

    @Test("Une carte de l'autre jeu complète la même fondation")
    func foundationsMixDecks() {
        var state = emptyState()
        state.foundations[F.spades] = [card(.spades, 1, .south)]
        #expect(Rules.canPlace(card(.spades, 2, .north), on: .foundation(F.spades), playedBy: .south, in: state))
    }
}

// MARK: - Colonnes

@Suite("Colonnes du tapis")
struct TableauTests {

    @Test("On descend en alternant rouge et noir")
    func alternatingColours() {
        var state = emptyState()
        state.tableau[0] = [card(.spades, 8)]
        #expect(Rules.canPlace(card(.hearts, 7), on: .tableau(0), playedBy: .south, in: state))
        #expect(Rules.canPlace(card(.diamonds, 7), on: .tableau(0), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.clubs, 7), on: .tableau(0), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.hearts, 9), on: .tableau(0), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.hearts, 6), on: .tableau(0), playedBy: .south, in: state))
    }

    @Test("Le Cavalier s'intercale entre Valet et Dame")
    func knightSlotsBetweenJackAndQueen() {
        var state = emptyState()
        state.tableau[0] = [card(.spades, 13)]                         // Dame de pique
        #expect(Rules.canPlace(card(.hearts, 12), on: .tableau(0), playedBy: .south, in: state))  // Cavalier de cœur
        state.tableau[1] = [card(.spades, 12)]                         // Cavalier de pique
        #expect(Rules.canPlace(card(.hearts, 11), on: .tableau(1), playedBy: .south, in: state))  // Valet de cœur
        #expect(card(.hearts, 12).label(suitedRanks: 14) == "C")
        #expect(card(.hearts, 13).label(suitedRanks: 14) == "D")
        #expect(card(.hearts, 14).label(suitedRanks: 14) == "R")
    }

    @Test("Un atout ne se pose que sur un atout, sans contrainte de couleur")
    func trumpsStackOnlyOnTrumps() {
        var state = emptyState()
        state.tableau[0] = [card(.trumps, 18)]
        #expect(Rules.canPlace(card(.trumps, 17), on: .tableau(0), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.trumps, 16), on: .tableau(0), playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.hearts, 17), on: .tableau(0), playedBy: .south, in: state))

        state.tableau[1] = [card(.spades, 14)]   // Roi de pique
        #expect(!Rules.canPlace(card(.trumps, 13), on: .tableau(1), playedBy: .south, in: state))
    }

    @Test("Une colonne vide accueille n'importe quelle carte")
    func emptyColumnTakesAnything() {
        let state = emptyState()
        #expect(Rules.canPlace(card(.trumps, 21), on: .tableau(3), playedBy: .south, in: state))
        #expect(Rules.canPlace(card(.clubs, 1), on: .tableau(3), playedBy: .south, in: state))
    }

    @Test("Promener une colonne d'une seule carte vers une colonne vide est interdit")
    func sterileMoveRejected() {
        var state = emptyState()
        state.tableau[0] = [card(.clubs, 5)]
        #expect(!Rules.isLegal(Move(source: .tableau(0), target: .tableau(1)), for: .south, in: state))
        state.tableau[0] = [card(.clubs, 9), card(.clubs, 5)]
        #expect(Rules.isLegal(Move(source: .tableau(0), target: .tableau(1)), for: .south, in: state))
        #expect(!Rules.isLegal(Move(source: .tableau(0), target: .tableau(0)), for: .south, in: state))
    }
}

// MARK: - Paquets adverses

@Suite("Coups offensifs")
struct OpponentPileTests {

    @Test("On charge la crapette adverse d'une carte voisine de la même famille")
    func loadingOpponentCrapette() {
        var state = emptyState()
        state.crapette[Side.north.index] = [card(.hearts, 7, .north)]
        #expect(Rules.canPlace(card(.hearts, 6), on: .opponentCrapette, playedBy: .south, in: state))
        #expect(Rules.canPlace(card(.hearts, 8), on: .opponentCrapette, playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.hearts, 9), on: .opponentCrapette, playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.spades, 6), on: .opponentCrapette, playedBy: .south, in: state))
    }

    @Test("La règle vaut aussi pour les atouts et pour la défausse")
    func loadingWithTrumps() {
        var state = emptyState()
        state.waste[Side.north.index] = [card(.trumps, 12, .north)]
        #expect(Rules.canPlace(card(.trumps, 11), on: .opponentWaste, playedBy: .south, in: state))
        #expect(Rules.canPlace(card(.trumps, 13), on: .opponentWaste, playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.clubs, 11), on: .opponentWaste, playedBy: .south, in: state))
    }

    @Test("On ne pose rien sur un paquet adverse vide")
    func cannotLoadEmptyPile() {
        let state = emptyState()
        #expect(!Rules.canPlace(card(.hearts, 6), on: .opponentCrapette, playedBy: .south, in: state))
        #expect(!Rules.canPlace(card(.hearts, 6), on: .opponentWaste, playedBy: .south, in: state))
    }

    @Test("On ne joue jamais depuis les paquets de l'adversaire")
    func cannotPlayFromOpponentPiles() {
        var state = emptyState()
        state.crapette[Side.north.index] = [card(.hearts, 1, .north)]
        #expect(!Rules.isLegal(Move(source: .crapette(.north), target: .foundation(F.hearts)), for: .south, in: state))
        #expect(Rules.isLegal(Move(source: .crapette(.north), target: .foundation(F.hearts)), for: .north, in: state))
    }
}

// MARK: - Obligations

@Suite("Obligations et fautes")
struct ObligationTests {

    @Test("Un As disponible doit être posé au centre")
    func aceIsCompulsory() {
        var state = emptyState()
        state.tableau[2] = [card(.clubs, 1)]
        let obligations = Rules.obligations(for: .south, in: state)
        #expect(obligations.contains { $0.source == .tableau(2) })
    }

    @Test("L'atout 1 est obligatoire au même titre qu'un As")
    func trumpOneIsCompulsory() {
        var state = emptyState()
        state.waste[0] = [card(.trumps, 1)]
        #expect(!Rules.obligations(for: .south, in: state).isEmpty)
    }

    @Test("La carte retournée de sa crapette doit monter sur une fondation si elle le peut")
    func crapetteCardIsCompulsory() {
        var state = emptyState()
        state.foundations[F.diamonds] = [card(.diamonds, 1), card(.diamonds, 2)]
        state.crapette[0] = [card(.spades, 9), card(.diamonds, 3)]
        let obligations = Rules.obligations(for: .south, in: state)
        #expect(obligations.count == 1)
        #expect(obligations.first?.source == .crapette(.south))
    }

    @Test("Une carte de crapette qui ne peut aller qu'en colonne n'oblige à rien")
    func crapetteCardOnTableauIsOptional() {
        var state = emptyState()
        state.tableau[0] = [card(.spades, 8)]
        state.crapette[0] = [card(.hearts, 7)]
        #expect(Rules.obligations(for: .south, in: state).isEmpty)
        #expect(!Rules.legalMoves(for: .south, in: state).isEmpty)
    }
}

// MARK: - Déroulement d'un tour

@Suite("Déroulement")
struct TurnTests {

    @Test("Retourner une carte du talon clôt le tour")
    func drawingEndsTurn() {
        var state = emptyState()
        state.stock[0] = [card(.hearts, 4), card(.spades, 9)]
        Rules.endTurn(for: .south, in: &state)
        #expect(state.waste(.south).map(\.id) == [card(.spades, 9).id])
        #expect(state.stock(.south).count == 1)
        #expect(state.current == .north)
    }

    @Test("Talon épuisé : on retourne la défausse pour en refaire un talon")
    func wasteRecycles() {
        var state = emptyState()
        state.waste[0] = [card(.hearts, 2), card(.hearts, 3), card(.hearts, 4)]
        Rules.endTurn(for: .south, in: &state)
        // Le paquet est retourné : le 2 de cœur, qui était dessous, arrive dessus.
        #expect(state.waste(.south).map(\.id) == [card(.hearts, 2).id])
        #expect(state.stock(.south).count == 2)
    }

    @Test("Une faute prive le joueur de sa carte retournée")
    func faultSkipsTheDraw() {
        var state = emptyState()
        state.stock[0] = [card(.hearts, 4), card(.spades, 9)]
        Rules.endTurn(for: .south, in: &state, drawing: false)
        #expect(state.waste(.south).isEmpty)
        #expect(state.stock(.south).count == 2)
        #expect(state.current == .north)
    }

    @Test("Vider crapette, talon et défausse gagne la partie")
    func winCondition() {
        var state = emptyState()
        state.crapette[0] = [card(.hearts, 1)]
        #expect(!state.hasWon(.south))
        Rules.apply(Move(source: .crapette(.south), target: .foundation(F.hearts)), by: .south, to: &state)
        #expect(state.winner == .south)
        #expect(state.hasWon(.south))
        // Plus aucun coup n'est jouable une fois la partie finie.
        #expect(Rules.legalMoves(for: .north, in: state).isEmpty)
    }

    @Test("Un coup joué déplace bien la carte d'un paquet à l'autre")
    func applyMovesTheCard() {
        var state = emptyState()
        state.stock[0] = [card(.clubs, 2)]
        state.tableau[0] = [card(.spades, 8)]
        state.waste[0] = [card(.hearts, 7)]
        Rules.apply(Move(source: .waste(.south), target: .tableau(0)), by: .south, to: &state)
        #expect(state.waste(.south).isEmpty)
        #expect(state.tableau[0].map(\.id) == [card(.spades, 8).id, card(.hearts, 7).id])
        #expect(state.movesThisTurn == 1)
    }
}

// MARK: - L'adversaire

@Suite("Adversaire artificiel")
struct AITests {

    @Test("L'IA ne propose que des coups légaux et respecte ses obligations")
    func aiPlaysLegally() {
        var state = GameState.dealt(variant: tarot, seed: 7, firstPlayer: .north)
        var ai = AIPlayer(side: .north, difficulty: .expert, seed: 3)
        ai.beginTurn()
        var visited: Set<Int> = [state.positionSignature]
        for _ in 0..<12 {
            let obligations = Rules.obligations(for: .north, in: state)
            switch ai.chooseAction(in: state, visited: visited, movesPlayed: 0) {
            case .move(let move):
                #expect(Rules.isLegal(move, for: .north, in: state))
                if !obligations.isEmpty { #expect(obligations.contains(move)) }
                Rules.apply(move, by: .north, to: &state)
                visited.insert(state.positionSignature)
            case .endTurn:
                #expect(obligations.isEmpty, "Un niveau fort ne laisse jamais passer une obligation")
                return
            }
        }
    }

    @Test("Le conseil proposé au joueur est toujours jouable")
    func hintIsPlayable() {
        let state = GameState.dealt(variant: tarot, seed: 11, firstPlayer: .south)
        let suggestion = AIPlayer.suggestion(for: .south, in: state)
        if let suggestion {
            #expect(Rules.isLegal(suggestion, for: .south, in: state))
        }
    }

    @Test("Une partie complète entre deux machines se termine", .timeLimit(.minutes(1)))
    func fullGameTerminates() {
        var state = GameState.dealt(variant: tarot, seed: 2024, firstPlayer: .south)
        var players = [
            AIPlayer(side: .south, difficulty: .normal, seed: 5),
            AIPlayer(side: .north, difficulty: .expert, seed: 6)
        ]
        var turns = 0
        var blocked = false

        while state.winner == nil && !blocked && turns < 4000 {
            let side = state.current
            players[side.index].beginTurn()
            var visited: Set<Int> = [state.positionSignature]
            var played = 0

            turnLoop: while true {
                switch players[side.index].chooseAction(in: state, visited: visited, movesPlayed: played) {
                case .move(let move):
                    #expect(Rules.isLegal(move, for: side, in: state))
                    Rules.apply(move, by: side, to: &state)
                    played += 1
                    visited.insert(state.positionSignature)
                    if state.winner != nil { break turnLoop }
                case .endTurn:
                    blocked = played == 0 && !Rules.canDraw(side, in: state)
                        && Rules.legalMoves(for: side.opponent, in: state).isEmpty
                        && !Rules.canDraw(side.opponent, in: state)
                    Rules.endTurn(for: side, in: &state, drawing: true)
                    break turnLoop
                }
            }
            turns += 1
        }

        #expect(state.winner != nil || blocked, "La partie doit aboutir, elle s'est arrêtée après \(turns) tours")
        if let winner = state.winner {
            #expect(state.hasWon(winner))
        }
    }
}
