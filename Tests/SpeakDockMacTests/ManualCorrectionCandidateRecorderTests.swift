import XCTest
@testable import SpeakDockMac
import SpeakDockCore

@MainActor
final class ManualCorrectionCandidateRecorderTests: XCTestCase {
    private let fileManager = FileManager.default

    func testComposeWorkspaceRecordsPendingCandidateFromObservedText() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let recorder = ManualCorrectionCandidateRecorder(
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
