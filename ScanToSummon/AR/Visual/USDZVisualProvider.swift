import Foundation
import RealityKit
import UIKit

/// Loads a modelled creature body from `Creatures/<archetype>.usdz` in the app
/// bundle, if one has been added.
///
/// No such files ship today, so `loadEntity` always returns nil and
/// `CompositeVisualProvider` falls through to primitives. Dropping the files in
/// is the entire integration — see `docs/creature-asset-spec.md` for the
/// contract they have to meet.
struct USDZVisualProvider {

    static let subdirectory = "Creatures"

    /// Meshes with this node name get recoloured with the scanned object's
    /// colour. Everything else — eyes, teeth, details — keeps the colours it
    /// was authored with.
    ///
    /// Matching on the *node* name rather than the material name is deliberate:
    /// entity names survive USD export from any tool and are readable from
    /// RealityKit directly, whereas material names are not exposed uniformly.
    static let tintableNodeName = "Body"

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadEntity(for creature: Creature) -> Entity? {
        guard let url = assetURL(for: creature.archetype),
              let loaded = try? Entity.load(contentsOf: url)
        else { return nil }

        let root = Entity()
        root.name = CreatureEntityNames.root

        let body = Entity()
        body.name = CreatureEntityNames.body
        body.addChild(loaded)
        root.addChild(body)

        applyTint(UIColor(creature.tint), to: loaded)
        return root
    }

    func assetURL(for archetype: Archetype) -> URL? {
        bundle.url(
            forResource: archetype.rawValue,
            withExtension: "usdz",
            subdirectory: Self.subdirectory
        )
    }

    /// Assets are authored in white so the tint reads as the object's colour
    /// rather than fighting a baked-in one.
    private func applyTint(_ tint: UIColor, to entity: Entity) {
        if entity.name == Self.tintableNodeName,
           let modelEntity = entity as? ModelEntity,
           var model = modelEntity.model {
            var material = SimpleMaterial(color: tint, isMetallic: false)
            material.roughness = .float(0.5)
            model.materials = model.materials.map { _ in material }
            modelEntity.model = model
        }

        for child in entity.children {
            applyTint(tint, to: child)
        }
    }
}
