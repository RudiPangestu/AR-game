import XCTest
@testable import ScanToSummon

/// Builds a creature without going through a scan.
private func makeCreature(
    _ archetype: Archetype,
    stats: Stats? = nil,
    duplicates: Int = 0
) -> Creature {
    Creature(
        signature: "test:\(archetype.rawValue):\(UUID().uuidString)",
        name: archetype.rawValue.capitalized,
        archetype: archetype,
        sourceLabel: "Test",
        tint: .neutral,
        baseStats: stats ?? archetype.baseStats,
        duplicateCount: duplicates
    )
}

final class TypeChartTests: XCTestCase {

    func testTheTwoRings() {
        XCTAssertEqual(TypeChart.effectiveness(attacker: .ember, defender: .verdant), .strong)
        XCTAssertEqual(TypeChart.effectiveness(attacker: .verdant, defender: .aqua), .strong)
        XCTAssertEqual(TypeChart.effectiveness(attacker: .aqua, defender: .ember), .strong)
        XCTAssertEqual(TypeChart.effectiveness(attacker: .ferro, defender: .air), .strong)
        XCTAssertEqual(TypeChart.effectiveness(attacker: .air, defender: .void), .strong)
        XCTAssertEqual(TypeChart.effectiveness(attacker: .void, defender: .ferro), .strong)
    }

    func testBeingBeatenIsTheInverse() {
        XCTAssertEqual(TypeChart.effectiveness(attacker: .verdant, defender: .ember), .weak)
        XCTAssertEqual(TypeChart.effectiveness(attacker: .air, defender: .ferro), .weak)
    }

    func testAcrossRingsIsNeutral() {
        XCTAssertEqual(TypeChart.effectiveness(attacker: .ember, defender: .ferro), .neutral)
        XCTAssertEqual(TypeChart.effectiveness(attacker: .aqua, defender: .air), .neutral)
    }

    func testSameElementIsNeutral() {
        for element in Element.allCases {
            XCTAssertEqual(TypeChart.effectiveness(attacker: element, defender: element), .neutral)
        }
    }

    func testCounterLookupIsConsistentWithTheChart() {
        for element in Element.allCases {
            let counter = TypeChart.counter(to: element)
            XCTAssertEqual(TypeChart.effectiveness(attacker: counter, defender: element), .strong)
        }
    }

    func testEveryElementHasExactlyOneStrongMatchup() {
        for attacker in Element.allCases {
            let strong = Element.allCases.filter {
                TypeChart.effectiveness(attacker: attacker, defender: $0) == .strong
            }
            XCTAssertEqual(strong.count, 1, "\(attacker) should beat exactly one element")
        }
    }
}

final class BattleEngineTests: XCTestCase {

    private let playerTeam = [makeCreature(.ember), makeCreature(.ferro), makeCreature(.aqua)]
    private let enemyTeam = [makeCreature(.verdant), makeCreature(.air), makeCreature(.glass)]

    private func makeEngine(seed: UInt64 = 7) -> BattleEngine {
        BattleEngine(playerTeam: playerTeam, enemyTeam: enemyTeam, seed: seed)
    }

    /// Plays a whole battle with a simple policy, returning the finished engine.
    private func runToCompletion(_ engine: inout BattleEngine, maxTurns: Int = 500) -> Int {
        var turns = 0
        while engine.outcome == nil && turns < maxTurns {
            turns += 1
            if engine.isAwaitingPlayerInput {
                guard let target = engine.aliveUnits(on: .enemy).first,
                      let actor = engine.activeUnit else { break }
                let move: Move = actor.canUse(.skill) ? .skill : .basic
                engine.takePlayerTurn(move: move, targetID: target.id)
            } else {
                engine.advance()
            }
        }
        return turns
    }

    func testBattleAlwaysTerminates() {
        for seed in UInt64(0)..<50 {
            var engine = makeEngine(seed: seed)
            let turns = runToCompletion(&engine)
            XCTAssertNotNil(engine.outcome, "seed \(seed) never finished")
            XCTAssertLessThan(turns, 500)
        }
    }

