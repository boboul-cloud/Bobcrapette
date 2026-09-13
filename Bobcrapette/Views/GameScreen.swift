import SwiftUI

/// L'écran de jeu : le tapis, la barre d'état, les actions et les
/// annonces qui se superposent.
struct GameScreen: View {
    @Environment(GameStore.self) private var store
    @Environment(AppSettings.self) private var settings

    @State private var showSettings = false
    @State private var showRules = false
    @State private var confirmQuit = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }
    #else
    private var isCompact: Bool { false }
    #endif

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar
                BoardView()
                    .padding(.horizontal, 4)
                bottomBar
            }

            if let banner = store.banner {
                BannerView(banner: banner)
                    .padding(.top, 62)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
            }

            if store.crapetteOpportunity != nil {
                CrapetteCallButton(progress: store.crapetteCountdown) { store.callCrapette() }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 86)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            if let warning = store.faultWarning {
                FaultWarningPanel(
                    warning: warning,
                    describe: { store.describe($0) },
                    onPlay: { store.cancelFault() },
                    onPass: { store.commitFault() }
                )
            }

            if store.phase == .finished {
                GameOverPanel(
                    winner: store.state.winner,
                    onReplay: { store.startNewGame() },
                    onMenu: { store.abandonGame() }
                )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.banner)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.crapetteOpportunity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.faultWarning)
        .animation(.easeInOut(duration: 0.3), value: store.phase)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showRules) { RulesView() }
        .alert("Abandonner la partie ?", isPresented: $confirmQuit) {
            Button("Continuer à jouer", role: .cancel) {}
            Button("Abandonner", role: .destructive) { store.abandonGame() }
        } message: {
            Text("La partie en cours sera perdue.")
        }
    }

    // MARK: - Barre du haut

    private var topBar: some View {
        HStack(spacing: 10) {
            IconButton(symbol: "chevron.backward", label: "Quitter") { confirmQuit = true }

            Spacer(minLength: 4)
            TurnBadge(
                isPlayerTurn: store.state.current == .south,
                isThinking: store.isOpponentActing,
                isDealing: store.phase == .dealing
            )
            Spacer(minLength: 4)

            CardCountBadge(
                mine: store.state.remainingCards(for: .south),
                theirs: store.state.remainingCards(for: .north)
            )
            IconButton(symbol: "questionmark.circle", label: "Règles") { showRules = true }
            IconButton(symbol: "gearshape", label: "Réglages") { showSettings = true }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Barre du bas

    private var bottomBar: some View {
        HStack(spacing: 10) {
            ActionButton(title: "Annuler", symbol: "arrow.uturn.backward",
                         enabled: store.canUndo, prominent: false) { store.undo() }
                .keyboardShortcut("z", modifiers: .command)

            ActionButton(title: "Indice", symbol: "lightbulb",
                         enabled: store.canHumanAct, prominent: false) { store.showHint() }
                .keyboardShortcut("h", modifiers: [])

            Spacer(minLength: 0)

            ActionButton(
                title: store.canDraw
                    ? (isCompact ? "Retourner" : "Retourner une carte")
                    : (isCompact ? "Passer" : "Passer la main"),
                symbol: store.canDraw ? "arrow.triangle.2.circlepath" : "forward.end",
                enabled: store.canHumanAct,
                prominent: true
            ) { store.requestEndTurn() }
                .keyboardShortcut(.space, modifiers: [])
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

// MARK: - Éléments de la barre

private struct IconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.black.opacity(0.28)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct TurnBadge: View {
    let isPlayerTurn: Bool
    let isThinking: Bool
    let isDealing: Bool

    private var text: String {
        if isDealing { return "Distribution…" }
        if isThinking { return "L'adversaire réfléchit…" }
        return isPlayerTurn ? "À vous de jouer" : "À l'adversaire"
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isPlayerTurn && !isThinking ? Theme.target : Theme.opponentTrace)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.black.opacity(0.3)))
    }
}

private struct CardCountBadge: View {
    let mine: Int
    let theirs: Int

    var body: some View {
        HStack(spacing: 6) {
            count(mine, color: Theme.backColors(for: .south).line)
            Text("/").font(.system(size: 11)).foregroundStyle(.white.opacity(0.35))
            count(theirs, color: Theme.backColors(for: .north).line)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.28)))
        .help("Cartes qu'il reste à écouler : vous / l'adversaire")
    }

    private func count(_ value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 11)
            Text("\(value)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

private struct ActionButton: View {
    let title: String
    let symbol: String
    let enabled: Bool
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(prominent ? Color(red: 0.12, green: 0.16, blue: 0.13) : .white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(prominent
                               ? AnyShapeStyle(LinearGradient(colors: [Theme.selection, Theme.selection.opacity(0.82)],
                                                              startPoint: .top, endPoint: .bottom))
                               : AnyShapeStyle(Color.black.opacity(0.3)))
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}

// MARK: - Annonces

private struct BannerView: View {
    let banner: GameStore.Banner

    private var accent: Color {
        switch banner.style {
        case .info: Theme.hint
        case .warning: Theme.obligation
        case .crapette: Theme.obligation
        case .victory: Theme.target
        case .defeat: Theme.opponentTrace
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(banner.text)
                .font(.system(size: banner.style == .crapette ? 26 : 17,
                              weight: .heavy, design: .serif))
                .foregroundStyle(accent)
            if let detail = banner.detail {
                Text(detail)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .frame(maxWidth: 460)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.72))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(accent.opacity(0.5), lineWidth: 1.5))
        )
        .padding(.horizontal, 20)
    }
}

