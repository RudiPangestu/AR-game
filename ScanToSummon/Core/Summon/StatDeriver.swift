import Foundation

/// Turns a seed into stats.
public struct StatDeriver {
    /// Maximum swing above or below the archetype's base value.
    ///
    /// Kept modest: large variance would mean the same object is a great pull
    /// for one player and junk for another, which undercuts the idea that the
    /// creature genuinely belongs to that object.
    public let variance: Double

    public init(variance: Double = 0.18) {
        self.variance = variance
    }

    public func stats(for archetype: Archetype, seed: UInt64) -> Stats {
        var rng = SeededGenerator(seed: seed)
        let base = archetype.baseStats

        func roll(_ value: Int) -> Int {
            let factor = rng.double(in: (1 - variance)...(1 + variance))
            return max(1, Int((Double(value) * factor).rounded()))
        }

        // Order matters for determinism — do not reorder these four lines.
        let hp = roll(base.hp)
        let attack = roll(base.attack)
        let defense = roll(base.defense)
        let speed = roll(base.speed)

        return Stats(hp: hp, attack: attack, defense: defense, speed: speed)
    }
}

/// Invents a creature name from an archetype and a seed.
public struct NameGenerator {
    public init() {}

    public func name(for archetype: Archetype, seed: UInt64) -> String {
        var rng = SeededGenerator(seed: seed &* 0x2545_F491_4F6C_DD1D)
        let prefixes = archetype.namePrefixes
        let prefix = prefixes[Int(rng.next() % UInt64(prefixes.count))]
        let suffixes = Archetype.nameSuffixes
        let suffix = suffixes[Int(rng.next() % UInt64(suffixes.count))]
        return prefix + suffix
    }
}
