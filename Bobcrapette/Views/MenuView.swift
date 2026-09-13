import SwiftUI

struct MenuView: View {
    @Environment(GameStore.self) private var store
    @Environment(AppSettings.self) private var settings

    @State private var showSettings = false
    @State private var showRules = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 18)
                CardFanEmblem()
                    .frame(height: 168)

                VStack(spacing: 6) {
                    Text("Bobcrapette")
                        .font(.system(size: 46, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.parchment)
                    Text("La réussite à deux, au jeu de tarot")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.parchment.opacity(0.65))
                }

                VStack(spacing: 11) {
                    MenuButton(title: "Nouvelle partie", symbol: "play.fill", prominent: true) {
                        store.startNewGame()
                    }
                    if store.savedGameAvailable {
                        MenuButton(title: "Reprendre la partie", symbol: "arrow.clockwise") {
                            store.resumeSavedGame()
                        }
                    }
                    MenuButton(title: "Règles du jeu", symbol: "book") { showRules = true }
                    MenuButton(title: "Réglages", symbol: "gearshape") { showSettings = true }
                }
                .frame(maxWidth: 320)

                CurrentSetupSummary()
                    .frame(maxWidth: 340)

                if settings.gamesPlayed > 0 {
                    Text("\(settings.gamesWon) victoire\(settings.gamesWon > 1 ? "s" : "") sur \(settings.gamesPlayed) partie\(settings.gamesPlayed > 1 ? "s" : "")")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.parchment.opacity(0.5))
                }
                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 22)
            .containerRelativeFrame(.vertical, alignment: .center)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showRules) { RulesView() }
    }
}

/// L'éventail de cartes décoratif du menu.
private struct CardFanEmblem: View {
    private let cards: [Card] = [
        Card(family: .spades, rank: 14, deck: .south),
        Card(family: .hearts, rank: 13, deck: .south),
        Card(family: .trumps, rank: 21, deck: .south),
        Card(family: .diamonds, rank: 12, deck: .north),
        Card(family: .clubs, rank: 1, deck: .north)
    ]

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.height / Theme.cardHeight, 96)
            ZStack {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    let angle = Double(index - 2) * 8
                    CardView(card: card, faceUp: true, suitedRanks: 14, width: width)
                        .rotationEffect(.degrees(angle), anchor: .bottom)
                        .offset(x: CGFloat(index - 2) * width * 0.60,
                                y: abs(CGFloat(index - 2)) * width * 0.045)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct CurrentSetupSummary: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(spacing: 5) {
            row("Jeu", settings.variantPreset.title)
            row("Adversaire", settings.difficulty.title)
            row("Crapette", "\(settings.crapetteSize) cartes")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.black.opacity(0.24)))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Theme.parchment.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.parchment.opacity(0.9))
        }
    }
}

private struct MenuButton: View {
    let title: String
    let symbol: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
            }
            .foregroundStyle(prominent ? Color(red: 0.12, green: 0.16, blue: 0.13) : Theme.parchment)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(prominent
                          ? AnyShapeStyle(LinearGradient(colors: [Theme.selection, Theme.selection.opacity(0.8)],
                                                         startPoint: .top, endPoint: .bottom))
                          : AnyShapeStyle(Color.black.opacity(0.28)))
            )
        }
        .buttonStyle(.plain)
    }
}
