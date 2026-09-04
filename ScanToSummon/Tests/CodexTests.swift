import XCTest
@testable import ScanToSummon

private func makeCreature(signature: String, archetype: Archetype = .aqua) -> Creature {
    Creature(
        signature: signature,
        name: "Test\(signature)",
        archetype: archetype,
        sourceLabel: "Mug",
        tint: ColorRGB(red: 0.3, green: 0.5, blue: 0.7),
        baseStats: archetype.baseStats
    )
}

final class CodexTests: XCTestCase {

    func testFirstScanIsADiscovery() {
        var codex = Codex()
        let result = codex.insert(makeCreature(signature: "a"))

        guard case .discovered = result else { return XCTFail("expected a discovery") }
        XCTAssertEqual(codex.count, 1)
    }

    func testRescanningTheSameObjectDoesNotAddASecondEntry() {
        var codex = Codex()
        codex.insert(makeCreature(signature: "a"))
        let result = codex.insert(makeCreature(signature: "a"))

        guard case .duplicate(let creature) = result else { return XCTFail("expected a duplicate") }
        XCTAssertEqual(codex.count, 1)
        XCTAssertEqual(creature.duplicateCount, 1)
    }

    func testDuplicatesRaiseStatsOnACappedCurve() {
        var codex = Codex()
        codex.insert(makeCreature(signature: "a"))
        let base = codex.creatures[0].effectiveStats

        for _ in 0..<5 { codex.insert(makeCreature(signature: "a")) }
        let boosted = codex.creatures[0].effectiveStats
        XCTAssertGreaterThan(boosted.attack, base.attack)

        // Well past the cap — the bonus must stop growing.
        for _ in 0..<40 { codex.insert(makeCreature(signature: "a")) }
        let capped = codex.creatures[0]
        XCTAssertEqual(capped.level, 11)
        XCTAssertEqual(capped.effectiveStats, capped.baseStats.scaled(by: 1.6))
    }

    func testSuggestedTeamPicksTheStrongest() {
        var codex = Codex()
        codex.insert(makeCreature(signature: "weak", archetype: .paper))
        codex.insert(makeCreature(signature: "tanky", archetype: .snack))
        codex.insert(makeCreature(signature: "mid", archetype: .aqua))
        codex.insert(makeCreature(signature: "spare", archetype: .glass))

        let team = codex.suggestedTeam(size: 3)
        XCTAssertEqual(team.count, 3)
        XCTAssertEqual(team, codex.sortedByPower.prefix(3).map { $0 })
    }

    func testSuggestedTeamHandlesAThinCodex() {
        var codex = Codex()
        codex.insert(makeCreature(signature: "only"))
        XCTAssertEqual(codex.suggestedTeam(size: 3).count, 1)
    }
}

final class CodexStoreTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() -> CodexStore {
        CodexStore(fileURL: directory.appendingPathComponent("codex.json"))
    }

    func testLoadingBeforeAnythingIsSavedGivesAnEmptyCodex() {
        XCTAssertTrue(makeStore().load().isEmpty)
    }

    func testSurvivesARoundTrip() throws {
        let store = makeStore()
        let creatures = [
            makeCreature(signature: "a", archetype: .ember),
            makeCreature(signature: "b", archetype: .tech)
        ]

        try store.save(creatures)
        let loaded = store.load()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.map(\.signature), ["a", "b"])
        XCTAssertEqual(loaded.map(\.archetype), [.ember, .tech])
        XCTAssertEqual(loaded[0].baseStats, creatures[0].baseStats)
        XCTAssertEqual(loaded[0].tint, creatures[0].tint)
    }

    func testDuplicateCountsPersist() throws {
        let store = makeStore()
        var codex = Codex()
        codex.insert(makeCreature(signature: "a"))
        codex.insert(makeCreature(signature: "a"))
        codex.insert(makeCreature(signature: "a"))

        try store.save(codex.creatures)
        XCTAssertEqual(store.load().first?.duplicateCount, 2)
    }

    /// Losing a Codex is bad; refusing to launch is worse. A damaged file reads
    /// as empty and gets rewritten on the next scan.
    func testCorruptFileIsTreatedAsEmptyRatherThanCrashing() throws {
        let url = directory.appendingPathComponent("codex.json")
        try Data("this is not json".utf8).write(to: url)

        let store = CodexStore(fileURL: url)
        XCTAssertTrue(store.load().isEmpty)

        // And it must still be writable afterwards.
        try store.save([makeCreature(signature: "recovered")])
        XCTAssertEqual(store.load().count, 1)
    }
}
