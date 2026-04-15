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

    private func makeTemporaryDirectory(named prefix: String) throws -> URL {
        let url = fileManager.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
