import Foundation
import RealityKit

/// Builds the 3D body for a creature.
///
/// The point of this protocol is the migration path. Today every creature is
/// assembled from primitives; once modelled `.usdz` files exist they drop into
/// the bundle and `CompositeVisualProvider` starts preferring them, with no
/// change to any calling code.
protocol CreatureVisualProvider {
    /// Returns a root entity whose feet sit at y = 0 and whose forward is -Z.
    /// The child named `CreatureEntityNames.body` is the part that gets bobbed
    /// by the idle animation.
    func makeEntity(for creature: Creature) -> Entity
}

enum CreatureEntityNames {
    static let root = "creature"
    static let body = "body"
}

/// Tries modelled assets first, falls back to primitives.
///
/// Note that procedural is not a placeholder to be deleted later: scanned
/// creatures are tinted with the colour of the object they came from, so even
/// with a full set of `.usdz` files this remains the fallback for anything
/// unmodelled.
struct CompositeVisualProvider: CreatureVisualProvider {
    let usdz: USDZVisualProvider
    let procedural: ProceduralVisualProvider

    init(
        usdz: USDZVisualProvider = USDZVisualProvider(),
        procedural: ProceduralVisualProvider = ProceduralVisualProvider()
    ) {
        self.usdz = usdz
        self.procedural = procedural
    }

    func makeEntity(for creature: Creature) -> Entity {
        usdz.loadEntity(for: creature) ?? procedural.makeEntity(for: creature)
    }
}
