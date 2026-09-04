import SwiftUI

struct BattleScreen: View {
    let team: [Creature]

    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: BattleViewModel

    init(team: [Creature]) {
        self.team = team
        _model = StateObject(wrappedValue: BattleViewModel(playerTeam: team))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                unitRow(model.enemyUnits, side: .enemy)
                logPanel
                unitRow(model.playerUnits, side: .player)
                moveBar
            }
            .padding(16)

            if let outcome = model.outcome {
                OutcomeOverlay(outcome: outcome) { dismiss() }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let active = model.activeUnit {
                Text(active.side == .player ? "battle.yourTurn" : "battle.enemyTurn")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(active.side == .player ? Theme.accent : .orange)
            }
        }
    }

    private func unitRow(_ units: [BattleUnit], side: Side) -> some View {
        HStack(spacing: 10) {
            ForEach(units) { unit in
                BattleUnitView(
                    unit: unit,
                    isActive: model.activeUnit?.id == unit.id,
                    isTargeted: side == .enemy && model.selectedTargetID == unit.id
                )
                .onTapGesture {
                    guard side == .enemy, unit.isAlive else { return }
                    model.selectedTargetID = unit.id
                }
            }
        }
    }

    /// The last few lines only. A scrolling history would invite reading
    /// instead of playing.
    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(model.engine.log.suffix(4)) { event in
                Text(BattleEventFormatter.text(for: event))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .padding(12)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeOut(duration: 0.2), value: model.engine.log.count)
    }

    private var moveBar: some View {
        HStack(spacing: 12) {
            ForEach(Move.allCases, id: \.self) { move in
                Button {
                    model.play(move)
                } label: {
                    VStack(spacing: 2) {
                        Text(LocalizedStringKey(move.localizationKey))
                            .font(.subheadline.weight(.semibold))
                        if move == .skill, let cooldown = skillCooldown, cooldown > 0 {
                            Text("battle.cooldown \(cooldown)")
                                .font(.caption2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(move == .skill ? .orange : Theme.accent)
                .foregroundStyle(.black)
                .disabled(!model.canAct || !(model.activeUnit?.canUse(move) ?? false))
            }
        }
    }

    private var skillCooldown: Int? {
        model.activeUnit?.side == .player ? model.activeUnit?.skillCooldown : nil
    }
}

struct BattleUnitView: View {
    let unit: BattleUnit
    let isActive: Bool
    let isTargeted: Bool

    var body: some View {
        VStack(spacing: 5) {
            CreatureGlyphView(unit: unit)
                .frame(height: 56)
                .opacity(unit.isAlive ? 1 : 0.25)
                .grayscale(unit.isAlive ? 0 : 1)

            Text(unit.name)
                .font(.caption2.weight(.medium))
                .lineLimit(1)

            healthBar

            Text("\(unit.currentHP)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 2)
        }
        .animation(.easeOut(duration: 0.25), value: unit.currentHP)
    }

    private var borderColor: Color {
        if isTargeted { return .orange }
        if isActive { return Theme.accent }
        return .clear
    }

    private var healthBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(healthColor)
                    .frame(width: geometry.size.width * unit.hpFraction)
            }
        }
        .frame(height: 5)
    }

    private var healthColor: Color {
        switch unit.hpFraction {
        case ..<0.25: return .red
        case ..<0.55: return .yellow
        default: return Theme.accent
        }
    }
}

private struct OutcomeOverlay: View {
    let outcome: BattleOutcome
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 16) {
                Text(outcome == .victory ? "battle.victory" : "battle.defeat")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(outcome == .victory ? Theme.accent : .orange)

                Text(outcome == .victory ? "battle.victory.body" : "battle.defeat.body")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onClose) {
                    Text("battle.close")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .foregroundStyle(.black)
            }
        }
        .transition(.opacity)
    }
}
