import UIKit

/// The MVP ships no audio — nothing here can author a sound file — so haptics
/// carry the whole job of making the hatch feel physical. They are worth
/// getting right rather than treating as a placeholder.
enum Haptics {
    static func tick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func crack() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func burst() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func failure() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
