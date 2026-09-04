import Foundation

/// One guess from the image classifier.
public struct ScanObservation: Equatable, Sendable {
    public let label: String
    public let confidence: Double

    public init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}

public struct ScanMatch: Equatable, Sendable {
    public let archetype: Archetype
    /// The label the decision was actually made from, shown to the player.
    public let label: String
    /// False when nothing was recognised and we fell back to `void`.
    public let isConfident: Bool

    public init(archetype: Archetype, label: String, isConfident: Bool) {
        self.archetype = archetype
        self.label = label
        self.isConfident = isConfident
    }
}

/// Turns classifier output into an archetype.
public struct ArchetypeMapper {

    /// Vision's classifier spreads confidence across ~1300 categories, so even
    /// a correct top guess often sits around 0.2. This threshold is low on
    /// purpose — a wrong-but-plausible creature is more fun than a refusal.
    public let confidenceThreshold: Double

    /// How many of the classifier's guesses to consider before giving up.
    public let candidateDepth: Int

    public init(confidenceThreshold: Double = 0.10, candidateDepth: Int = 5) {
        self.confidenceThreshold = confidenceThreshold
        self.candidateDepth = candidateDepth
    }

    public func map(observations: [ScanObservation]) -> ScanMatch {
        let ranked = observations
            .sorted { $0.confidence > $1.confidence }
            .prefix(candidateDepth)

        for observation in ranked where observation.confidence >= confidenceThreshold {
            if let archetype = archetype(for: observation.label) {
                return ScanMatch(
                    archetype: archetype,
                    label: Self.prettify(observation.label),
                    isConfident: true
                )
            }
        }

        // Nothing matched. This is a designed outcome, not an error: the player
        // gets a Void creature and the app treats it as a discovery. Per the
        // brainstorm doc, the machine is allowed to be a bad reader.
        let fallbackLabel = ranked.first.map { Self.prettify($0.label) } ?? ""
        return ScanMatch(archetype: .void, label: fallbackLabel, isConfident: false)
    }

    /// Resolves a single label such as `"coffee_table"`.
    ///
    /// Words are checked back-to-front because English compounds put the head
    /// noun last: a "coffee table" is a table, a "water bottle" is a bottle,
    /// a "teddy bear" is a bear. Scanning forwards would get all three wrong.
    public func archetype(for label: String) -> Archetype? {
        let words = Self.tokenize(label)
        for word in words.reversed() {
            if let match = LabelMap.wordIndex[word] {
                return match
            }
            // Cheap plural handling: "leaves" and "shoes" both appear.
            if word.hasSuffix("s"), let match = LabelMap.wordIndex[String(word.dropLast())] {
                return match
            }
        }
        return nil
    }

    static func tokenize(_ label: String) -> [String] {
        label
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    /// `"coffee_mug"` → `"Coffee Mug"`.
    static func prettify(_ label: String) -> String {
        tokenize(label)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
