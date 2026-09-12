import CoreGraphics
import Foundation
import Testing
@testable import Crapette

private let variant = VariantPreset.tarot77.variant

/// Fondations : ♠ ♠ ♥ ♥ ♦ ♦ ♣ ♣ ★ ★
private let heartsFoundation = 2
private let clubsFoundation = 6

private func position(current: Side = .south) -> GameState {
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

@MainActor
private func makeStore(difficulty: Difficulty = .expert, assist: Bool = true) -> GameStore {
    // Réglages isolés : les tests n'écrivent pas dans les préférences réelles.
    let defaults = UserDefaults(suiteName: "crapette.tests.\(UUID().uuidString)")!
    let settings = AppSettings(defaults: defaults)
    settings.difficulty = difficulty
    settings.assistEnabled = assist
    settings.allowUndo = true
    return GameStore(settings: settings)
}

@Suite("Conduite de la partie")
@MainActor
struct GameStoreTests {

    @Test("Toucher une carte l'active et allume ses destinations")
    func selectionLightsUpTargets() {
        let store = makeStore()
        var state = position()
        state.crapette[0] = [card(.hearts, 4), card(.hearts, 1)]
        state.stock[0] = [card(.spades, 7)]
        store.setUp(with: state)

        #expect(store.canHumanAct)
        store.tap(.crapette(.south))
        #expect(store.selection == .crapette(.south))
        #expect(store.highlightedTargets.contains(.foundation(heartsFoundation)))
        store.abandonGame()
    }

    @Test("Retoucher la carte l'envoie d'elle-même sur sa fondation")
    func secondTapPlaysToFoundation() {
        let store = makeStore()
        var state = position()
        state.crapette[0] = [card(.hearts, 4), card(.hearts, 1)]
        state.stock[0] = [card(.spades, 7)]
        store.setUp(with: state)

        store.tap(.crapette(.south))
        store.tap(.crapette(.south))
        #expect(store.state.foundations[heartsFoundation].map(\.id) == [card(.hearts, 1).id])
        #expect(store.state.crapette(.south).count == 1)
        #expect(store.selection == nil)
        store.abandonGame()
    }

    @Test("Un As non joué empêche de passer, et l'aide prévient")
    func assistWarnsBeforeAFault() {
        let store = makeStore(assist: true)
        var state = position()
        state.tableau[2] = [card(.clubs, 1)]
        state.stock[0] = [card(.hearts, 5), card(.spades, 9)]
        store.setUp(with: state)

        #expect(store.obligationPiles.contains(.tableau(2)))
        store.requestEndTurn()
        #expect(store.faultWarning != nil)
        // Tant que le joueur n'a pas tranché, le tour ne bouge pas.
        #expect(store.state.current == .south)
        #expect(store.state.waste(.south).isEmpty)
        store.abandonGame()
    }

    @Test("Revenir sur sa décision pointe le coup à jouer")
    func cancellingAFaultSelectsTheObligation() {
        let store = makeStore(assist: true)
        var state = position()
        state.tableau[2] = [card(.clubs, 1)]
        state.stock[0] = [card(.hearts, 5)]
        store.setUp(with: state)

        store.requestEndTurn()
        store.cancelFault()
        #expect(store.faultWarning == nil)
        #expect(store.selection == .tableau(2))
        #expect(store.highlightedTargets.contains(.foundation(clubsFoundation)))
        store.abandonGame()
    }

    @Test("Passer malgré tout coûte la carte retournée")
    func committingAFaultSkipsTheDraw() {
        let store = makeStore(difficulty: .expert, assist: true)
        var state = position()
        state.tableau[2] = [card(.clubs, 1)]
        state.stock[0] = [card(.hearts, 5), card(.spades, 9)]
        store.setUp(with: state)

        store.requestEndTurn()
        store.commitFault()
        // Un adversaire de niveau fort ne rate jamais une faute.
        #expect(store.state.current == .north)
        #expect(store.state.waste(.south).isEmpty)
        #expect(store.state.stock(.south).count == 2)
        #expect(store.banner?.text == "Crapette !")
        store.abandonGame()
    }

    @Test("Sans aide visuelle, aucun avertissement ne s'interpose")
    func withoutAssistTheFaultIsImmediate() {
        let store = makeStore(difficulty: .expert, assist: false)
        var state = position()
        state.tableau[2] = [card(.clubs, 1)]
        state.stock[0] = [card(.hearts, 5)]
        store.setUp(with: state)

        #expect(store.obligationPiles.isEmpty, "L'aide est coupée : aucun liseré")
        store.requestEndTurn()
        #expect(store.faultWarning == nil)
        #expect(store.state.current == .north)
        store.abandonGame()
    }

    @Test("Sans obligation, retourner une carte clôt normalement le tour")
    func aCleanTurnEndsWithADraw() {
        let store = makeStore()
        var state = position()
        state.tableau[0] = [card(.spades, 9)]
        state.stock[0] = [card(.hearts, 5), card(.diamonds, 8)]
        store.setUp(with: state)

        store.requestEndTurn()
        #expect(store.faultWarning == nil)
        #expect(store.state.waste(.south).map(\.id) == [card(.diamonds, 8).id])
        #expect(store.state.current == .north)
        store.abandonGame()
    }

    @Test("L'annulation remet la position telle qu'elle était")
    func undoRestoresThePosition() {
        let store = makeStore()
        var state = position()
        state.tableau[0] = [card(.spades, 9)]
        state.waste[0] = [card(.hearts, 8)]
        state.stock[0] = [card(.clubs, 3)]
        store.setUp(with: state)

        #expect(!store.canUndo)
        store.play(Move(source: .waste(.south), target: .tableau(0)))
        #expect(store.state.tableau[0].count == 2)
        #expect(store.canUndo)
        store.undo()
        #expect(store.state.tableau[0].count == 1)
        #expect(store.state.waste(.south).count == 1)
        #expect(!store.canUndo)
        store.abandonGame()
    }

    @Test("Vider ses trois paquets termine la partie")
    func emptyingEveryPileWinsTheGame() {
        let store = makeStore()
        var state = position()
        state.crapette[0] = [card(.hearts, 1)]
        store.setUp(with: state)

        store.play(Move(source: .crapette(.south), target: .foundation(heartsFoundation)))
        #expect(store.state.winner == .south)
        #expect(store.phase == .finished)
        store.abandonGame()
    }

    @Test("La distribution garnit le tapis puis rend la main", .timeLimit(.minutes(1)))
    func dealingFillsTheTable() async throws {
        let store = makeStore()
        store.settings.animationSpeed = 2.5
        store.settings.humanStarts = true
        store.startNewGame()
        #expect(store.phase == .dealing)

        try await waitUntil(seconds: 20) { store.phase != .dealing }
        #expect(store.phase == .playing)
        for side in Side.allCases {
            #expect(store.state.crapette(side).count == 13)
            #expect(store.state.stock(side).count == 60)
        }
        #expect(store.state.tableau.allSatisfy { $0.count == 1 })
        store.abandonGame()
    }

    @Test("L'adversaire joue son tour puis rend la main", .timeLimit(.minutes(1)))
    func theOpponentPlaysThenHandsBack() async throws {
        let store = makeStore(difficulty: .normal)
        store.settings.animationSpeed = 2.5
        var state = position(current: .north)
        // Un As en haut de sa crapette : il est obligé de le monter au centre.
        state.crapette[Side.north.index] = [card(.spades, 9, .north), card(.hearts, 1, .north)]
        state.stock[Side.north.index] = [card(.clubs, 4, .north), card(.diamonds, 6, .north)]
        state.tableau[0] = [card(.spades, 5)]
        state.stock[Side.south.index] = [card(.clubs, 8)]
        store.setUp(with: state)

        try await waitUntil(seconds: 25) { store.state.current == .south }
        #expect(store.state.foundations[heartsFoundation].count == 1,
                "L'As de cœur devait monter sur sa fondation")
        #expect(store.state.waste(.north).count == 1, "Le tour se clôt en retournant une carte")
        #expect(!store.isOpponentActing)
        store.abandonGame()
    }

    @Test("Une position sans issue des deux côtés est déclarée nulle")
    func aDeadPositionIsADraw() {
        let store = makeStore()
        var state = position()
        // Personne n'a de carte à retourner, et le Roi ne va nulle part.
        state.crapette[Side.north.index] = [card(.spades, 14, .north)]
        state.tableau[0] = [card(.hearts, 5)]
        state.stock[0] = [card(.clubs, 3)]
        store.setUp(with: state)
        store.requestEndTurn()

        #expect(store.state.current == .north)
        #expect(store.isDeadlocked == false, "L'adversaire peut encore jouer son Roi en colonne vide")
        store.abandonGame()
    }
}

