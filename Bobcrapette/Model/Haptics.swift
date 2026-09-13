#if os(iOS)
import UIKit
#endif

/// Retours haptiques sur iPhone. Sans effet ailleurs.
enum Haptics {
    @MainActor
    static func light(enabled: Bool) {
        guard enabled else { return }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    @MainActor
    static func warning(enabled: Bool) {
        guard enabled else { return }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    @MainActor
    static func success(enabled: Bool) {
        guard enabled else { return }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
