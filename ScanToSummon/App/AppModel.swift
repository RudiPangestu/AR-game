import Foundation
import SwiftUI

/// App-wide state: the Codex and its persistence.
///
/// Not annotated `@MainActor` — SwiftUI creates it during `View.init`, which is
/// not main-actor isolated, and every mutation already happens on the main
/// thread (button actions, and callbacks the AR session is pinned to).
final class AppModel: ObservableObject {
    @Published private(set) var codex: Codex
    @Published private(set) var saveFailed = false

    private let store: CodexStore?

    init() {
        let store = try? CodexStore.makeDefault()
        self.store = store
        self.codex = Codex(creatures: store?.load() ?? [])
    }

    /// Test seam: build a model over a specific file, or over nothing at all.
    init(store: CodexStore?, creatures: [Creature] = []) {
        self.store = store
        self.codex = Codex(creatures: creatures)
    }

    @discardableResult
    func insert(_ creature: Creature) -> Codex.InsertResult {
        let result = codex.insert(creature)
        persist()
        return result
    }

    var canBattle: Bool { codex.count >= BattleRules.teamSize }

    private func persist() {
        guard let store else { return }
        do {
            try store.save(codex.creatures)
            saveFailed = false
        } catch {
            // The Codex still holds everything in memory, so the session is not
            // lost — but the player should know it will not survive a relaunch.
            saveFailed = true
        }
    }
}

enum BattleRules {
    static let teamSize = 3
}