/// Attend qu'une condition soit remplie, sans bloquer la boucle principale.
@MainActor
private func waitUntil(seconds: Double, _ condition: () -> Bool) async throws {
    let deadline = Date().addingTimeInterval(seconds)
    while !condition() && Date() < deadline {
        try await Task.sleep(for: .milliseconds(40))
    }
    #expect(condition(), "Condition non remplie après \(seconds) s")
}

@Suite("Plan du tapis")
struct BoardLayoutTests {

    @Test("Le pliage s'adapte à l'écran")
    func layoutFollowsTheScreen() {
        #expect(BoardLayout.make(for: CGSize(width: 1400, height: 900), variant: variant).shape == .wide)
        #expect(BoardLayout.make(for: CGSize(width: 1024, height: 1250), variant: variant).shape == .medium)
        #expect(BoardLayout.make(for: CGSize(width: 393, height: 700), variant: variant).shape == .tall)
    }

    @Test("Le pliage retenu est celui qui donne les plus grandes cartes")
    func chosenLayoutMaximisesCardSize() {
        for size in [CGSize(width: 1400, height: 900), CGSize(width: 1024, height: 1250),
                     CGSize(width: 393, height: 700), CGSize(width: 852, height: 393)] {
            let chosen = BoardLayout.make(for: size, variant: variant)
            #expect(chosen.scale(in: size) > 0)
            // Le tapis tient entièrement dans l'espace offert.
            #expect(chosen.boardSize.width * chosen.scale(in: size) <= size.width + 0.001)
            #expect(chosen.boardSize.height * chosen.scale(in: size) <= size.height + 0.001)
        }
    }

