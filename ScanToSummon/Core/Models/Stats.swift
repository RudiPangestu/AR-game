import Foundation

/// The four numbers that fully describe a creature in combat.
public struct Stats: Codable, Equatable, Sendable {
    public var hp: Int
    public var attack: Int
    public var defense: Int
    public var speed: Int

    public init(hp: Int, attack: Int, defense: Int, speed: Int) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.speed = speed
    }

    /// Total stat budget. Used to compare creatures and to scale AI opponents.
    public var power: Int { hp / 4 + attack + defense + speed }

    /// Scales every stat by `factor`, never dropping below 1.
    public func scaled(by factor: Double) -> Stats {
        Stats(
            hp: max(1, Int((Double(hp) * factor).rounded())),
            attack: max(1, Int((Double(attack) * factor).rounded())),
            defense: max(1, Int((Double(defense) * factor).rounded())),
            speed: max(1, Int((Double(speed) * factor).rounded()))
        )
    }
}