    func testOutcomeMatchesWhoIsLeftStanding() {
        var engine = makeEngine()
        _ = runToCompletion(&engine)

        switch engine.outcome {
        case .victory:
            XCTAssertTrue(engine.aliveUnits(on: .enemy).isEmpty)
            XCTAssertFalse(engine.aliveUnits(on: .player).isEmpty)
        case .defeat:
            XCTAssertTrue(engine.aliveUnits(on: .player).isEmpty)
        case nil:
            XCTFail("battle did not finish")
        }
    }

    func testSameSeedAndInputsReplayExactly() {
        var first = makeEngine(seed: 99)
        var second = makeEngine(seed: 99)
        _ = runToCompletion(&first)
        _ = runToCompletion(&second)

        XCTAssertEqual(first.outcome, second.outcome)
        XCTAssertEqual(first.log.count, second.log.count)
        XCTAssertEqual(
            first.units.map(\.currentHP),
            second.units.map(\.currentHP)
        )
    }

    func testFasterCreatureActsFirst() {
        let quick = makeCreature(.glass, stats: Stats(hp: 100, attack: 20, defense: 10, speed: 99))
        let slow = makeCreature(.ceramic, stats: Stats(hp: 100, attack: 20, defense: 10, speed: 1))
        let engine = BattleEngine(playerTeam: [quick], enemyTeam: [slow], seed: 1)
        XCTAssertEqual(engine.activeUnit?.name, quick.name)
    }

    func testSkillGoesOnCooldownForExactlyThreeOfItsOwnTurns() {
        // Beefy, slow-hitting 1v1 so the turn order is unambiguous and neither
        // side dies before the cooldown has run its course.
        let hero = makeCreature(.ferro, stats: Stats(hp: 500, attack: 10, defense: 50, speed: 99))
        let foe = makeCreature(.ferro, stats: Stats(hp: 500, attack: 10, defense: 50, speed: 1))
        var engine = BattleEngine(playerTeam: [hero], enemyTeam: [foe], seed: 3)

        let heroID = engine.activeUnit!.id
        let foeID = engine.aliveUnits(on: .enemy)[0].id
        XCTAssertTrue(engine.unit(heroID)!.canUse(.skill))

        engine.takePlayerTurn(move: .skill, targetID: foeID)
        engine.advance()
        XCTAssertFalse(engine.unit(heroID)!.canUse(.skill), "still cooling down after one turn")

        engine.takePlayerTurn(move: .basic, targetID: foeID)
        engine.advance()
        XCTAssertFalse(engine.unit(heroID)!.canUse(.skill), "still cooling down after two turns")

        engine.takePlayerTurn(move: .basic, targetID: foeID)
        engine.advance()
        XCTAssertTrue(engine.unit(heroID)!.canUse(.skill), "should be ready again on the third turn")
    }

    func testInvalidPlayerInputIsRejectedRatherThanApplied() {
        var engine = makeEngine()
        guard engine.isAwaitingPlayerInput else { return XCTFail("expected a player turn") }

        // Targeting one of your own creatures must not do anything.
        let ownUnit = engine.aliveUnits(on: .player)[1]
        XCTAssertFalse(engine.takePlayerTurn(move: .basic, targetID: ownUnit.id))
        XCTAssertTrue(engine.log.isEmpty)

        XCTAssertFalse(engine.takePlayerTurn(move: .basic, targetID: UUID()))
        XCTAssertTrue(engine.log.isEmpty)
    }

