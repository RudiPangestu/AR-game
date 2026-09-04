import Foundation

/// The combat type of a creature.
///
/// There are deliberately only six, arranged as two rock-paper-scissors rings
/// so that a player can hold the entire chart in their head after one battle:
///
///     ember → verdant → aqua → ember
///     ferro → air → void → ferro
///
/// Matchups *across* the two rings are always neutral. That is intentional:
/// it keeps the chart at two facts instead of thirty.
public enum Element: String, Codable, CaseIterable, Sendable {
    case ember
    case verdant
    case aqua
    case ferro
    case air
    case void

    /// Key into `Localizable.xcstrings`.
    public var localizationKey: String { "element.\(rawValue)" }
}
