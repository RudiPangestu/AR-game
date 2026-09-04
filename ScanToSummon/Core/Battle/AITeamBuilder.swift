import Foundation

/// Generates the opposing team for a battle.
///
/// Opponents are built from the player's own roster strength rather than from a
/// fixed ladder, so the first battle is winnable with three weak creatures and
/// stays interesting once the Codex fills up.
public struct AITeamBuilder {
    /// 1.0 is an even match. Slightly below on purpose: the MVP is trying to
    /// find out whether the loop is fun, and losing your first fight is a bad
    /// way to find that out.
    public let difficulty: Double
    public let teamSize: Int

    public init(difficulty: Double = 0.95, teamSize: Int = 3) {
        self.difficulty = difficulty
        self.teamSize = teamSize
    }

    public func makeTeam(against playerTeam: [Creature], seed: UInt64) -> [Creature] {
        guard !playerTeam.isEmpty else { return [] }

        var rng = SeededGenerator(seed: seed)
        let archetypes = pickArchetypes(against: playerTeam, rng: &rng)

        let playerPower = playerTeam.reduce(0) { $0 + $1.effectiveStats.power }
        let averagePower = Double(playerPower) / Double(playerTeam.count)

        return archetypes.enumerated().map { index, archetype in
            let unitSeed = seed &+ UInt64(index &+ 1) &* 0x9E37_79B9
            let rolled = StatDeriver().stats(for: archetype, seed: unitSeed)

            // Rescale so the opponent lands on the intended power budget
            // regardless of which archetype was drawn.
            let target = averagePower * difficulty
            let factor = target / Double(max(1, rolled.power))
            let stats = rolled.scaled(by: min(max(factor, 0.5), 2.0))

            return Creature(
                signature: "ai:\(archetype.rawValue):\(unitSeed)",
                name: NameGenerator().name(for: archetype, seed: unitSeed),
                archetype: archetype,
                sourceLabel: "",
                tint: randomTint(rng: &rng),
                baseStats: stats
            )
        }
    }

    /// One opponent is always picked to counter whatever the player leans on;
    /// the rest are varied so the fight is not a single-element wall.
    private func pickArchetypes(against playerTeam: [Creature], rng: inout SeededGenerator) -> [Archetype] {
        var counts: [Element: Int] = [:]
        for creature in playerTeam {
            counts[creature.element, default: 0] += 1
        }
        let dominant = counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.rawValue < $1.key.rawValue }
            .first?.key ?? .void
        let counterElement = TypeChart.counter(to: dominant)

        var picks: [Archetype] = []
        if let counterArchetype = Archetype.allCases.first(where: { $0.element == counterElement }) {
            picks.append(counterArchetype)
        }

        let pool = Archetype.allCases.filter { $0 != .void }
        var attempts = 0
        while picks.count < teamSize {
            let candidate = pool[Int(rng.next() % UInt64(pool.count))]
            // Prefer distinct archetypes, but never spin forever chasing one:
            // after a bounded number of draws a repeat is accepted.
            if !picks.contains(candidate) || attempts > pool.count * 4 {
                picks.append(candidate)
            }
            attempts += 1
        }
        return Array(picks.prefix(teamSize))
    }

    private func randomTint(rng: inout SeededGenerator) -> ColorRGB {
        ColorRGB(
            red: rng.double(in: 0.25...0.85),
            green: rng.double(in: 0.25...0.85),
            blue: rng.double(in: 0.25...0.85)
        ).vivid()
    }
}
