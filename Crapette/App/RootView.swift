import SwiftUI

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Theme.felt)
                .ignoresSafeArea()

            if store.phase == .idle {
                MenuView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                GameScreen()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.32), value: store.phase)
        .onAppear {
            #if DEBUG
            // Permet d'ouvrir directement une partie pour inspecter le tapis.
            if ProcessInfo.processInfo.arguments.contains("-startGame") {
                store.startNewGame()
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 560)
        #endif
    }
}
