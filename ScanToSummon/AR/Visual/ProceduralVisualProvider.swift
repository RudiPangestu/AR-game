import Foundation
import RealityKit
import UIKit
import simd

/// Assembles a creature out of spheres and boxes.
///
/// Only `generateSphere` and `generateBox` are used. Cones and capsules would
/// read better but arrived in later SDKs; sticking to the two primitives that
/// have existed since RealityKit 1 keeps this buildable on the whole iOS 17
/// device range without conditional compilation.
struct ProceduralVisualProvider: CreatureVisualProvider {

    func makeEntity(for creature: Creature) -> Entity {
        let plan = creature.archetype.bodyPlan
        let tint = UIColor(creature.tint)

        let root = Entity()
        root.name = CreatureEntityNames.root

        let body = Entity()
        body.name = CreatureEntityNames.body
        root.addChild(body)

        let legHeight: Float = plan.limbCount > 0 ? 0.03 : 0.0
        let torsoCenterY = legHeight + plan.torsoSize.y / 2
        let headCenterY = legHeight + plan.torsoSize.y + plan.headRadius * 0.7

        body.addChild(makeTorso(plan: plan, tint: tint, centerY: torsoCenterY))
        body.addChild(makeHead(plan: plan, tint: tint, centerY: headCenterY))

        for leg in makeLegs(plan: plan, tint: tint, height: legHeight) {
            body.addChild(leg)
        }
        for spike in makeSpikes(plan: plan, tint: tint, centerY: torsoCenterY) {
            body.addChild(spike)
        }
        if plan.hasCrest {
            body.addChild(makeCrest(plan: plan, tint: tint, headCenterY: headCenterY))
        }

        return root
    }

    // MARK: - Parts

    private func makeTorso(plan: BodyPlan, tint: UIColor, centerY: Float) -> ModelEntity {
        let entity = ModelEntity(
            mesh: unitMesh(for: plan.torso),
            materials: [bodyMaterial(plan: plan, tint: tint)]
        )
        entity.scale = plan.torsoSize
        entity.position = SIMD3(0, centerY, 0)
        return entity
    }

    private func makeHead(plan: BodyPlan, tint: UIColor, centerY: Float) -> Entity {
        let head = ModelEntity(
            mesh: unitMesh(for: plan.head),
            materials: [bodyMaterial(plan: plan, tint: tint)]
        )
        let diameter = plan.headRadius * 2
        head.scale = SIMD3(repeating: diameter)
        head.position = SIMD3(0, centerY, 0)

        // Eyes carry almost all of the "this is alive" signal, so they are
        // oversized and always high-contrast regardless of the body colour.
        let eyeRadius = plan.headRadius * 0.30
        let eyeX = plan.headRadius * 0.40
        let eyeZ = -plan.headRadius * 0.82

        for side in [Float(-1), Float(1)] {
            let sclera = ModelEntity(
                mesh: .generateSphere(radius: 0.5),
                materials: [UnlitMaterial(color: .white)]
            )
            // The eye is a child of the head, whose own transform already
            // scales by `diameter`, so both size and offset are divided back
            // out to end up in the metres they are written in above.
            sclera.scale = SIMD3(repeating: eyeRadius * 2 / diameter)
            sclera.position = SIMD3(side * eyeX, plan.headRadius * 0.12, eyeZ) / diameter

            let pupil = ModelEntity(
                mesh: .generateSphere(radius: 0.5),
                materials: [UnlitMaterial(color: UIColor(white: 0.08, alpha: 1))]
            )
            pupil.scale = SIMD3(repeating: 0.55)
            pupil.position = SIMD3(0, 0, -0.30)
            sclera.addChild(pupil)

            head.addChild(sclera)
        }

        return head
    }

