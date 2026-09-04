import Foundation
import simd

/// A recipe for building a creature out of primitives.
///
/// This lives in `Core` rather than in `AR/` on purpose: it is pure data, it is
/// worth unit-testing, and keeping it here means the procedural renderer and a
/// future USDZ renderer read from the same description.
public struct BodyPlan: Equatable, Sendable {
    public enum Shape: String, Sendable {
        case sphere
        case box
        case capsule
    }

    /// Main body.
    public var torso: Shape
    /// Metres. A creature is roughly 0.30 m tall so it sits comfortably on a desk.
    public var torsoSize: SIMD3<Float>
    public var head: Shape
    public var headRadius: Float
    /// 0, 2 or 4. Stubby legs under the torso.
    public var limbCount: Int
    /// Spikes ringing the torso — ferro, glass, ember.
    public var spikeCount: Int
    /// A flat crest or leaf on top — verdant, paper, textil.
    public var hasCrest: Bool
    public var metallic: Float
    public var roughness: Float
    /// Emissive intensity. Void and tech glow faintly; ceramic does not.
    public var glow: Float

    public init(
        torso: Shape,
        torsoSize: SIMD3<Float>,
        head: Shape,
        headRadius: Float,
        limbCount: Int,
        spikeCount: Int,
        hasCrest: Bool,
        metallic: Float,
        roughness: Float,
        glow: Float
    ) {
        self.torso = torso
        self.torsoSize = torsoSize
        self.head = head
        self.headRadius = headRadius
        self.limbCount = limbCount
        self.spikeCount = spikeCount
        self.hasCrest = hasCrest
        self.metallic = metallic
        self.roughness = roughness
        self.glow = glow
    }
}
