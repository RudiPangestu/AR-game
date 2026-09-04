import Foundation

/// A complete 3v3 battle.
///
/// The engine is a plain value type with no UI, no timers and no async: given
/// the same seed and the same player inputs it always produces the same battle.
/// That is what makes it testable without a simulator, and it is why the battle
/// screen can be a thin renderer over this state.
public struct BattleEngine: Equatable {

    public private(set) var units: [BattleUnit]
    public private(set) var log: [BattleEvent]
    public private(set) var outcome: BattleOutcome?
    public private(set) var round: Int

    private var order: [UUID]
    private var cursor: Int
    private var rng: SeededGenerator

    public init(playerTeam: [Creature], enemyTeam: [Creature], seed: UInt64) {
        let player = playerTeam.map { BattleUnit(creature: $0, side: .player) }
        let enemy = enemyTeam.map { BattleUnit(creature: $0, side: .enemy) }
        self.units = player + enemy
        self.log = []
        self.outcome = nil
        self.round = 1
        self.rng = SeededGenerator(seed: seed)

        // Fast creatures act first. Ties fall back to the unit's identifier so
        // the order is stable rather than dependent on array shuffling.
        self.order = self.units
            .sorted {
                $0.speed != $1.speed
                    ? $0.speed > $1.speed
                    : $0.id.uuidString < $1.id.uuidString
            }
            .map(\.id)
        self.cursor = 0
    }

    // MARK: - Queries

    public var activeUnit: BattleUnit? {
        guard outcome == nil, order.indices.contains(cursor) else { return nil }
        return unit(order[cursor])
    }

    public var isAwaitingPlayerInput: Bool {
        activeUnit?.side == .player
    }

    public func aliveUnits(on side: Side) -> [BattleUnit] {
        units.filter { $0.side == side && $0.isAlive }
    }

    public func unit(_ id: UUID) -> BattleUnit? {
        units.first { $0.id == id }
    }

    /// Events appended by the most recent action, for the UI to animate.
    public private(set) var lastEventCount: Int = 0

    // MARK: - Driving the battle

    /// Resolves the player's chosen action.
    ///
    /// Invalid input (wrong turn, dead target, skill on cooldown) is ignored
    /// rather than trapped — the UI should not be able to corrupt a battle.
    @discardableResult
    public mutating func takePlayerTurn(move: Move, targetID: UUID) -> Bool {
        guard outcome == nil,
              let actor = activeUnit,
              actor.side == .player,
              actor.canUse(move),
              let target = unit(targetID),
              target.side == .enemy,
              target.isAlive
        else { return false }

        lastEventCount = 0
        resolve(move: move, actorID: actor.id, targetID: target.id)
        finishTurn()
        return true
    }

    /// Advances one enemy turn. Returns false when it is the player's move or
    /// the battle is over, so a caller can drive it with `while engine.advance() {}`.
    @discardableResult
    public mutating func advance() -> Bool {
        guard outcome == nil, let actor = activeUnit, actor.side == .enemy else { return false }

        lastEventCount = 0
        let (move, targetID) = chooseEnemyAction(for: actor)
        if let targetID {
            resolve(move: move, actorID: actor.id, targetID: targetID)
        }
        finishTurn()
        return true
    }

    // MARK: - Resolution

    private mutating func resolve(move: Move, actorID: UUID, targetID: UUID) {
        guard let actorIndex = units.firstIndex(where: { $0.id == actorID }),
              let targetIndex = units.firstIndex(where: { $0.id == targetID })
        else { return }

        let actor = units[actorIndex]
        let target = units[targetIndex]

        let effectiveness = TypeChart.effectiveness(attacker: actor.element, defender: target.element)
        let damage = computeDamage(actor: actor, target: target, move: move, effectiveness: effectiveness)

        units[targetIndex].currentHP = max(0, target.currentHP - damage)
        if move == .skill {
            units[actorIndex].skillCooldown = move.cooldown
        }

        append(.attack(
            actor: actor.name,
            target: target.name,
            move: move,
            damage: damage,
            effectiveness: effectiveness
        ))

        // Aqua and verdant drain rather than burst: the two tanky elements get
        // sustain instead of raw numbers, so a slow team has a way to win.
        if move == .skill, actor.element == .aqua || actor.element == .verdant {
            let healed = min(actor.maxHP - units[actorIndex].currentHP, Int((Double(damage) * 0.3).rounded()))
            if healed > 0 {
                units[actorIndex].currentHP += healed
                append(.heal(actor: actor.name, amount: healed))
            }
        }

        if units[targetIndex].currentHP == 0 {
            append(.defeated(name: target.name))
        }
    }

    private mutating func computeDamage(
        actor: BattleUnit,
        target: BattleUnit,
        move: Move,
        effectiveness: Effectiveness
    ) -> Int {
        let typeMultiplier: Double
        switch effectiveness {
        case .strong: typeMultiplier = TypeChart.strongMultiplier
        case .weak: typeMultiplier = TypeChart.weakMultiplier
        case .neutral: typeMultiplier = 1.0
        }

        let raw = Double(actor.attack) * move.damageMultiplier * typeMultiplier
        // Diminishing returns on defence, so a high-defence creature is durable
        // without ever becoming unkillable.
        let mitigated = raw * (100.0 / (100.0 + Double(target.defense)))
        let jitter = rng.double(in: 0.9...1.1)
        return max(1, Int((mitigated * jitter).rounded()))
    }

    private mutating func append(_ kind: BattleEvent.Kind) {
        log.append(BattleEvent(kind))
        lastEventCount += 1
    }

    // MARK: - Turn bookkeeping

    private mutating func finishTurn() {
        if aliveUnits(on: .enemy).isEmpty {
            outcome = .victory
            append(.finished(.victory))
            return
        }
        if aliveUnits(on: .player).isEmpty {
            outcome = .defeat
            append(.finished(.defeat))
            return
        }
        advanceCursor()
    }

    private mutating func advanceCursor() {
        // At most one full lap: `finishTurn` has already established that both
        // sides still have a living unit, so a lap is guaranteed to find one.
        for step in 1...order.count {
            let next = (cursor + step) % order.count
            guard let candidate = unit(order[next]), candidate.isAlive else { continue }

            // Passing the end of the turn order is what makes a new round.
            if next <= cursor { round += 1 }
            cursor = next

            // A unit's cooldown ticks down when its turn comes around, so the
            // UI can show the true availability before the player chooses.
            if let index = units.firstIndex(where: { $0.id == candidate.id }), units[index].skillCooldown > 0 {
                units[index].skillCooldown -= 1
            }
            return
        }
    }

    // MARK: - Enemy AI

    /// Picks a target that the attacker is strong against and that is already
    /// hurt, preferring the kill when one is available.
    private func chooseEnemyAction(for actor: BattleUnit) -> (Move, UUID?) {
        let targets = aliveUnits(on: .player)
        guard !targets.isEmpty else { return (.basic, nil) }

        let move: Move = actor.canUse(.skill) ? .skill : .basic

        let best = targets.max { lhs, rhs in
            score(actor: actor, target: lhs) < score(actor: actor, target: rhs)
        }
        return (move, best?.id)
    }

    private func score(actor: BattleUnit, target: BattleUnit) -> Double {
        let typeMultiplier = TypeChart.multiplier(attacker: actor.element, defender: target.element)
        // Wounded targets are worth more; the 0.6 weight stops the AI from
        // tunnel-visioning a nearly dead creature it is weak against.
        return typeMultiplier * (1.0 + (1.0 - target.hpFraction) * 0.6)
    }
}
