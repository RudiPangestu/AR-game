import SwiftUI

struct CodexScreen: View {
    @EnvironmentObject private var appModel: AppModel

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if appModel.codex.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("codex.title")
            .background(Theme.background)
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(appModel.codex.sortedByDiscovery) { creature in
                    NavigationLink {
                        CreatureDetailScreen(creature: creature)
                    } label: {
                        CodexCell(creature: creature)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .background(Theme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("codex.empty.title")
                .font(.headline)
            Text("codex.empty.body")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CodexCell: View {
    let creature: Creature

    var body: some View {
        VStack(spacing: 6) {
            CreatureGlyphView(creature: creature)
                .frame(height: 76)

            Text(creature.name)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)

            ElementBadge(element: creature.element)

            if creature.duplicateCount > 0 {
                Text("creature.level \(creature.level)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
