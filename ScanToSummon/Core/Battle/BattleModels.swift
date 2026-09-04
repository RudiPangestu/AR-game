import Foundation

public enum Side: String, Codable, Equatable, Sendable {
    case player
    case enemy
}

public enum Move: String, Codable, CaseIterable, Equatable, Sendable {
    case basic
    case skill

    public var damageMultiplier: Double {
        switch self {
        case .basic: return 1.0
        case .skill: return 1.85
        }
    }

    /// Turns the move is unavailable for after use.
    public var cooldown: Int {
        switch self {
        case .basic: return 0
        case .skill: return 3
        }
    }

    public var localizationKey: String { "move.\(rawValue)" }
}

public struct BattleUnit: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let creatureID: UUID
    public let name: String
    public let archetype: Archetype
    public let side: Side
    public let tint: ColorRGB
    public let maxHP: Int
    public var currentHP: Int
    public let attack: Int
    public let defense: Int
    public let speed: Int
    /// Turns remaining before `skill` can be used again.
    public var skillCooldown: Int

    public var element: Element { archetype.element }
    public var isAlive: Bool { currentHP > 0 }
    public var hpFraction: Double { max(0, Double(currentHP) / Double(max(1, maxHP))) }

    public func canUse(_ move: Move) -> Bool {
        move == .basic || skillCooldown == 0
    }

    init(creature: Creature, side: Side) {
        let stats = creature.effectiveStats
        self.id = UUID()
        self.creatureID = creature.id
        self.name = creature.name
        self.archetype = creature.archetype
        self.side = side
        self.tint = creature.tint
        self.maxHP = stats.hp
        self.currentHP = stats.hp
        self.attack = stats.attack
        self.defense = stats.defense
        self.speed = stats.speed
        self.skillCooldown = 0
    }
}

public enum BattleOutcome: String, Equatable, Sendable {
    case victory
    case defeat
}

/// One line of the battle log. Carries enough data for the UI to render it in
/// either language without the engine ever building a user-facing string.
public struct BattleEvent: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case attack(actor: String, target: String, move: Move, damage: Int, effectiveness: Effectiveness)
        case heal(actor: String, amount: Int)
        case defeated(name: String)
        case finished(BattleOutcome)
    }

    public let id: UUID
    public let kind: Kind

    init(_ kind: Kind) {
        self.id = UUID()
        self.kind = kind
    }
}
