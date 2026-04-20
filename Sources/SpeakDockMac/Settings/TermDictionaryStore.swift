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
    static let defaultExportFileName = "SpeakDock-TermDictionary.json"

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

    private(set) var observedCorrections: [ObservedWordCorrection] {
        didSet {
            persistIfReady()
        }
    }

    private(set) var learningEvents: [TermDictionaryLearningEvent] {
        didSet {
            persistIfReady()
        }
    }

    private let storageURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let candidateExtractor = TermDictionaryCandidateExtractor()
    private let observationPromotionThreshold: Int
    private let maximumLearningEvents = 200
    private var isReady = false

    init(
        storageURL: URL = TermDictionaryStore.defaultStorageURL,
        fileManager: FileManager = .default,
        observationPromotionThreshold: Int = 3
    ) {
        self.storageURL = storageURL
        self.fileManager = fileManager
        self.observationPromotionThreshold = max(1, observationPromotionThreshold)

        let snapshot = Self.loadSnapshot(
            from: storageURL,
            using: JSONDecoder(),
            fileManager: fileManager
        )
        self.confirmedDictionary = TermDictionary(entries: snapshot.confirmedEntries)
        self.pendingCandidates = snapshot.pendingCandidates
        self.observedCorrections = snapshot.observedCorrections
        self.learningEvents = snapshot.learningEvents
        self.isReady = true
    }

    func save() throws {
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let snapshot = currentSnapshot()
        let data = try encoder.encode(snapshot)
        try data.write(to: storageURL, options: .atomic)
    }

    func exportSnapshot(to exportURL: URL) throws {
        try fileManager.createDirectory(
            at: exportURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let exportEncoder = JSONEncoder()
        exportEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try exportEncoder.encode(currentSnapshot())
        try data.write(to: exportURL, options: .atomic)
    }

    func reload() {
        let snapshot = Self.loadSnapshot(
            from: storageURL,
            using: decoder,
            fileManager: fileManager
        )
        confirmedDictionary = TermDictionary(entries: snapshot.confirmedEntries)
        pendingCandidates = snapshot.pendingCandidates
        observedCorrections = snapshot.observedCorrections
        learningEvents = snapshot.learningEvents
    }

    func confirm(_ candidate: TermDictionaryCandidate) throws {
        var entries = confirmedDictionary.entries

        entries = upsert(
            entries: entries,
            canonicalTerm: candidate.canonicalTerm,
            aliases: [candidate.alias]
        )
        confirmedDictionary = TermDictionary(entries: entries)
        removeObservedCorrections(
            canonicalTerm: candidate.canonicalTerm,
            aliases: [candidate.alias]
        )
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
        removeObservedCorrections(
            canonicalTerm: normalizedCanonicalTerm,
            aliases: normalizedAliases
        )
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

    func recordManualCorrection(
        generatedText: String,
        correctedText: String
    ) throws {
        let candidates = candidateExtractor.candidates(
            generatedText: generatedText,
            correctedText: correctedText
        )
        for candidate in candidates {
            if confirmedDictionaryContains(candidate) {
                appendLearningEvent(
                    canonicalTerm: candidate.canonicalTerm,
                    alias: candidate.alias,
                    outcome: .skippedConfirmed,
                    evidenceCount: 0
                )
                continue
            }

            recordObservedCorrection(candidate)
        }

        try save()
    }

    func learningEventCount(for outcome: TermDictionaryLearningEvent.Outcome) -> Int {
        learningEvents.reduce(into: 0) { count, event in
            if event.outcome == outcome {
                count += 1
            }
        }
    }

    func recentLearningEvents(limit: Int) -> [TermDictionaryLearningEvent] {
        guard limit > 0 else {
            return []
        }

        return Array(learningEvents.suffix(limit).reversed())
    }

    private func currentSnapshot() -> Snapshot {
        Snapshot(
            confirmedEntries: confirmedDictionary.entries,
            pendingCandidates: pendingCandidates,
            observedCorrections: observedCorrections,
            learningEvents: learningEvents
        )
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
                pendingCandidates: [],
                observedCorrections: [],
                learningEvents: []
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

    private func confirmedDictionaryContains(_ candidate: TermDictionaryCandidate) -> Bool {
        let candidateCanonicalKey = canonicalKey(for: candidate.canonicalTerm)
        let candidateAliasKey = canonicalKey(for: candidate.alias)

        return confirmedDictionary.entries.contains { entry in
            canonicalKey(for: entry.canonicalTerm) == candidateCanonicalKey
                && entry.aliases.contains { alias in
                    canonicalKey(for: alias) == candidateAliasKey
                }
        }
    }

    private func hasObservedConflict(aliasKey: String, expectedCanonicalKey: String) -> Bool {
        observedCorrections.contains { observation in
            canonicalKey(for: observation.alias) == aliasKey
                && canonicalKey(for: observation.canonicalTerm) != expectedCanonicalKey
        }
    }

    private func confirmedDictionaryHasConflict(aliasKey: String, expectedCanonicalKey: String) -> Bool {
        confirmedDictionary.entries.contains { entry in
            canonicalKey(for: entry.canonicalTerm) != expectedCanonicalKey
                && entry.aliases.contains { alias in
                    canonicalKey(for: alias) == aliasKey
                }
        }
    }

    private func canonicalKey(for text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func removeObservedCorrections(
        canonicalTerm: String,
        aliases: [String]
    ) {
        let canonicalTermKey = canonicalKey(for: canonicalTerm)
        let aliasKeys = Set(aliases.map(canonicalKey(for:)))

        observedCorrections.removeAll { observation in
            canonicalKey(for: observation.canonicalTerm) == canonicalTermKey
                && aliasKeys.contains(canonicalKey(for: observation.alias))
        }
    }

    private func recordObservedCorrection(_ candidate: TermDictionaryCandidate) {
        let candidateCanonicalKey = canonicalKey(for: candidate.canonicalTerm)
        let candidateAliasKey = canonicalKey(for: candidate.alias)

        if let index = observedCorrections.firstIndex(where: {
            canonicalKey(for: $0.canonicalTerm) == candidateCanonicalKey
                && canonicalKey(for: $0.alias) == candidateAliasKey
        }) {
            observedCorrections[index].evidenceCount += 1
        } else {
            observedCorrections.append(
                ObservedWordCorrection(
                    canonicalTerm: candidate.canonicalTerm,
                    alias: candidate.alias,
                    evidenceCount: 1
                )
            )
        }

        guard let observation = observedCorrections.first(where: {
            canonicalKey(for: $0.canonicalTerm) == candidateCanonicalKey
                && canonicalKey(for: $0.alias) == candidateAliasKey
        }) else {
            return
        }

        guard observation.evidenceCount >= observationPromotionThreshold else {
            appendLearningEvent(
                canonicalTerm: observation.canonicalTerm,
                alias: observation.alias,
                outcome: .observed,
                evidenceCount: observation.evidenceCount
            )
            return
        }

        guard !hasObservedConflict(aliasKey: candidateAliasKey, expectedCanonicalKey: candidateCanonicalKey) else {
            appendLearningEvent(
                canonicalTerm: observation.canonicalTerm,
                alias: observation.alias,
                outcome: .conflicted,
                evidenceCount: observation.evidenceCount
            )
            return
        }

        guard !confirmedDictionaryHasConflict(aliasKey: candidateAliasKey, expectedCanonicalKey: candidateCanonicalKey) else {
            appendLearningEvent(
                canonicalTerm: observation.canonicalTerm,
                alias: observation.alias,
                outcome: .conflicted,
                evidenceCount: observation.evidenceCount
            )
            return
        }

        let entries = upsert(
            entries: confirmedDictionary.entries,
            canonicalTerm: observation.canonicalTerm,
            aliases: [observation.alias]
        )
        confirmedDictionary = TermDictionary(entries: entries)
        observedCorrections.removeAll { observationCandidate in
            canonicalKey(for: observationCandidate.alias) == candidateAliasKey
        }
        pendingCandidates.removeAll { pendingCandidate in
            canonicalKey(for: pendingCandidate.alias) == candidateAliasKey
        }

        appendLearningEvent(
            canonicalTerm: observation.canonicalTerm,
            alias: observation.alias,
            outcome: .promoted,
            evidenceCount: observation.evidenceCount
        )
    }

    private func appendLearningEvent(
        canonicalTerm: String,
        alias: String,
        outcome: TermDictionaryLearningEvent.Outcome,
        evidenceCount: Int
    ) {
        learningEvents.append(
            TermDictionaryLearningEvent(
                canonicalTerm: canonicalTerm,
                alias: alias,
                outcome: outcome,
                evidenceCount: evidenceCount
            )
        )

        if learningEvents.count > maximumLearningEvents {
            learningEvents.removeFirst(learningEvents.count - maximumLearningEvents)
        }
    }
}

private struct Snapshot: Codable, Equatable {
    var confirmedEntries: [TermDictionaryEntry]
    var pendingCandidates: [TermDictionaryCandidate]
    var observedCorrections: [ObservedWordCorrection]
    var learningEvents: [TermDictionaryLearningEvent]

    init(
        confirmedEntries: [TermDictionaryEntry],
        pendingCandidates: [TermDictionaryCandidate],
        observedCorrections: [ObservedWordCorrection],
        learningEvents: [TermDictionaryLearningEvent]
    ) {
        self.confirmedEntries = confirmedEntries
        self.pendingCandidates = pendingCandidates
        self.observedCorrections = observedCorrections
        self.learningEvents = learningEvents
    }

    private enum CodingKeys: String, CodingKey {
        case confirmedEntries
        case pendingCandidates
        case observedCorrections
        case learningEvents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confirmedEntries = try container.decodeIfPresent([TermDictionaryEntry].self, forKey: .confirmedEntries) ?? []
        pendingCandidates = try container.decodeIfPresent([TermDictionaryCandidate].self, forKey: .pendingCandidates) ?? []
        observedCorrections = try container.decodeIfPresent([ObservedWordCorrection].self, forKey: .observedCorrections) ?? []
        learningEvents = try container.decodeIfPresent([TermDictionaryLearningEvent].self, forKey: .learningEvents) ?? []
    }
}
