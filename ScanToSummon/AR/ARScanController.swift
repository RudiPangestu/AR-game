#if !targetEnvironment(simulator)

import ARKit
import Combine
import Foundation
import RealityKit
import UIKit
import simd

/// Owns the AR session, the camera frame capture, and the placed creature.
///
/// Not compiled for the Simulator at all. RealityKit's `ARView` has no camera
/// there and has historically been unreliable, and the app is required to stay
/// fully usable in the Simulator so that Codex and Battle can be iterated on
/// without a device.
final class ARScanController: NSObject, ObservableObject, ARSessionDelegate {

    let arView = ARView(frame: .zero)

    @Published private(set) var hint: ScanHint = .starting
    /// True once the session has a usable world map, which is when scanning is
    /// allowed to produce a creature.
    @Published private(set) var isReady = false

    private let classifier = VisionClassifier()
    private let colorExtractor = DominantColorExtractor()
    private let visuals: CreatureVisualProvider

    private var summonedAnchor: AnchorEntity?
    private var bodyEntity: Entity?
    private var rootEntity: Entity?
    /// `Scene.subscribe` hands back the `Cancellable` protocol, not Combine's
    /// concrete `AnyCancellable`, so the existential is stored and cancelled by
    /// hand in `deinit` — `AnyCancellable`'s automatic cancel-on-deinit does not
    /// come along with it.
    private var updateSubscription: (any Cancellable)?
    private var elapsed: TimeInterval = 0

    init(visuals: CreatureVisualProvider = CompositeVisualProvider()) {
        self.visuals = visuals
        super.init()
        arView.session.delegate = self
        // Only lightweight state callbacks are implemented, and they publish to
        // SwiftUI, so taking them on the main queue avoids a hop per event.
        arView.session.delegateQueue = .main
        arView.automaticallyConfigureSession = false
        subscribeToSceneUpdates()
    }

    deinit {
        updateSubscription?.cancel()
    }

    // MARK: - Session lifecycle

    func start() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic

        // People occlusion needs no LiDAR and costs little, and it is most of
        // what sells a creature as being in the room rather than on the glass.
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }

        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func pause() {
        arView.session.pause()
    }

    // MARK: - Scanning

    /// Reads the current frame. Returns nil when the session has no frame yet.
    func capture() -> ScanCapture? {
        guard let frame = arView.session.currentFrame else { return nil }
        let buffer = frame.capturedImage

        // ARKit hands over the buffer in the camera's native landscape layout;
        // `.right` is what turns that into the portrait image the player sees.
        let observations = (try? classifier.classify(pixelBuffer: buffer, orientation: .right)) ?? []
        let color = colorExtractor.averageColor(pixelBuffer: buffer)

        return ScanCapture(observations: observations, averageColor: color)
    }

    // MARK: - Summoning

    /// Places the creature in the world and returns its root so the hatch
    /// animation can drive it.
    @discardableResult
    func summon(_ creature: Creature) -> Entity {
        clearSummoned()

        let anchor = AnchorEntity(world: placementTransform())
        let root = visuals.makeEntity(for: creature)
        anchor.addChild(root)
        arView.scene.addAnchor(anchor)

        summonedAnchor = anchor
        rootEntity = root
        bodyEntity = root.findEntity(named: CreatureEntityNames.body)
        return root
    }

    func clearSummoned() {
        if let anchor = summonedAnchor {
            arView.scene.removeAnchor(anchor)
        }
        summonedAnchor = nil
        rootEntity = nil
        bodyEntity = nil
    }

    /// Prefers a real surface; falls back to floating the creature in front of
    /// the camera so that a failed raycast never blocks a summon. A player
    /// pointing at a plain white wall should still get their creature.
    private func placementTransform() -> simd_float4x4 {
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        if !arView.bounds.isEmpty,
           let hit = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
            return hit.worldTransform
        }

        let camera = arView.cameraTransform
        let forward = camera.matrix.columns.2
        let position = camera.translation - SIMD3(forward.x, forward.y, forward.z) * 0.6
        return Transform(scale: .one, rotation: simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)), translation: position).matrix
    }

    // MARK: - Idle motion

    private func subscribeToSceneUpdates() {
        updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.tick(deltaTime: event.deltaTime)
        }
    }

    /// A gentle bob plus turning to face the player. Both are cheap, and
    /// together they are the difference between a model sitting on the floor
    /// and something that notices you.
    private func tick(deltaTime: TimeInterval) {
        elapsed += deltaTime

        if let body = bodyEntity {
            body.position.y = Float(sin(elapsed * 2.1)) * 0.006
        }

        guard let root = rootEntity, let anchor = summonedAnchor else { return }
        let cameraPosition = arView.cameraTransform.translation
        let creaturePosition = anchor.position(relativeTo: nil)
        let delta = cameraPosition - creaturePosition
        guard simd_length(SIMD2(delta.x, delta.z)) > 0.05 else { return }

        let targetYaw = atan2(delta.x, delta.z)
        let target = simd_quatf(angle: targetYaw, axis: SIMD3(0, 1, 0))
        root.orientation = simd_slerp(root.orientation, target, min(1, Float(deltaTime) * 3.0))
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            hint = .ready
            isReady = true
        case .notAvailable:
            hint = .starting
            isReady = false
        case .limited(let reason):
            isReady = false
            switch reason {
            case .insufficientFeatures: hint = .tooDark
            case .initializing, .relocalizing: hint = .starting
            case .excessiveMotion: hint = .moveAround
            @unknown default: hint = .moveAround
            }
        }
    }

    /// Tracking loss is common indoors — a hand over the lens does it. The
    /// session is restarted quietly rather than shown as an error, because
    /// punishing the player for it is the fastest way to lose them.
    func sessionWasInterrupted(_ session: ARSession) {
        hint = .starting
        isReady = false
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        start()
    }
}

#endif
