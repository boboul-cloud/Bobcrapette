import Foundation
import Observation

/// Pilote une partie : enchaîne les tours, fait jouer l'IA geste par geste,
/// arbitre les fautes et tient la sauvegarde à jour.
/// C'est la seule source de vérité pour l'interface.
@Observable
@MainActor
final class GameStore {

    enum Phase: Equatable {
        case idle
        case dealing
        case playing
        case finished
    }

    struct Banner: Identifiable, Equatable {
        enum Style: Equatable { case info, warning, crapette, victory, defeat }
        let id = UUID()
        var text: String
        var detail: String?
        var style: Style
    }

    /// Le joueur s'apprête à passer alors qu'un coup obligatoire l'attend.
    struct FaultWarning: Identifiable, Equatable {
        let id = UUID()
        var obligations: [Move]
        var reason: String
    }

    /// L'adversaire vient de bâcler son tour. Le magasin le sait — il ne le
    /// dit à personne : c'est au joueur de le repérer sur le tapis.
    struct OpponentFault: Identifiable, Equatable {
        let id = UUID()
        var snapshot: GameState
        var missed: Move
    }

    // MARK: - État observé

    private(set) var state: GameState
    private(set) var phase: Phase = .idle
    private(set) var isOpponentActing = false
    private(set) var lastOpponentMove: Move?

    var selection: MoveSource?
    private(set) var highlightedTargets: Set<PileRef> = []
    private(set) var obligationPiles: Set<PileRef> = []
    private(set) var movableSources: Set<PileRef> = []
    private(set) var hintMove: Move?

    var banner: Banner?
    var faultWarning: FaultWarning?
    /// La faute de l'adversaire, tenue secrète : rien dans l'interface ne doit
    /// en trahir la présence, sinon le cri n'est plus qu'une formalité.
    private var opponentFault: OpponentFault?
    /// Le tour où le joueur a déjà crié : on ne crie qu'une fois par tour.
    private var criedOnTurn: Int?
    /// Erreurs de cri qu'il reste au joueur, quand le réglage les compte.
    private(set) var falseCallsLeft = FalseCallPenalty.allowance

    let settings: AppSettings

    // MARK: - Interne

    private var opponent: AIPlayer
    private var undoStack: [GameState] = []
    private var opponentTask: Task<Void, Never>?
    private var dealTask: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?
    private var hintTask: Task<Void, Never>?

    /// Graine de l'adversaire. Fixée, elle rend ses décisions reproductibles,
    /// y compris les tours qu'il choisit de bâcler : sans cela, le
    /// « Crapette ! » ne serait pas testable.
    private let opponentSeed: UInt64?

    init(settings: AppSettings = .shared, opponentSeed: UInt64? = nil) {
        self.settings = settings
        self.opponentSeed = opponentSeed
        self.state = GameState.undealt(variant: settings.variant, seed: 1, firstPlayer: .south)
        self.opponent = AIPlayer(side: .north, difficulty: settings.difficulty,
                                 seed: opponentSeed ?? UInt64.random(in: 1...UInt64.max))
    }

    private func freshOpponent() -> AIPlayer {
        AIPlayer(side: .north, difficulty: settings.difficulty,
                 seed: opponentSeed ?? UInt64.random(in: 1...UInt64.max))
    }

    // MARK: - Cycle de vie d'une partie

    /// Tenu à jour plutôt que relu du disque : l'affichage le consulte souvent.
    private(set) var savedGameAvailable: Bool = GameArchive.load() != nil

