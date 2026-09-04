import Combine
import Foundation
import SwiftUI

#if !targetEnvironment(simulator)
import ARKit
import UIKit
#endif

final class ScanViewModel: ObservableObject {

    enum Phase: Equatable {
        case idle
        /// Classifying the frame.
        case working
        /// The egg is on screen and cracking.
        case hatching(Creature)
        case revealed(creature: Creature, isNew: Bool)
    }

    @Published private(set) var phase: Phase = .idle

    /// Mirrored from the AR controller.
    ///
    /// SwiftUI only observes the object a view actually holds, so a `@Published`
    /// on a nested `ObservableObject` would change without ever redrawing the
    /// hint. Republishing it here is what makes the tracking hint live.
    @Published private(set) var hint: ScanHint = .starting

    #if !targetEnvironment(simulator)
    let controller = ARScanController()
    #endif

    private var cancellables = Set<AnyCancellable>()
    private let factory = CreatureFactory()

    init() {
        #if !targetEnvironment(simulator)
        // `assign(to:on:)` would retain self through the subscription.
        controller.$hint
            .removeDuplicates()
            .sink { [weak self] hint in self?.hint = hint }
            .store(in: &cancellables)
        #endif
    }

    var isARAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return ARWorldTrackingConfiguration.isSupported
        #endif
    }

    var isBusy: Bool {
        switch phase {
        case .idle, .revealed: return false
        case .working, .hatching: return true
        }
    }

    // MARK: - Lifecycle

    func onAppear() {
        #if !targetEnvironment(simulator)
        controller.start()
        #endif
    }

    func onDisappear() {
        #if !targetEnvironment(simulator)
        controller.pause()
        #endif
    }

    // MARK: - Scanning

    func scan(into appModel: AppModel) {
        guard case .idle = phase else { return }
        phase = .working

        #if targetEnvironment(simulator)
        complete(capture: Self.simulatedCapture(), into: appModel)
        #else
        guard let capture = controller.capture() else {
            // No frame yet — the session is still warming up.
            Haptics.failure()
            phase = .idle
            return
        }
        complete(capture: capture, into: appModel)
        #endif
    }

    func reset() {
        #if !targetEnvironment(simulator)
        controller.clearSummoned()
        #endif
        phase = .idle
    }

    private func complete(capture: ScanCapture, into appModel: AppModel) {
        let creature = factory.make(
            observations: capture.observations,
            averageColor: capture.averageColor
        )

        // Insert first, then reveal: what the player is shown is the creature as
        // the Codex actually holds it, including the bumped duplicate count.
        let result = appModel.insert(creature)
        let stored: Creature
        let isNew: Bool
        switch result {
        case .discovered(let value):
            stored = value
            isNew = true
        case .duplicate(let value):
            stored = value
            isNew = false
        }

        #if targetEnvironment(simulator)
        phase = .hatching(stored)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.phase = .revealed(creature: stored, isNew: isNew)
        }
        #else
        phase = .hatching(stored)
        let root = controller.summon(stored)
        HatchEffect.play(on: root, tint: UIColor(stored.tint)) { [weak self] in
            self?.phase = .revealed(creature: stored, isNew: isNew)
        }
        #endif
    }

    #if targetEnvironment(simulator)
    /// The Simulator has no camera, so scanning invents a plausible reading.
    ///
    /// This exists so that Codex, battles and the reveal flow can be worked on
    /// without a device — not as a gameplay feature. It is compiled out of every
    /// build that runs on real hardware.
    private static func simulatedCapture() -> ScanCapture {
        let words = LabelMap.vocabulary.values.flatMap { $0 }
        let label = words.randomElement() ?? "mug"
        return ScanCapture(
            observations: [ScanObservation(label: label, confidence: 0.62)],
            averageColor: ColorRGB(
                red: Double.random(in: 0.2...0.9),
                green: Double.random(in: 0.2...0.9),
                blue: Double.random(in: 0.2...0.9)
            )
        )
    }
    #endif
}
