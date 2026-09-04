import Foundation

/// Builds a creature from a scan result.
///
/// Everything here is a pure function of `(label, colour)`. That is the whole
/// design: the same object always becomes the same creature, so the player's
/// belongings feel like they *have* identities rather than being a slot machine.
public struct CreatureFactory {
    private let mapper: ArchetypeMapper
    private let names: NameGenerator

    public init(mapper: ArchetypeMapper = ArchetypeMapper(), names: NameGenerator = NameGenerator()) {
        self.mapper = mapper
        self.names = names
    }

    public func make(observations: [ScanObservation], averageColor: ColorRGB) -> Creature {
        let match = mapper.map(observations: observations)
        let tint = averageColor.vivid()
        let signature = Self.signature(archetype: match.archetype, label: match.label, color: averageColor)
        let seed = StableHash.fnv1a(signature)

        return Creature(
            signature: signature,
            name: names.name(for: match.archetype, seed: seed),
            archetype: match.archetype,
            sourceLabel: match.label,
            tint: tint,
            baseStats: StatDeriver().stats(for: match.archetype, seed: seed)
        )
    }

    /// Identity key for a scan.
    ///
    /// Colour goes through `bucketKey` rather than in full, otherwise a
    /// one-percent lighting change would mint a brand new creature from the
    /// same mug and duplicates would never be detected.
    public static func signature(archetype: Archetype, label: String, color: ColorRGB) -> String {
        let normalizedLabel = ArchetypeMapper.tokenize(label).joined(separator: "-")
        return "\(archetype.rawValue):\(normalizedLabel):\(color.bucketKey)"
    }
}
