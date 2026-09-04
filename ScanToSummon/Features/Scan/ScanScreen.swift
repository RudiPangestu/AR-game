import SwiftUI

#if !targetEnvironment(simulator)
import RealityKit
import UIKit

/// Hosts the `ARView` the controller owns.
struct ARViewContainer: UIViewRepresentable {
    let controller: ARScanController

    func makeUIView(context: Context) -> ARView { controller.arView }
    func updateUIView(_ uiView: ARView, context: Context) {}
}
#endif

struct ScanScreen: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var model = ScanViewModel()

    var body: some View {
        ZStack {
            cameraLayer
                .ignoresSafeArea()

            VStack {
                hintBar
                Spacer()
                controls
            }
            .padding()
        }
        .background(Theme.background)
        .onAppear { model.onAppear() }
        .onDisappear { model.onDisappear() }
    }

    // MARK: - Camera

    @ViewBuilder
    private var cameraLayer: some View {
        if model.isARAvailable {
            #if !targetEnvironment(simulator)
            ZStack {
                ARViewContainer(controller: model.controller)
                reticle
            }
            #else
            unsupportedPlaceholder
            #endif
        } else {
            unsupportedPlaceholder
        }
    }

    /// Marks the part of the frame that is actually classified, so the player
    /// can tell what the app is looking at instead of guessing.
    private var reticle: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height) * 0.62
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.accent.opacity(model.isBusy ? 0.25 : 0.85), lineWidth: 2)
                .frame(width: side, height: side)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .animation(.easeInOut(duration: 0.25), value: model.isBusy)
        }
        .allowsHitTesting(false)
    }

    private var unsupportedPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "iphone.gen3.slash")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("scan.unsupported.title")
                .font(.headline)
            Text("scan.unsupported.body")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    // MARK: - Overlays

    private var hintKey: LocalizedStringKey? {
        guard model.isARAvailable else { return nil }
        switch model.hint {
        case .starting: return "scan.hint.starting"
        case .moveAround: return "scan.hint.moveAround"
        case .tooDark: return "scan.hint.tooDark"
        case .ready: return "scan.hint.ready"
        }
    }

    @ViewBuilder
    private var hintBar: some View {
        if let hintKey {
            Text(hintKey)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch model.phase {
        case .idle:
            scanButton
        case .working, .hatching:
            ProgressView()
                .controlSize(.large)
                .padding(.bottom, 24)
        case .revealed(let creature, let isNew):
            RevealCard(creature: creature, isNew: isNew) {
                model.reset()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var scanButton: some View {
        Button {
            model.scan(into: appModel)
        } label: {
            Label("scan.button", systemImage: "viewfinder")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .foregroundStyle(.black)
    }
}

/// What the player sees the instant the creature lands.
private struct RevealCard: View {
    let creature: Creature
    let isNew: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(isNew ? "scan.result.discovered" : "scan.result.duplicate")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)

            HStack(spacing: 14) {
                CreatureGlyphView(creature: creature)
                    .frame(width: 76, height: 76)

                VStack(alignment: .leading, spacing: 4) {
                    Text(creature.name)
                        .font(.title3.weight(.bold))
                    HStack(spacing: 6) {
                        ElementBadge(element: creature.element)
                        Text("creature.level \(creature.level)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    originLine
                }
                Spacer(minLength: 0)
            }

            StatRow(stats: creature.effectiveStats)

            Button(action: onDismiss) {
                Text("scan.again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .foregroundStyle(.black)
        }
        .padding(16)
        .background(Theme.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// Showing the raw label is a deliberate choice: seeing "Coffee Mug →
    /// Aqualin" is most of what makes the scan feel like it understood
    /// something, and when it is wrong, the wrongness is the joke rather than a
    /// bug.
    @ViewBuilder
    private var originLine: some View {
        if creature.sourceLabel.isEmpty {
            Text("scan.result.unknown")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("creature.origin \(creature.sourceLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct StatRow: View {
    let stats: Stats

    var body: some View {
        HStack(spacing: 0) {
            cell("creature.hp", stats.hp)
            cell("creature.attack", stats.attack)
            cell("creature.defense", stats.defense)
            cell("creature.speed", stats.speed)
        }
    }

    private func cell(_ key: LocalizedStringKey, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(key)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity)
    }
}
