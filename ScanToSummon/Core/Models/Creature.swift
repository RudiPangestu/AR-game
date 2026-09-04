import Foundation

/// A creature summoned from a real object.
public struct Creature: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID

    /// Deterministic identity, derived from the recognised label plus the
    /// bucketed colour of the object. Two scans of the same mug produce the
    /// same signature — that is how the Codex knows it is a duplicate.
    public let signature: String

    public let name: String
    public let archetype: Archetype

    /// The raw Vision label, kept so the detail screen can show the player
    /// *why* they got this creature. Being able to see "coffee mug → Aqualin"
    /// is a big part of why the scan feels like it understood something.
    public let sourceLabel: String

    public let tint: ColorRGB

    /// Stats as first summoned. Duplicates do not change this; see `effectiveStats`.
    public let baseStats: Stats

    /// How many extra times this object has been scanned.
    public var duplicateCount: Int

    public let discoveredAt: Date

    public init(
        id: UUID = UUID(),
        signature: String,
        name: String,
        archetype: Archetype,
        sourceLabel: String,
        tint: ColorRGB,
        baseStats: Stats,
        duplicateCount: Int = 0,
        discoveredAt: Date = Date()
    ) {
        self.id = id
        self.signature = signature
        self.name = name
        self.archetype = archetype
        self.sourceLabel = sourceLabel
        self.tint = tint
        self.baseStats = baseStats
        self.duplicateCount = duplicateCount
        self.discoveredAt = discoveredAt
    }

    public var element: Element { archetype.element }

    /// Re-scanning an object you already own is not wasted, but it is also not
    /// a slot machine: each duplicate is a flat +6%, and the bonus stops
    /// growing after ten. Because stats are deterministic there is nothing to
    /// re-roll, so the only thing a player can farm is this gentle curve.
    public var effectiveStats: Stats {
        let bonus = 1.0 + 0.06 * Double(min(duplicateCount, 10))
        return baseStats.scaled(by: bonus)
    }

    public var level: Int { 1 + min(duplicateCount, 10) }
}
