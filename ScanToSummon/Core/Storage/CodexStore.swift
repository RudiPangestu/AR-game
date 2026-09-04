import Foundation

/// Persists the Codex as a single JSON file.
///
/// Deliberately not SwiftData: the entire dataset is a few hundred small
/// structs, a flat file needs no schema migration, and — most usefully here —
/// it can be tested as plain Swift against a temporary directory.
public struct CodexStore {
    public enum StoreError: Error {
        case directoryUnavailable
    }

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// The real on-device location: Application Support, which is backed up and
    /// not user-visible.
    public static func makeDefault(fileManager: FileManager = .default) throws -> CodexStore {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StoreError.directoryUnavailable
        }
        let directory = base.appendingPathComponent("ScanToSummon", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return CodexStore(fileURL: directory.appendingPathComponent("codex.json"))
    }

    /// Returns an empty Codex when the file does not exist yet.
    ///
    /// A corrupt file is also treated as empty rather than thrown: losing a
    /// Codex is bad, but refusing to launch is worse, and the file is rewritten
    /// on the next scan.
    public func load() -> [Creature] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([Creature].self, from: data)) ?? []
    }

    public func save(_ creatures: [Creature]) throws {
        let data = try encoder.encode(creatures)
        try data.write(to: fileURL, options: .atomic)
    }
}
