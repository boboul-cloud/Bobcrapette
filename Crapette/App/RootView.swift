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
            // Ouvre directement une partie, éventuellement sur une donne
            // reproductible : « -startGame -seed 1234 ».
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-startGame") {
                let seed = arguments.firstIndex(of: "-seed").flatMap { index -> UInt64? in
                    arguments.indices.contains(index + 1) ? UInt64(arguments[index + 1]) : nil
                }
                store.startNewGame(seed: seed)
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 560)
        #endif
    }
}
