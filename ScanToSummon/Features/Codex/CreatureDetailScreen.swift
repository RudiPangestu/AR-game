import SwiftUI

struct CreatureDetailScreen: View {
    let creature: Creature

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CreatureGlyphView(creature: creature)
                    .frame(height: 180)
                    .padding(.top, 12)

                VStack(spacing: 8) {
                    Text(creature.name)
                        .font(.largeTitle.weight(.bold))

                    HStack(spacing: 8) {
                        ElementBadge(element: creature.element)
                        Text(LocalizedStringKey(creature.archetype.localizationKey))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                panel {
                    StatRow(stats: creature.effectiveStats)
                }

                panel {
                    VStack(alignment: .leading, spacing: 10) {
                        row("creature.origin.title", value: originValue)
                        row("creature.level.title", value: "\(creature.level)")
                        row("creature.duplicates", value: "\(creature.duplicateCount)")
                        row("creature.found", value: creature.discoveredAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                Text("creature.duplicate.hint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var originValue: String {
        creature.sourceLabel.isEmpty
            ? String(localized: "creature.origin.unknown")
            : creature.sourceLabel
    }

    private func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(_ key: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(key)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}
