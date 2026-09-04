import XCTest
@testable import ScanToSummon

final class ArchetypeMapperTests: XCTestCase {

    private let mapper = ArchetypeMapper()

    func testResolvesCompoundLabelsFromTheHeadNoun() {
        // The point of scanning back-to-front: the last word is the thing.
        XCTAssertEqual(mapper.archetype(for: "coffee_table"), .verdant)
        XCTAssertEqual(mapper.archetype(for: "water_bottle"), .aqua)
        XCTAssertEqual(mapper.archetype(for: "teddy_bear"), .fauna)
        XCTAssertEqual(mapper.archetype(for: "cell_phone"), .tech)
    }

    func testHandlesPlurals() {
        XCTAssertEqual(mapper.archetype(for: "headphones"), .tech)
        XCTAssertEqual(mapper.archetype(for: "books"), .paper)
    }

    func testUnknownLabelFallsBackToVoid() {
        let match = mapper.map(observations: [ScanObservation(label: "quarklike_thing", confidence: 0.9)])
        XCTAssertEqual(match.archetype, .void)
        XCTAssertFalse(match.isConfident)
        XCTAssertEqual(match.label, "Quarklike Thing")
    }

    func testLowConfidenceObservationsAreIgnored() {
        let match = mapper.map(observations: [ScanObservation(label: "mug", confidence: 0.02)])
        XCTAssertEqual(match.archetype, .void)
    }

    func testPicksTheHighestConfidenceRecognisedLabel() {
        let match = mapper.map(observations: [
            ScanObservation(label: "unrecognisable", confidence: 0.8),
            ScanObservation(label: "laptop", confidence: 0.5),
            ScanObservation(label: "mug", confidence: 0.3)
        ])
        XCTAssertEqual(match.archetype, .tech)
        XCTAssertTrue(match.isConfident)
    }

    func testEmptyObservationsProduceVoid() {
        let match = mapper.map(observations: [])
        XCTAssertEqual(match.archetype, .void)
        XCTAssertEqual(match.label, "")
    }
}

final class DeterminismTests: XCTestCase {

    /// The core promise of the game: scan the same object twice, get the same
    /// creature. If this test fails, the design is broken, not just the code.
    func testSameScanProducesIdenticalCreature() {
        let factory = CreatureFactory()
        let observations = [ScanObservation(label: "coffee_mug", confidence: 0.55)]
        let color = ColorRGB(red: 0.21, green: 0.44, blue: 0.78)

        let first = factory.make(observations: observations, averageColor: color)
        let second = factory.make(observations: observations, averageColor: color)

        XCTAssertEqual(first.signature, second.signature)
        XCTAssertEqual(first.name, second.name)
        XCTAssertEqual(first.archetype, second.archetype)
        XCTAssertEqual(first.baseStats, second.baseStats)
        // Only the identifier and timestamp may differ.
        XCTAssertNotEqual(first.id, second.id)
    }

    /// Colour must not touch identity at all.
    ///
    /// This started as a weaker test about *small* lighting changes, and CI
    /// caught the flaw it was too generous to see: with colour bucketed into
    /// the signature, an object sitting near a bucket edge produced a different
    /// creature on consecutive scans. Colour now only tints, so the claim can
    /// be the strong one — even wildly different lighting is the same creature.
    func testLightingDoesNotAffectIdentityAtAll() {
        let factory = CreatureFactory()
        let observations = [ScanObservation(label: "coffee_mug", confidence: 0.55)]

        let daylight = factory.make(
            observations: observations,
            averageColor: ColorRGB(red: 0.82, green: 0.79, blue: 0.74)
        )
        let lamplight = factory.make(
            observations: observations,
            averageColor: ColorRGB(red: 0.11, green: 0.09, blue: 0.31)
        )

        XCTAssertEqual(daylight.signature, lamplight.signature)
        XCTAssertEqual(daylight.baseStats, lamplight.baseStats)
        XCTAssertEqual(daylight.name, lamplight.name)
        // ...but they still look like the object they came from.
        XCTAssertNotEqual(daylight.tint, lamplight.tint)
    }

    /// The specific values that used to break identity: 0.50 and 0.51 fell on
    /// opposite sides of a bucket edge.
    func testColoursOnAFormerBucketEdgeAreTheSameCreature() {
        let factory = CreatureFactory()
        let observations = [ScanObservation(label: "mug", confidence: 0.55)]

        let below = factory.make(
            observations: observations,
            averageColor: ColorRGB(red: 0.50, green: 0.30, blue: 0.10)
        )
        let above = factory.make(
            observations: observations,
            averageColor: ColorRGB(red: 0.51, green: 0.31, blue: 0.11)
        )

        XCTAssertEqual(below.signature, above.signature)
    }

    func testDifferentObjectsProduceDifferentCreatures() {
        let factory = CreatureFactory()
        let color = ColorRGB(red: 0.5, green: 0.5, blue: 0.5)

        let mug = factory.make(
            observations: [ScanObservation(label: "mug", confidence: 0.6)],
            averageColor: color
        )
        let laptop = factory.make(
            observations: [ScanObservation(label: "laptop", confidence: 0.6)],
            averageColor: color
        )

        XCTAssertNotEqual(mug.signature, laptop.signature)
        XCTAssertNotEqual(mug.archetype, laptop.archetype)
    }

    /// Swift's own `hashValue` is per-process seeded, which would silently break
    /// determinism across launches. This pins the hash we actually use.
    func testStableHashIsNotProcessSeeded() {
        XCTAssertEqual(StableHash.fnv1a("mug"), StableHash.fnv1a("mug"))
        XCTAssertNotEqual(StableHash.fnv1a("mug"), StableHash.fnv1a("jug"))
        // FNV-1a of the empty string is the offset basis.
        XCTAssertEqual(StableHash.fnv1a(""), 0xcbf2_9ce4_8422_2325)
    }

    func testSeededGeneratorReplays() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        for _ in 0..<32 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testStatsStayWithinVariance() {
        let deriver = StatDeriver(variance: 0.18)
        for archetype in Archetype.allCases {
            let base = archetype.baseStats
            for seed in UInt64(0)..<200 {
                let stats = deriver.stats(for: archetype, seed: seed)
                XCTAssertLessThanOrEqual(stats.hp, Int(Double(base.hp) * 1.19))
                XCTAssertGreaterThanOrEqual(stats.hp, Int(Double(base.hp) * 0.81))
                XCTAssertGreaterThan(stats.attack, 0)
            }
        }
    }
}

final class ColorRGBTests: XCTestCase {

    func testGreyObjectsStillGetAColouredCreature() {
        let grey = ColorRGB(red: 0.5, green: 0.5, blue: 0.5).vivid()
        // Should have been pushed off grey rather than left flat.
        XCTAssertNotEqual(grey.red, grey.blue, accuracy: 0.0001)
    }

    func testComponentsAreClamped() {
        let color = ColorRGB(red: 2.0, green: -1.0, blue: 0.5)
        XCTAssertEqual(color.red, 1.0)
        XCTAssertEqual(color.green, 0.0)
    }
}
