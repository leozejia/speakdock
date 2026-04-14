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

    private func makeTemporaryDirectory(named prefix: String) throws -> URL {
        let url = fileManager.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
