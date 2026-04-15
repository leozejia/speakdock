import Foundation
import Observation
import SpeakDockCore

enum TermDictionaryStoreError: LocalizedError {
    case emptyCanonicalTerm
    case missingAlias

    var errorDescription: String? {
        switch self {
        case .emptyCanonicalTerm:
            AppLocalizer.string(.termDictionaryCanonicalRequired)
        case .missingAlias:
            AppLocalizer.string(.termDictionaryMissingAlias)
        }
    }
}

@MainActor
@Observable
final class TermDictionaryStore {
    static let defaultDirectoryURL: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
    }()

    static let defaultStorageURL = defaultDirectoryURL
        .appendingPathComponent("SpeakDock", isDirectory: true)
        .appendingPathComponent("term-dictionary.json")

    var confirmedDictionary: TermDictionary {
        didSet {
            persistIfReady()
        }
    }

    var pendingCandidates: [TermDictionaryCandidate] {
        didSet {
            persistIfReady()
        }
    }

    private let storageURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var isReady = false

    init(
        storageURL: URL = TermDictionaryStore.defaultStorageURL,
        fileManager: FileManager = .default
    ) {
        self.storageURL = storageURL
        self.fileManager = fileManager

        let snapshot = Self.loadSnapshot(
            from: storageURL,
            using: JSONDecoder(),
            fileManager: fileManager
        )
        self.confirmedDictionary = TermDictionary(entries: snapshot.confirmedEntries)
        self.pendingCandidates = snapshot.pendingCandidates
        self.isReady = true
    }

    func save() throws {
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let snapshot = Snapshot(
            confirmedEntries: confirmedDictionary.entries,
            pendingCandidates: pendingCandidates
        )
        let data = try encoder.encode(snapshot)
        try data.write(to: storageURL, options: .atomic)
    }

    func reload() {
        let snapshot = Self.loadSnapshot(
            from: storageURL,
            using: decoder,
            fileManager: fileManager
        )
        confirmedDictionary = TermDictionary(entries: snapshot.confirmedEntries)
        pendingCandidates = snapshot.pendingCandidates
    }

    func confirm(_ candidate: TermDictionaryCandidate) throws {
        var entries = confirmedDictionary.entries

        entries = upsert(
            entries: entries,
            canonicalTerm: candidate.canonicalTerm,
            aliases: [candidate.alias]
        )
        confirmedDictionary = TermDictionary(entries: entries)
        pendingCandidates.removeAll { $0 == candidate }
        try save()
    }

    func addEntry(canonicalTerm: String, aliases: [String]) throws {
        let normalizedCanonicalTerm = canonicalTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCanonicalTerm.isEmpty else {
            throw TermDictionaryStoreError.emptyCanonicalTerm
        }

        let normalizedAliases = normalizeAliases(
            aliases,
            canonicalTerm: normalizedCanonicalTerm
        )
        guard !normalizedAliases.isEmpty else {
            throw TermDictionaryStoreError.missingAlias
        }

        let entries = upsert(
            entries: confirmedDictionary.entries,
            canonicalTerm: normalizedCanonicalTerm,
            aliases: normalizedAliases
        )
        confirmedDictionary = TermDictionary(entries: entries)
        try save()
    }

    func removeEntry(canonicalTerm: String) throws {
        let key = canonicalKey(for: canonicalTerm)
        confirmedDictionary = TermDictionary(
            entries: confirmedDictionary.entries.filter { canonicalKey(for: $0.canonicalTerm) != key }
        )
        try save()
    }

    func dismiss(_ candidate: TermDictionaryCandidate) throws {
        pendingCandidates.removeAll { $0 == candidate }
        try save()
    }

    private func persistIfReady() {
        guard isReady else {
            return
        }

        try? save()
    }

    private static func loadSnapshot(
        from storageURL: URL,
        using decoder: JSONDecoder,
        fileManager: FileManager
    ) -> Snapshot {
        guard
            fileManager.fileExists(atPath: storageURL.path),
            let data = try? Data(contentsOf: storageURL),
            let snapshot = try? decoder.decode(Snapshot.self, from: data)
        else {
            return Snapshot(
                confirmedEntries: [],
                pendingCandidates: []
            )
        }

        return snapshot
    }

    private func upsert(
        entries: [TermDictionaryEntry],
        canonicalTerm: String,
        aliases: [String]
    ) -> [TermDictionaryEntry] {
        var updatedEntries = entries
        let key = canonicalKey(for: canonicalTerm)

        if let existingEntryIndex = updatedEntries.firstIndex(where: { canonicalKey(for: $0.canonicalTerm) == key }) {
            let mergedAliases = normalizeAliases(
                updatedEntries[existingEntryIndex].aliases + aliases,
                canonicalTerm: canonicalTerm
            )
            updatedEntries[existingEntryIndex].canonicalTerm = canonicalTerm
            updatedEntries[existingEntryIndex].aliases = mergedAliases
        } else {
            updatedEntries.append(
                TermDictionaryEntry(
                    canonicalTerm: canonicalTerm,
                    aliases: normalizeAliases(aliases, canonicalTerm: canonicalTerm)
                )
            )
        }

        return updatedEntries.sorted {
            $0.canonicalTerm.localizedCaseInsensitiveCompare($1.canonicalTerm) == .orderedAscending
        }
    }

    private func normalizeAliases(
        _ aliases: [String],
        canonicalTerm: String
    ) -> [String] {
        var seen: Set<String> = []
        var normalizedAliases: [String] = []

        for alias in aliases {
            let trimmedAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedAlias.isEmpty else {
                continue
            }

            guard canonicalKey(for: trimmedAlias) != canonicalKey(for: canonicalTerm) else {
                continue
            }

            let key = canonicalKey(for: trimmedAlias)
            guard seen.insert(key).inserted else {
                continue
            }

            normalizedAliases.append(trimmedAlias)
        }

        return normalizedAliases.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    private func canonicalKey(for text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

private struct Snapshot: Codable, Equatable {
    var confirmedEntries: [TermDictionaryEntry]
    var pendingCandidates: [TermDictionaryCandidate]
}
