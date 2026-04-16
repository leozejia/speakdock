import XCTest
@testable import SpeakDockMac
import SpeakDockCore

@MainActor
final class TermDictionaryStoreTests: XCTestCase {
    private let fileManager = FileManager.default

    func testPersistsAndReloadsConfirmedEntriesAndPendingCandidates() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        store.confirmedDictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "Project Atlas", aliases: ["project atlas"]),
        ])
        store.pendingCandidates = [
            TermDictionaryCandidate(
                canonicalTerm: "SpeakDock",
                alias: "speak dock",
                source: .manualCorrection
            ),
        ]
        try store.save()

        let reloadedStore = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        XCTAssertEqual(
            reloadedStore.confirmedDictionary,
            TermDictionary(entries: [
                TermDictionaryEntry(canonicalTerm: "Project Atlas", aliases: ["project atlas"]),
            ])
        )
        XCTAssertEqual(
            reloadedStore.pendingCandidates,
            [
                TermDictionaryCandidate(
                    canonicalTerm: "SpeakDock",
                    alias: "speak dock",
                    source: .manualCorrection
                ),
            ]
        )
        XCTAssertTrue(fileManager.fileExists(atPath: storageURL.path))
    }

    func testConfirmCandidatePromotesItIntoConfirmedDictionaryAndRemovesPendingEntry() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let candidate = TermDictionaryCandidate(
            canonicalTerm: "Project Atlas",
            alias: "project adults",
            source: .manualCorrection
        )
        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )
        store.pendingCandidates = [candidate]

        try store.confirm(candidate)

        XCTAssertEqual(
            store.confirmedDictionary,
            TermDictionary(entries: [
                TermDictionaryEntry(
                    canonicalTerm: "Project Atlas",
                    aliases: ["project adults"]
                ),
            ])
        )
        XCTAssertEqual(store.pendingCandidates, [])
    }

    func testAddEntryMergesAliasesIntoExistingEntry() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )
        store.confirmedDictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "SpeakDock", aliases: ["speak dock"]),
        ])

        try store.addEntry(
            canonicalTerm: "SpeakDock",
            aliases: ["speakdoc", "Speak Dock", "  "]
        )

        XCTAssertEqual(
            store.confirmedDictionary,
            TermDictionary(entries: [
                TermDictionaryEntry(
                    canonicalTerm: "SpeakDock",
                    aliases: ["speak dock", "speakdoc"]
                ),
            ])
        )
    }

    func testAddEntryClearsMatchingObservedCorrection() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        try store.recordManualCorrection(
            generatedText: "project adults 已经完成",
            correctedText: "Project Atlas 已经完成"
        )

        try store.addEntry(
            canonicalTerm: "Project Atlas",
            aliases: ["project adults"]
        )

        XCTAssertEqual(store.observedCorrections, [])
    }

    func testRemoveEntryAndDismissCandidatePersist() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let candidate = TermDictionaryCandidate(
            canonicalTerm: "Project Atlas",
            alias: "project adults",
            source: .manualCorrection
        )
        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )
        store.confirmedDictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "SpeakDock", aliases: ["speak dock"]),
        ])
        store.pendingCandidates = [candidate]

        try store.removeEntry(canonicalTerm: "SpeakDock")
        try store.dismiss(candidate)

        let reloadedStore = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        XCTAssertEqual(reloadedStore.confirmedDictionary, .empty)
        XCTAssertEqual(reloadedStore.pendingCandidates, [])
    }

    func testAddEntryRejectsEmptyCanonicalOrAliasList() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        XCTAssertThrowsError(
            try store.addEntry(canonicalTerm: "   ", aliases: ["speak dock"])
        ) { error in
            XCTAssertEqual(
                error.localizedDescription,
                TermDictionaryStoreError.emptyCanonicalTerm.localizedDescription
            )
        }

        XCTAssertThrowsError(
            try store.addEntry(canonicalTerm: "SpeakDock", aliases: [" ", "SpeakDock"])
        ) { error in
            XCTAssertEqual(
                error.localizedDescription,
                TermDictionaryStoreError.missingAlias.localizedDescription
            )
        }
    }

    func testRecordManualCorrectionStoresObservedEvidenceBeforePromotionThreshold() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        try store.recordManualCorrection(
            generatedText: "project adults 已经完成",
            correctedText: "Project Atlas 已经完成"
        )

        XCTAssertEqual(store.confirmedDictionary, .empty)
        XCTAssertEqual(store.pendingCandidates, [])

        let snapshot = try loadPersistedSnapshot(from: storageURL)
        let observedCorrections = try XCTUnwrap(snapshot["observedCorrections"] as? [[String: Any]])
        XCTAssertEqual(observedCorrections.count, 1)
        XCTAssertEqual(observedCorrections.first?["canonicalTerm"] as? String, "Project Atlas")
        XCTAssertEqual(observedCorrections.first?["alias"] as? String, "project adults")
        XCTAssertEqual(observedCorrections.first?["evidenceCount"] as? Int, 1)
    }

    func testRecordManualCorrectionDoesNotDuplicatePendingCandidate() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )
        store.pendingCandidates = [
            TermDictionaryCandidate(
                canonicalTerm: "Project Atlas",
                alias: "project adults",
                source: .manualCorrection
            ),
        ]

        try store.recordManualCorrection(
            generatedText: "project adults 已经完成",
            correctedText: "Project Atlas 已经完成"
        )

        XCTAssertEqual(
            store.pendingCandidates,
            [
                TermDictionaryCandidate(
                    canonicalTerm: "Project Atlas",
                    alias: "project adults",
                    source: .manualCorrection
                ),
            ]
        )
    }

    func testRecordManualCorrectionPromotesObservedCorrectionAfterThreeConsistentMatches() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        try store.recordManualCorrection(
            generatedText: "project adults 已经完成",
            correctedText: "Project Atlas 已经完成"
        )
        try store.recordManualCorrection(
            generatedText: "project adults 明天继续",
            correctedText: "Project Atlas 明天继续"
        )
        try store.recordManualCorrection(
            generatedText: "project adults 现在开始",
            correctedText: "Project Atlas 现在开始"
        )

        XCTAssertEqual(
            store.confirmedDictionary,
            TermDictionary(entries: [
                TermDictionaryEntry(
                    canonicalTerm: "Project Atlas",
                    aliases: ["project adults"]
                ),
            ])
        )
        XCTAssertEqual(store.pendingCandidates, [])

        let snapshot = try loadPersistedSnapshot(from: storageURL)
        let observedCorrections = try XCTUnwrap(snapshot["observedCorrections"] as? [[String: Any]])
        XCTAssertEqual(observedCorrections.count, 0)
    }

    func testRecordManualCorrectionDoesNotPromoteConflictingObservedMappings() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )

        try store.recordManualCorrection(
            generatedText: "project adults 已经完成",
            correctedText: "Project Atlas 已经完成"
        )
        try store.recordManualCorrection(
            generatedText: "project adults 已经完成",
            correctedText: "Project Alice 已经完成"
        )
        try store.recordManualCorrection(
            generatedText: "project adults 明天继续",
            correctedText: "Project Atlas 明天继续"
        )
        try store.recordManualCorrection(
            generatedText: "project adults 现在开始",
            correctedText: "Project Atlas 现在开始"
        )

        XCTAssertEqual(store.confirmedDictionary, .empty)
        XCTAssertEqual(store.pendingCandidates, [])

        let snapshot = try loadPersistedSnapshot(from: storageURL)
        let observedCorrections = try XCTUnwrap(snapshot["observedCorrections"] as? [[String: Any]])
        XCTAssertEqual(observedCorrections.count, 2)
        XCTAssertTrue(
            observedCorrections.contains {
                $0["canonicalTerm"] as? String == "Project Atlas"
                    && $0["alias"] as? String == "project adults"
                    && $0["evidenceCount"] as? Int == 3
            }
        )
        XCTAssertTrue(
            observedCorrections.contains {
                $0["canonicalTerm"] as? String == "Project Alice"
                    && $0["alias"] as? String == "project adults"
                    && $0["evidenceCount"] as? Int == 1
            }
        )
    }

    func testRecordManualCorrectionDoesNotAddAlreadyConfirmedAlias() throws {
        let rootDirectory = try makeTemporaryDirectory(named: "term-dictionary-store")
        let storageURL = rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")

        let store = TermDictionaryStore(
            storageURL: storageURL,
            fileManager: fileManager
        )
        store.confirmedDictionary = TermDictionary(entries: [
            TermDictionaryEntry(
                canonicalTerm: "Project Atlas",
                aliases: ["project adults"]
            ),
        ])

        try store.recordManualCorrection(
            generatedText: "project adults 已经完成",
            correctedText: "Project Atlas 已经完成"
        )

        XCTAssertEqual(store.pendingCandidates, [])
    }

    private func makeTemporaryDirectory(named prefix: String) throws -> URL {
        let url = fileManager.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func loadPersistedSnapshot(from storageURL: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: storageURL)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return object
    }
}
