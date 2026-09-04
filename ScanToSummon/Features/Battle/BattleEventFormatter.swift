import Foundation

/// Turns engine events into display strings.
///
/// The engine never builds user-facing text itself — it emits structured
/// events — which is what lets the log be localised and lets the engine stay
/// testable without a bundle.
enum BattleEventFormatter {

    static func text(for event: BattleEvent) -> String {
        switch event.kind {
        case let .attack(actor, target, move, damage, effectiveness):
            var line = String(
                format: localized("battle.log.attack"),
                actor,
                localized(move.localizationKey),
                target,
                damage
            )
            switch effectiveness {
            case .strong: line += " " + localized("battle.log.strong")
            case .weak: line += " " + localized("battle.log.weak")
            case .neutral: break
            }
            return line

        case let .heal(actor, amount):
            return String(format: localized("battle.log.heal"), actor, amount)

        case let .defeated(name):
            return String(format: localized("battle.log.defeated"), name)

        case let .finished(outcome):
            switch outcome {
            case .victory: return localized("battle.log.victory")
            case .defeat: return localized("battle.log.defeat")
            }
        }
    }

    /// Keys are computed at runtime (a `Move`'s key, an element's key), so
    /// `NSLocalizedString` is used rather than `String(localized:)`, whose
    /// argument is built for literals.
    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