    /// `seed` rejoue exactement la même donne : utile pour reproduire une
    /// partie, et indispensable aux tests d'interface.
    func startNewGame(seed: UInt64? = nil) {
        cancelEverything()
        let variant = settings.variant
        let first: Side = settings.humanStarts ? .south : .north
        state = GameState.undealt(variant: variant,
                                  seed: seed ?? UInt64.random(in: 1...UInt64.max),
                                  firstPlayer: first)
        opponent = freshOpponent()
        undoStack.removeAll()
        selection = nil
        phase = .dealing
        refresh()

        let plan = GameState.dealPlan(variant: variant, firstPlayer: first)
        dealTask = Task { [weak self] in
            guard let self else { return }
            for step in plan {
                guard !Task.isCancelled else { return }
                state.apply(step)
                await pause(0.035)
            }
            guard !Task.isCancelled else { return }
            phase = .playing
            refresh()
            save()
            if state.current == .north {
                startOpponentTurn()
            } else {
                announceTurn()
            }
        }
    }

    func resumeSavedGame() {
        guard let saved = GameArchive.load() else { savedGameAvailable = false; return }
        opponent = freshOpponent()
        setUp(with: saved.state)
    }

    /// Installe une position et reprend le fil : si c'est à l'adversaire,
    /// il se met à jouer. Sert à la reprise de partie et aux tests.
    func setUp(with state: GameState) {
        cancelEverything()
        self.state = state
        undoStack.removeAll()
        selection = nil
        phase = state.winner == nil ? .playing : .finished
        refresh()
        if phase == .playing && state.current == .north { startOpponentTurn() }
    }

    func abandonGame() {
        cancelEverything()
        phase = .idle
        GameArchive.clear()
        savedGameAvailable = false
    }

    private func cancelEverything() {
        opponentTask?.cancel()
        dealTask?.cancel()
        bannerTask?.cancel()
        hintTask?.cancel()
        opponentFault = nil
        criedOnTurn = nil
        falseCallsLeft = FalseCallPenalty.allowance
        faultWarning = nil
        banner = nil
        hintMove = nil
        isOpponentActing = false
        lastOpponentMove = nil
    }

    // MARK: - Ce que le joueur peut faire

    var canHumanAct: Bool {
        phase == .playing
            && state.current == .south
            && !isOpponentActing
            && faultWarning == nil
            && state.winner == nil
    }

    var canUndo: Bool { settings.allowUndo && canHumanAct && !undoStack.isEmpty }

    /// Reste-t-il une carte à retourner ? Sinon le joueur passe simplement la main.
    var canDraw: Bool { Rules.canDraw(.south, in: state) }

    /// Plus aucun coup ni aucune carte à retourner des deux côtés :
    /// la partie ne peut plus avancer, elle est nulle.
    var isDeadlocked: Bool {
        Side.allCases.allSatisfy { side in
            !Rules.canDraw(side, in: state) && Rules.legalMoves(for: side, in: state).isEmpty
        }
    }

    func tap(_ pile: PileRef) {
        guard canHumanAct else { return }

        switch pile {
        case .stock(.south):
            requestEndTurn()

        case .crapette(.south):
            toggleSelection(.crapette(.south))

        case .waste(.south):
            toggleSelection(.waste(.south))

        case .tableau(let index):
            if let selection, playIfLegal(from: selection, to: .tableau(index)) { return }
            if !state.tableau[index].isEmpty { toggleSelection(.tableau(index)) }

        case .foundation(let index):
            if let selection { _ = playIfLegal(from: selection, to: .foundation(index)) }

        case .crapette(.north):
            if let selection { _ = playIfLegal(from: selection, to: .opponentCrapette) }

        case .waste(.north):
            if let selection { _ = playIfLegal(from: selection, to: .opponentWaste) }

        case .stock(.north):
            break
        }
    }

    /// Le geste de glisser-déposer : la carte est lâchée sur un paquet.
    func drop(from source: MoveSource, onto pile: PileRef) {
        guard canHumanAct else { selection = nil; refresh(); return }
        guard let target = target(for: pile) else { selection = nil; refresh(); return }
        if !playIfLegal(from: source, to: target) {
            selection = nil
            refresh()
        }
    }