    func testDamageIsNeverZero() {
        // A glass cannon against a wall still chips it.
        let weak = makeCreature(.paper, stats: Stats(hp: 60, attack: 1, defense: 1, speed: 50))
        let wall = makeCreature(.ferro, stats: Stats(hp: 400, attack: 5, defense: 999, speed: 1))
        var engine = BattleEngine(playerTeam: [weak], enemyTeam: [wall], seed: 5)

        guard let target = engine.aliveUnits(on: .enemy).first else { return XCTFail() }
        engine.takePlayerTurn(move: .basic, targetID: target.id)

        guard case let .attack(_, _, _, damage, _) = engine.log.first?.kind else {
            return XCTFail("expected an attack event")
        }
        XCTAssertGreaterThanOrEqual(damage, 1)
    }

    func testAquaSkillHealsItsUser() {
        let healer = makeCreature(.aqua, stats: Stats(hp: 200, attack: 40, defense: 10, speed: 99))
        let dummy = makeCreature(.ember, stats: Stats(hp: 400, attack: 30, defense: 10, speed: 1))
        var engine = BattleEngine(playerTeam: [healer], enemyTeam: [dummy], seed: 11)

        // Trade one round first, so the healer has damage to drain back.
        guard let target = engine.aliveUnits(on: .enemy).first else { return XCTFail() }
        engine.takePlayerTurn(move: .basic, targetID: target.id)
        engine.advance()

        XCTAssertTrue(engine.isAwaitingPlayerInput)
        let damagedHP = engine.aliveUnits(on: .player)[0].currentHP
        XCTAssertLessThan(damagedHP, 200, "the healer should have taken a hit")

        engine.takePlayerTurn(move: .skill, targetID: target.id)

        let didHeal = engine.log.contains { event in
            if case .heal = event.kind { return true }
            return false
        }
        XCTAssertTrue(didHeal, "an aqua skill should emit a heal event")
        XCTAssertGreaterThan(engine.aliveUnits(on: .player)[0].currentHP, damagedHP)
    }
}

final class AITeamBuilderTests: XCTestCase {

    func testBuildsAFullTeam() {
        let player = [makeCreature(.ember), makeCreature(.ferro), makeCreature(.aqua)]
        let team = AITeamBuilder().makeTeam(against: player, seed: 1)
        XCTAssertEqual(team.count, 3)
    }

    func testIncludesACounterToThePlayersDominantElement() {
        // Three aqua-element creatures should draw a verdant opponent.
        let player = [makeCreature(.aqua), makeCreature(.aqua), makeCreature(.ceramic)]
        let team = AITeamBuilder().makeTeam(against: player, seed: 4)
        XCTAssertTrue(
            team.contains { $0.element == TypeChart.counter(to: .aqua) },
            "expected an opponent that counters aqua"
        )
    }

    func testScalesToThePlayersStrength() {
        let weakTeam = (0..<3).map { _ in
            makeCreature(.paper, stats: Stats(hp: 40, attack: 8, defense: 6, speed: 8))
        }
        let strongTeam = (0..<3).map { _ in
            makeCreature(.paper, stats: Stats(hp: 400, attack: 80, defense: 60, speed: 80))
        }

        let weakOpponents = AITeamBuilder().makeTeam(against: weakTeam, seed: 2)
        let strongOpponents = AITeamBuilder().makeTeam(against: strongTeam, seed: 2)

        let weakPower = weakOpponents.reduce(0) { $0 + $1.effectiveStats.power }
        let strongPower = strongOpponents.reduce(0) { $0 + $1.effectiveStats.power }
        XCTAssertGreaterThan(strongPower, weakPower)
    }

    func testEmptyPlayerTeamProducesNoOpponents() {
        XCTAssertTrue(AITeamBuilder().makeTeam(against: [], seed: 1).isEmpty)
    }

    func testIsDeterministicForASeed() {
        let player = [makeCreature(.ember), makeCreature(.tech), makeCreature(.snack)]
        let first = AITeamBuilder().makeTeam(against: player, seed: 77)
        let second = AITeamBuilder().makeTeam(against: player, seed: 77)
        XCTAssertEqual(first.map(\.name), second.map(\.name))
        XCTAssertEqual(first.map(\.baseStats), second.map(\.baseStats))
    }
}
