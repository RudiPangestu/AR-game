import Foundation

/// The player's collection, plus the rule for what happens when they scan
/// something they already own.
public struct Codex: Equatable {
    public private(set) var creatures: [Creature]

    public init(creatures: [Creature] = []) {
        self.creatures = creatures
    }

    public var isEmpty: Bool { creatures.isEmpty }
    public var count: Int { creatures.count }

    /// What an `insert` actually did, so the summon screen can say the right
    /// thing: a brand new creature and a tenth duplicate deserve very different
    /// presentation.
    public enum InsertResult: Equatable {
        case discovered(Creature)
        case duplicate(Creature)
    }

    @discardableResult
    public mutating func insert(_ creature: Creature) -> InsertResult {
        if let index = creatures.firstIndex(where: { $0.signature == creature.signature }) {
            creatures[index].duplicateCount += 1
            return .duplicate(creatures[index])
        }
        creatures.append(creature)
        return .discovered(creature)
    }

    public func creature(withID id: UUID) -> Creature? {
        creatures.first { $0.id == id }
    }

    /// Newest first — the Codex grid reads as a history of what you have found.
    public var sortedByDiscovery: [Creature] {
        creatures.sorted { $0.discoveredAt > $1.discoveredAt }
    }

    /// Strongest first, used to preselect a battle team.
    public var sortedByPower: [Creature] {
        creatures.sorted { $0.effectiveStats.power > $1.effectiveStats.power }
    }

    public func suggestedTeam(size: Int = 3) -> [Creature] {
        Array(sortedByPower.prefix(size))
    }
}