    private func target(for pile: PileRef) -> MoveTarget? {
        switch pile {
        case .foundation(let i): .foundation(i)
        case .tableau(let i): .tableau(i)
        case .crapette(.north): .opponentCrapette
        case .waste(.north): .opponentWaste
        default: nil
        }
    }

    @discardableResult
    private func playIfLegal(from source: MoveSource, to target: MoveTarget) -> Bool {
        let move = Move(source: source, target: target)
        guard Rules.isLegal(move, for: .south, in: state) else { return false }
        play(move)
        return true
    }

    private func toggleSelection(_ source: MoveSource) {
        guard Rules.card(in: state, at: source) != nil else { return }
        if selection == source {
            autoPlay(from: source)
        } else {
            selection = source
            refresh()
        }
    }

    /// Deuxième tape sur une carte déjà choisie : on joue le coup évident,
    /// c'est-à-dire la fondation, ou l'unique destination possible.
    private func autoPlay(from source: MoveSource) {
        let targets = Rules.legalTargets(from: source, for: .south, in: state)
        if let foundation = targets.first(where: { if case .foundation = $0 { return true } else { return false } }) {
            playIfLegal(from: source, to: foundation)
        } else if targets.count == 1 {
            playIfLegal(from: source, to: targets[0])
        } else {
            selection = nil
            refresh()
        }
    }

    func play(_ move: Move) {
        guard canHumanAct, Rules.isLegal(move, for: .south, in: state) else { return }
        // Le premier coup joué clôt le moment du cri.
        opponentFault = nil
        if settings.allowUndo { undoStack.append(state) }
        Rules.apply(move, by: .south, to: &state)
        selection = nil
        hintMove = nil
        Haptics.light(enabled: settings.hapticsEnabled)
        refresh()
        save()
        if state.winner != nil { finish() }
    }

    func undo() {
        guard canUndo, let previous = undoStack.popLast() else { return }
        state = previous
        selection = nil
        hintMove = nil
        refresh()
        save()
    }