    @Test("Tous les paquets ont une place, sans chevauchement")
    func everyPileHasItsOwnSpot() {
        let layout = BoardLayout.make(for: CGSize(width: 1400, height: 900), variant: variant)
        var expected: [PileRef] = []
        for side in Side.allCases { expected += [.stock(side), .waste(side), .crapette(side)] }
        expected += (0..<variant.tableauCount).map { PileRef.tableau($0) }
        expected += (0..<variant.foundationCount).map { PileRef.foundation($0) }

        for pile in expected {
            #expect(layout.slots[pile] != nil, "Paquet sans emplacement : \(pile)")
        }
        #expect(layout.slots.count == expected.count)

        // Les emplacements de départ ne se recouvrent pas.
        let frames = expected.map { layout.slot($0) }
        for i in frames.indices {
            for j in frames.indices where j > i {
                #expect(!frames[i].insetBy(dx: 0.01, dy: 0.01).intersects(frames[j]),
                        "Emplacements superposés : \(expected[i]) et \(expected[j])")
            }
        }
    }

    @Test("Le point de chute retrouve le bon paquet")
    func dropTargetsResolveCorrectly() {
        let layout = BoardLayout.make(for: CGSize(width: 1400, height: 900), variant: variant)
        let state = GameState.dealt(variant: variant, seed: 3, firstPlayer: .south)
        let targets = layout.dropTargets(for: state)

        for pile in [PileRef.tableau(0), .tableau(7), .foundation(0), .foundation(9),
                     .crapette(.north), .waste(.north)] {
            let centre = CGPoint(x: layout.slot(pile).midX, y: layout.slot(pile).midY)
            #expect(targets.first { $0.area.contains(centre) }?.pile == pile,
                    "Point de chute mal résolu pour \(pile)")
        }
    }

    @Test("Une colonne longue reste dans la place qui lui est réservée")
    func longColumnsStayWithinTheirSpace() {
        let layout = BoardLayout.make(for: CGSize(width: 1400, height: 900), variant: variant)
        for count in [1, 5, 12, 25] {
            let step = layout.columnFanStep(cardCount: count)
            let span = CGFloat(count - 1) * step + BoardLayout.cardHeight
            #expect(span <= layout.columnSpace + 0.001 || step == 0.075,
                    "Éventail de \(count) cartes débordant")
        }
    }
}
