import XCTest
@testable import SpeakDockMac
import SpeakDockCore

@MainActor
final class WordCorrectionObservationRecorderTests: XCTestCase {
    private let fileManager = FileManager.default

    func testComposeWorkspaceRecordsObservedCorrectionFromObservedText() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let recorder = WordCorrectionObservationRecorder(
            termDictionaryStore: store,
            observeComposeText: { targetID in
                XCTAssertEqual(targetID, "compose-target")
                return "Project Atlas 已经完成"
            }
        )
        let workspace = Workspace(
            mode: .compose,
            targetID: "compose-target",
            startLocation: 0,
            visibleText: "project adults 已经完成",
            hasSpoken: true
        )

        try recorder.recordIfNeeded(for: workspace)

        XCTAssertEqual(
            store.observedCorrections,
            [
                ObservedWordCorrection(
                    canonicalTerm: "Project Atlas",
                    alias: "project adults",
                    evidenceCount: 1
                ),
            ]
        )
        XCTAssertEqual(store.pendingCandidates, [])
    }

    private func makeStorageURL() throws -> URL {
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("manual-correction-recorder-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        return rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")
    }
}