/// Le bouton qui n'apparaît que quelques secondes, quand l'adversaire
/// a laissé passer un coup obligatoire.
private struct CrapetteCallButton: View {
    let progress: Double
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("CRAPETTE !")
                    .font(.system(size: 25, weight: .heavy, design: .serif))
                Text("L'adversaire a oublié un coup obligatoire")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(
                ZStack(alignment: .leading) {
                    Capsule().fill(LinearGradient(
                        colors: [Theme.obligation, Theme.red],
                        startPoint: .top, endPoint: .bottom))
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .clipShape(Capsule())
            )
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 2))
            .shadow(color: Theme.obligation.opacity(0.6), radius: 18)
            .scaleEffect(pulse ? 1.04 : 0.98)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("c", modifiers: [])
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Avertissement de faute

private struct FaultWarningPanel: View {
    let warning: GameStore.FaultWarning
    let describe: (Move) -> String
    let onPlay: () -> Void
    let onPass: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.obligation)

                Text("Coup obligatoire")
                    .font(.system(size: 21, weight: .bold, design: .serif))

                Text(warning.reason)
                    .font(.system(size: 14, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if let first = warning.obligations.first {
                    Text("À jouer : \(describe(first))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(Theme.obligation.opacity(0.16)))
                }

                Text("Si vous passez malgré tout, l'adversaire peut crier « Crapette ! » : vous perdrez la main sans retourner de carte.")
                    .font(.system(size: 12, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("Passer quand même", action: onPass)
                        .buttonStyle(.bordered)
                    Button("Jouer le coup", action: onPlay)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 2)
            }
            .padding(26)
            .frame(maxWidth: 380)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.parchment))
            .foregroundStyle(Theme.black)
            .shadow(radius: 30)
            .padding(24)
        }
    }
}

// MARK: - Fin de partie

private struct GameOverPanel: View {
    let winner: Side?
    let onReplay: () -> Void
    let onMenu: () -> Void
    @Environment(AppSettings.self) private var settings

    private var title: String {
        switch winner {
        case .south: "Vous avez gagné !"
        case .north: "L'adversaire l'emporte"
        case nil: "Partie nulle"
        }
    }

    private var detail: String {
        switch winner {
        case .south: "Crapette, talon et défausse vidés avant l'adversaire."
        case .north: "Il a écoulé toutes ses cartes le premier."
        case nil: "Plus aucun coup possible des deux côtés."
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: winner == .south ? "crown.fill" : "flag.checkered")
                    .font(.system(size: 38))
                    .foregroundStyle(winner == .south ? Theme.gold : Theme.black.opacity(0.5))

                Text(title).font(.system(size: 25, weight: .bold, design: .serif))
                Text(detail)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 22) {
                    stat("Parties", "\(settings.gamesPlayed)")
                    stat("Gagnées", "\(settings.gamesWon)")
                    stat("Réussite", settings.gamesPlayed == 0 ? "—"
                         : "\(Int(Double(settings.gamesWon) / Double(settings.gamesPlayed) * 100)) %")
                }
                .padding(.vertical, 6)

                HStack(spacing: 10) {
                    Button("Menu", action: onMenu).buttonStyle(.bordered)
                    Button("Rejouer", action: onReplay)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(28)
            .frame(maxWidth: 380)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.parchment))
            .foregroundStyle(Theme.black)
            .shadow(radius: 30)
            .padding(24)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 19, weight: .bold, design: .rounded)).monospacedDigit()
            Text(label).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
        }
    }
}