    private func makeLegs(plan: BodyPlan, tint: UIColor, height: Float) -> [ModelEntity] {
        guard plan.limbCount > 0, height > 0 else { return [] }

        let material = bodyMaterial(plan: plan, tint: tint.darkened(by: 0.25))
        let offsetX = plan.torsoSize.x * 0.30
        let offsetZ = plan.torsoSize.z * 0.28

        let positions: [SIMD3<Float>]
        if plan.limbCount >= 4 {
            positions = [
                SIMD3(-offsetX, height / 2, -offsetZ),
                SIMD3(offsetX, height / 2, -offsetZ),
                SIMD3(-offsetX, height / 2, offsetZ),
                SIMD3(offsetX, height / 2, offsetZ)
            ]
        } else {
            positions = [
                SIMD3(-offsetX, height / 2, 0),
                SIMD3(offsetX, height / 2, 0)
            ]
        }

        return positions.map { position in
            let leg = ModelEntity(mesh: .generateBox(size: 1.0, cornerRadius: 0.2), materials: [material])
            leg.scale = SIMD3(plan.torsoSize.x * 0.22, height, plan.torsoSize.z * 0.22)
            leg.position = position
            return leg
        }
    }

    private func makeSpikes(plan: BodyPlan, tint: UIColor, centerY: Float) -> [ModelEntity] {
        guard plan.spikeCount > 0 else { return [] }

        let material = plan.glow > 0.3
            ? (UnlitMaterial(color: tint.brightened(by: 0.35)) as Material)
            : (bodyMaterial(plan: plan, tint: tint.brightened(by: 0.15)) as Material)

        let radius = max(plan.torsoSize.x, plan.torsoSize.z) * 0.52
        let length = radius * 0.75

        return (0..<plan.spikeCount).map { index in
            let angle = Float(index) / Float(plan.spikeCount) * 2 * .pi
            let spike = ModelEntity(mesh: .generateBox(size: 1.0, cornerRadius: 0.05), materials: [material])
            spike.scale = SIMD3(length, plan.torsoSize.y * 0.10, plan.torsoSize.z * 0.10)
            spike.position = SIMD3(
                cos(angle) * radius,
                centerY + plan.torsoSize.y * 0.10,
                sin(angle) * radius
            )
            // Point the long axis outward from the body.
            spike.orientation = simd_quatf(angle: -angle, axis: SIMD3(0, 1, 0))
            return spike
        }
    }

    private func makeCrest(plan: BodyPlan, tint: UIColor, headCenterY: Float) -> ModelEntity {
        let crest = ModelEntity(
            mesh: .generateBox(size: 1.0, cornerRadius: 0.3),
            materials: [bodyMaterial(plan: plan, tint: tint.brightened(by: 0.25))]
        )
        crest.scale = SIMD3(plan.headRadius * 0.35, plan.headRadius * 1.5, plan.headRadius * 1.1)
        crest.position = SIMD3(0, headCenterY + plan.headRadius * 1.0, plan.headRadius * 0.15)
        crest.orientation = simd_quatf(angle: -0.25, axis: SIMD3(1, 0, 0))
        return crest
    }

    // MARK: - Helpers

    private func unitMesh(for shape: BodyPlan.Shape) -> MeshResource {
        switch shape {
        case .sphere, .capsule:
            // A non-uniformly scaled sphere stands in for a capsule.
            return .generateSphere(radius: 0.5)
        case .box:
            return .generateBox(size: 1.0, cornerRadius: 0.12)
        }
    }

    private func bodyMaterial(plan: BodyPlan, tint: UIColor) -> SimpleMaterial {
        var material = SimpleMaterial(color: tint, isMetallic: plan.metallic > 0.5)
        material.roughness = .float(plan.roughness)
        return material
    }
}

extension UIColor {
    convenience init(_ color: ColorRGB) {
        self.init(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: 1.0
        )
    }

    func brightened(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        return UIColor(
            red: min(1, r + amount),
            green: min(1, g + amount),
            blue: min(1, b + amount),
            alpha: a
        )
    }

    func darkened(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        return UIColor(
            red: max(0, r - amount),
            green: max(0, g - amount),
            blue: max(0, b - amount),
            alpha: a
        )
    }
}
