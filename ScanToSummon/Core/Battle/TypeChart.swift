import Foundation

public enum Effectiveness: String, Equatable, Sendable {
    case strong
    case neutral
    case weak
}

public enum TypeChart {
    public static let strongMultiplier: Double = 1.5
    public static let weakMultiplier: Double = 0.67

    /// `attacker → the element it beats`.
    private static let beats: [Element: Element] = [
        .ember: .verdant,
        .verdant: .aqua,
        .aqua: .ember,
        .ferro: .air,
        .air: .void,
        .void: .ferro
    ]

    public static func effectiveness(attacker: Element, defender: Element) -> Effectiveness {
        if beats[attacker] == defender { return .strong }
        if beats[defender] == attacker { return .weak }
        return .neutral
    }

    public static func multiplier(attacker: Element, defender: Element) -> Double {
        switch effectiveness(attacker: attacker, defender: defender) {
        case .strong: return strongMultiplier
        case .weak: return weakMultiplier
        case .neutral: return 1.0
        }
    }

    /// The element that beats `element`. Used to pick opponents that actually
    /// threaten the player's team instead of random filler.
    public static func counter(to element: Element) -> Element {
        for (attacker, defender) in beats where defender == element {
            return attacker
        }
        return element
    }
}