    func showHint() {
        guard canHumanAct else { return }
        hintTask?.cancel()
        guard let move = AIPlayer.suggestion(for: .south, in: state) else {
            show(Banner(text: "Aucun coup possible", detail: "Retournez une carte de votre talon pour passer la main.", style: .info))
            return
        }
        hintMove = move
        selection = move.source
        refresh()
        hintTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.hintMove = nil
        }
    }

    // MARK: - Fin de tour et fautes

    func requestEndTurn() {
        guard canHumanAct else { return }
        let obligations = Rules.obligations(for: .south, in: state)
        guard let first = obligations.first else {
            finishHumanTurn(drawing: true)
            return
        }
        if settings.assistEnabled {
            selection = nil
            faultWarning = FaultWarning(
                obligations: obligations,
                reason: Rules.obligationReason(for: first, side: .south, in: state)
            )
            refresh()
        } else {
            commitFault()
        }
    }

    /// Le joueur renonce à passer et va jouer son coup obligatoire.
    func cancelFault() {
        guard let warning = faultWarning else { return }
        faultWarning = nil
        selection = warning.obligations.first?.source
        refresh()
    }

    /// Le joueur passe quand même : l'adversaire peut le prendre en faute.
    func commitFault() {
        faultWarning = nil
        if opponent.noticesFault() {
            show(Banner(
                text: "Crapette !",
                detail: "Un coup obligatoire vous attendait : vous passez la main sans retourner de carte.",
                style: .crapette
            ))
            Haptics.warning(enabled: settings.hapticsEnabled)
            finishHumanTurn(drawing: false)
        } else {
            show(Banner(text: "Passé inaperçu", detail: "L'adversaire n'a rien remarqué.", style: .info))
            finishHumanTurn(drawing: true)
        }
    }

    private func finishHumanTurn(drawing: Bool) {
        selection = nil
        undoStack.removeAll()
        hintMove = nil
        // Le tour change de main : la faute d'en face, criée ou non, est périmée.
        opponentFault = nil
        Rules.endTurn(for: .south, in: &state, drawing: drawing)
        refresh()
        save()
        if state.winner != nil { finish() }
        else if isDeadlocked { finishDraw() }
        else { startOpponentTurn() }
    }

    // MARK: - Le tour de l'adversaire

    private func startOpponentTurn() {
        opponentTask?.cancel()
        opponentTask = Task { [weak self] in await self?.runOpponentTurn() }
    }

    private func runOpponentTurn() async {
        isOpponentActing = true
        defer { isOpponentActing = false; lastOpponentMove = nil }

        opponent.beginTurn()
        var visited: Set<Int> = [state.positionSignature]
        var played = 0
        await pause(0.6)

        while !Task.isCancelled {
            guard phase == .playing, state.current == .north, state.winner == nil else { return }

            switch opponent.chooseAction(in: state, visited: visited, movesPlayed: played) {
            case .move(let move):
                guard Rules.isLegal(move, for: .north, in: state) else {
                    endOpponentTurn(drawing: true)
                    return
                }
                lastOpponentMove = move
                Rules.apply(move, by: .north, to: &state)
                played += 1
                visited.insert(state.positionSignature)
                refresh()
                if state.winner != nil { finish(); return }
                await pause(0.45)

            case .endTurn:
                // Si l'IA a bâclé son tour, le joueur a quelques secondes pour la prendre en faute.
                let missed = Rules.obligations(for: .north, in: state).first
                let snapshot = state
                endOpponentTurn(drawing: true)
                if let missed { opponentFault = OpponentFault(snapshot: snapshot, missed: missed) }
                return
            }
        }
    }

    private func endOpponentTurn(drawing: Bool) {
        Rules.endTurn(for: .north, in: &state, drawing: drawing)
        isOpponentActing = false
        lastOpponentMove = nil
        undoStack.removeAll()
        refresh()
        save()
        if state.winner != nil { finish() }
        else if isDeadlocked { finishDraw() }
        else { announceTurn() }
    }

    // MARK: - Le cri de « Crapette ! »

    /// Le cri est-il recevable ? Uniquement au moment où il a un sens : à vous
    /// de jouer, avant d'avoir bougé la moindre carte.
    ///
    /// Cette disponibilité ne dit rien de la faute : elle est exactement la
    /// même que l'adversaire ait bâclé son tour ou l'ait joué proprement.
    /// C'est tout l'intérêt — c'est au joueur de regarder le tapis.
    var canCallCrapette: Bool {
        canHumanAct
            && state.movesThisTurn == 0
            && criedOnTurn != state.turnNumber
            && !(settings.falseCallPenalty == .rationed && falseCallsLeft == 0)
    }

    /// Le compte d'erreurs restantes, à afficher quand le réglage les compte.
    var falseCallBadge: String? {
        settings.falseCallPenalty == .rationed ? "\(falseCallsLeft)" : nil
    }

    /// Le joueur crie « Crapette ! ». Rien ne le lui a soufflé : c'est un pari
    /// sur ce qu'il a vu. S'il a raison, on rejoue la fin de tour de
    /// l'adversaire, cette fois sans qu'il retourne de carte.
    func callCrapette() {
        guard canCallCrapette else { return }
        criedOnTurn = state.turnNumber
        selection = nil
        hintMove = nil

        guard let fault = opponentFault else {
            missCall()
            return
        }
        opponentFault = nil

        var corrected = fault.snapshot
        Rules.endTurn(for: .north, in: &corrected, drawing: false)
        state = corrected
        undoStack.removeAll()
        Haptics.success(enabled: settings.hapticsEnabled)
        show(Banner(
            text: "Crapette !",
            detail: "Bien vu : l'adversaire devait jouer \(describe(fault.missed)). Il passe la main sans retourner de carte.",
            style: .crapette
        ))
        refresh()
        save()
    }

    /// Le cri tombe à plat. Ce qu'il en coûte dépend du réglage : sans prix,
    /// rien n'empêcherait d'appuyer à chaque tour au cas où.
    private func missCall() {
        Haptics.warning(enabled: settings.hapticsEnabled)
        let title = "Crapette ? Non."

        switch settings.falseCallPenalty {
        case .loseTurn:
            show(Banner(text: title,
                        detail: "L'adversaire n'avait rien oublié : vous passez la main sans retourner de carte.",
                        style: .warning))
            finishHumanTurn(drawing: false)

        case .harmless:
            show(Banner(text: title, detail: "L'adversaire n'avait rien oublié.", style: .warning))
            refresh()

        case .rationed:
            falseCallsLeft = max(0, falseCallsLeft - 1)
            let reste: String
            switch falseCallsLeft {
            case 0: reste = "Vous ne pouvez plus crier de cette partie."
            case 1: reste = "Il vous reste une erreur."
            default: reste = "Il vous reste \(falseCallsLeft) erreurs."
            }
            show(Banner(text: title,
                        detail: "L'adversaire n'avait rien oublié. \(reste)",
                        style: .warning))
            refresh()
        }
    }

    // MARK: - Fin de partie

    private func finish() {
        opponentTask?.cancel()
        opponentFault = nil
        phase = .finished
        let winner = state.winner ?? .north
        settings.recordResult(won: winner == .south)
        GameArchive.clear()
        savedGameAvailable = false
        Haptics.success(enabled: settings.hapticsEnabled && winner == .south)
        refresh()
    }

    /// Aucun des deux joueurs ne peut plus rien faire.
    private func finishDraw() {
        opponentTask?.cancel()
        opponentFault = nil
        phase = .finished
        settings.recordResult(won: false)
        GameArchive.clear()
        savedGameAvailable = false
        refresh()
    }

    // MARK: - Entretien

    private func announceTurn() {
        guard state.current == .south, state.winner == nil else { return }
        if Rules.legalMoves(for: .south, in: state).isEmpty {
            show(Banner(
                text: "À vous",
                detail: canDraw ? "Aucun coup jouable : retournez une carte de votre talon." : "Aucun coup jouable : passez la main.",
                style: .info
            ))
        }
    }

    private func show(_ banner: Banner) {
        bannerTask?.cancel()
        self.banner = banner
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(banner.style == .crapette ? 4.5 : 3))
            guard !Task.isCancelled else { return }
            self?.banner = nil
        }
    }

    /// Recalcule les surbrillances. Appelé après chaque changement d'état,
    /// pour que l'affichage n'ait aucun calcul à refaire pendant les animations.
    private func refresh() {
        guard phase == .playing || phase == .finished else {
            highlightedTargets = []; obligationPiles = []; movableSources = []
            return
        }
        let myMoves = Rules.legalMoves(for: .south, in: state)

        if let selection, canHumanAct {
            highlightedTargets = Set(
                myMoves.filter { $0.source == selection }.map { $0.target.pile(playedBy: .south) }
            )
        } else {
            highlightedTargets = []
        }

        if canHumanAct {
            movableSources = Set(myMoves.map(\.source.pile))
            obligationPiles = settings.assistEnabled
                ? Set(Rules.obligations(for: .south, in: state).map(\.source.pile))
                : []
        } else {
            movableSources = []
            obligationPiles = []
        }
    }

    private func save() {
        guard phase == .playing, state.winner == nil else { return }
        GameArchive.save(SavedGame(state: state, difficulty: settings.difficulty, savedAt: Date()))
        savedGameAvailable = true
    }

    private func pause(_ seconds: Double) async {
        let speed = max(0.4, min(2.5, settings.animationSpeed))
        try? await Task.sleep(for: .seconds(seconds / speed))
    }

    /// Description d'un coup en français, pour les annonces.
    func describe(_ move: Move) -> String {
        guard let card = Rules.card(in: state, at: move.source) else { return "ce coup" }
        return "le \(card.fullName(suitedRanks: state.variant.suitedRanks))"
    }
}
