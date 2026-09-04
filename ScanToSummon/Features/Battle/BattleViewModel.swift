import Foundation
import SwiftUI

final class BattleViewModel: ObservableObject {
    @Published private(set) var engine: BattleEngine
    /// True while enemy turns are playing out, so the controls stay locked.
    @Published private(set) var isResolving = false
    @Published var selectedTargetID: UUID?

    /// Delay between enemy actions. Long enough to read the log line, short
    /// enough that a whole 3v3 stays under two minutes.
    private let turnDelay: TimeInterval = 0.7

    init(playerTeam: [Creature], seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        let enemyTeam = AITeamBuilder().makeTeam(against: playerTeam, seed: seed)
        self.engine = BattleEngine(playerTeam: playerTeam, enemyTeam: enemyTeam, seed: seed)
        self.selectedTargetID = engine.aliveUnits(on: .enemy).first?.id
        advanceIfEnemyStarts()
    }

    var playerUnits: [BattleUnit] { engine.units.filter { $0.side == .player } }
    var enemyUnits: [BattleUnit] { engine.units.filter { $0.side == .enemy } }
    var activeUnit: BattleUnit? { engine.activeUnit }
    var outcome: BattleOutcome? { engine.outcome }

    var canAct: Bool {
        engine.outcome == nil && engine.isAwaitingPlayerInput && !isResolving
    }

    func play(_ move: Move) {
        guard canAct else { return }
        guard let targetID = resolvedTargetID() else { return }

        let didAct = engine.takePlayerTurn(move: move, targetID: targetID)
        guard didAct else {
            Haptics.failure()
            return
        }

        Haptics.tick()
        retargetIfNeeded()
        scheduleEnemyTurn()
    }

    /// Falls back to any living enemy if the selected one just died, so a tap
    /// is never silently swallowed.
    private func resolvedTargetID() -> UUID? {
        if let id = selectedTargetID, let unit = engine.unit(id), unit.isAlive, unit.side == .enemy {
            return id
        }
        return engine.aliveUnits(on: .enemy).first?.id
    }

    private func retargetIfNeeded() {
        if let id = selectedTargetID, let unit = engine.unit(id), unit.isAlive { return }
        selectedTargetID = engine.aliveUnits(on: .enemy).first?.id
    }

    private func advanceIfEnemyStarts() {
        // A fast enemy can hold the first turn of the battle.
        if engine.outcome == nil && !engine.isAwaitingPlayerInput {
            scheduleEnemyTurn()
        }
    }

    private func scheduleEnemyTurn() {
        guard engine.outcome == nil, !engine.isAwaitingPlayerInput else {
            isResolving = false
            finishIfNeeded()
            return
        }

        isResolving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + turnDelay) { [weak self] in
            guard let self else { return }
            _ = self.engine.advance()
            self.retargetIfNeeded()
            self.scheduleEnemyTurn()
        }
    }

    private func finishIfNeeded() {
        switch engine.outcome {
        case .victory: Haptics.success()
        case .defeat: Haptics.failure()
        case nil: break
        }
    }
}
