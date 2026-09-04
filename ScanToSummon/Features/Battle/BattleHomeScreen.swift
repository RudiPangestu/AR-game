import SwiftUI

/// Team selection. The gate before a battle, and the only screen that has to
/// explain why a player cannot fight yet.
struct BattleHomeScreen: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selectedIDs: [UUID] = []
    @State private var battleSetup: BattleSetup?

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if appModel.canBattle {
                    picker
                } else {
                    notEnoughCreatures
                }
            }
            .navigationTitle("battle.title")
            .background(Theme.background)
        }
        .fullScreenCover(item: $battleSetup) { setup in
            BattleScreen(team: setup.team)
        }
        .onAppear(perform: preselectIfNeeded)
    }

    private var picker: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(appModel.codex.sortedByPower) { creature in
                        Button {
                            toggle(creature)
                        } label: {
                            CodexCell(creature: creature)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            selectedIDs.contains(creature.id) ? Theme.accent : .clear,
                                            lineWidth: 2.5
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }

            VStack(spacing: 8) {
                Text("battle.pick \(selectedIDs.count) \(BattleRules.teamSize)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    startBattle()
                } label: {
                    Text("battle.start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .foregroundStyle(.black)
                .disabled(selectedIDs.count != BattleRules.teamSize)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }

    private var notEnoughCreatures: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("battle.needMore.title")
                .font(.headline)
            Text("battle.needMore.body \(appModel.codex.count) \(BattleRules.teamSize)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toggle(_ creature: Creature) {
        if let index = selectedIDs.firstIndex(of: creature.id) {
            selectedIDs.remove(at: index)
        } else if selectedIDs.count < BattleRules.teamSize {
            selectedIDs.append(creature.id)
        } else {
            // Replace the oldest pick rather than refusing the tap — being told
            // "no" while building a team is needless friction.
            selectedIDs.removeFirst()
            selectedIDs.append(creature.id)
        }
    }

    /// Starts the player off with their three strongest so a first battle is
    /// one tap away.
    private func preselectIfNeeded() {
        guard selectedIDs.isEmpty, appModel.canBattle else { return }
        selectedIDs = appModel.codex.suggestedTeam(size: BattleRules.teamSize).map(\.id)
    }

    private func startBattle() {
        let team = selectedIDs.compactMap { appModel.codex.creature(withID: $0) }
        guard team.count == BattleRules.teamSize else { return }
        battleSetup = BattleSetup(team: team)
    }
}

/// `fullScreenCover(item:)` needs an `Identifiable`, and a fresh identity per
/// presentation is also what makes "battle again" rebuild the engine.
private struct BattleSetup: Identifiable {
    let id = UUID()
    let team: [Creature]
}
