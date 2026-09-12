import SwiftUI

@main
struct CrapetteApp: App {
    @State private var settings = AppSettings.shared
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(store)
        }
        #if os(macOS)
        .defaultSize(width: 1240, height: 860)
        #endif
    }
}
