#if !targetEnvironment(simulator)

import Foundation
import RealityKit
import UIKit
import simd

/// The three seconds the whole game is built around.
///
/// An egg appears on the surface, shudders twice, then bursts and the creature
/// pops out. Everything is deliberately fast: the player is standing with an
/// arm raised, and a slow reveal is a tiring reveal.
enum HatchEffect {

    static let totalDuration: TimeInterval = 2.2

    /// Runs the sequence on an already-summoned creature root.
    /// - Parameter completion: called on the main queue when the creature is
    ///   fully visible.
    static func play(on root: Entity, tint: UIColor, completion: @escaping () -> Void) {
        // Hide the creature until the egg breaks.
        let finalScale = root.scale
        root.scale = .zero

        let egg = makeEgg(tint: tint)
        egg.scale = .zero
        root.parent?.addChild(egg)

        Haptics.tick()
        egg.move(
            to: Transform(scale: SIMD3(repeating: 1), rotation: egg.orientation, translation: egg.position),
            relativeTo: egg.parent,
            duration: 0.35,
            timingFunction: .easeOut
        )

        shudder(egg, at: 0.45)
        shudder(egg, at: 0.85)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            Haptics.burst()
            egg.removeFromParent()
            spawnBurst(tint: tint, around: root)

            // Overshoot then settle — the pop is what makes it feel alive.
            root.scale = finalScale * 0.01
            root.move(
                to: Transform(scale: finalScale * 1.18, rotation: root.orientation, translation: root.position),
                relativeTo: root.parent,
                duration: 0.28,
                timingFunction: .easeOut
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                root.move(
                    to: Transform(scale: finalScale, rotation: root.orientation, translation: root.position),
                    relativeTo: root.parent,
                    duration: 0.20,
                    timingFunction: .easeInOut
                )
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                Haptics.success()
                completion()
            }
        }
    }

    // MARK: - Pieces

    private static func makeEgg(tint: UIColor) -> ModelEntity {
        var material = SimpleMaterial(color: tint.darkened(by: 0.1), isMetallic: false)
        material.roughness = .float(0.35)

        let egg = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material])
        egg.scale = SIMD3(0.11, 0.14, 0.11)
        egg.position = SIMD3(0, 0.07, 0)
        egg.name = "egg"
        return egg
    }

    private static func shudder(_ entity: Entity, at delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard entity.parent != nil else { return }
            Haptics.crack()
            let tilted = simd_quatf(angle: 0.16, axis: SIMD3(0, 0, 1))
            entity.move(
                to: Transform(scale: entity.scale, rotation: tilted, translation: entity.position),
                relativeTo: entity.parent,
                duration: 0.08,
                timingFunction: .easeInOut
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                guard entity.parent != nil else { return }
                entity.move(
                    to: Transform(
                        scale: entity.scale,
                        rotation: simd_quatf(angle: -0.16, axis: SIMD3(0, 0, 1)),
                        translation: entity.position
                    ),
                    relativeTo: entity.parent,
                    duration: 0.10,
                    timingFunction: .easeInOut
                )
            }
        }
    }

    /// Shards flung outward, then cleaned up. Cheap stand-in for a particle
    /// system, and at this size the difference is not visible.
    private static func spawnBurst(tint: UIColor, around root: Entity) {
        guard let parent = root.parent else { return }
        let material = UnlitMaterial(color: tint.brightened(by: 0.3))
        let count = 14

        for index in 0..<count {
            let shard = ModelEntity(mesh: .generateBox(size: 1.0, cornerRadius: 0.1), materials: [material])
            shard.scale = SIMD3(repeating: 0.012)
            shard.position = SIMD3(0, 0.07, 0)
            parent.addChild(shard)

            let angle = Float(index) / Float(count) * 2 * .pi
            let radius = Float.random(in: 0.12...0.24)
            let target = SIMD3(cos(angle) * radius, Float.random(in: 0.10...0.30), sin(angle) * radius)

            shard.move(
                to: Transform(scale: SIMD3(repeating: 0.002), rotation: shard.orientation, translation: target),
                relativeTo: parent,
                duration: 0.6,
                timingFunction: .easeOut
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                shard.removeFromParent()
            }
        }
    }
}

#endif
