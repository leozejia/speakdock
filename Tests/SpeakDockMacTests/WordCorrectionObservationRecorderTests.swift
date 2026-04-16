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

    func testCaptureWorkspaceRecordsObservedCorrectionFromCaptureFileText() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let captureFileURL = try makeCaptureFile(contents: "Project Atlas 已经完成")
        let captureTarget = CaptureFileTarget(fileManager: fileManager)
        let recorder = WordCorrectionObservationRecorder(
            termDictionaryStore: store,
            observeCaptureText: { targetID in
                captureTarget.observedWorkspaceText(expectedTargetID: targetID)
            }
        )
        let workspace = Workspace(
            mode: .capture,
            targetID: captureFileURL.path,
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
    }

    func testCaptureWorkspaceSkipsObservationWhenCaptureFileIsUnavailable() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let captureTarget = CaptureFileTarget(fileManager: fileManager)
        let recorder = WordCorrectionObservationRecorder(
            termDictionaryStore: store,
            observeCaptureText: { targetID in
                captureTarget.observedWorkspaceText(expectedTargetID: targetID)
            }
        )
        let workspace = Workspace(
            mode: .capture,
            targetID: "/tmp/speakdock-missing-\(UUID().uuidString).md",
            startLocation: 0,
            visibleText: "project adults 已经完成",
            hasSpoken: true
        )

        try recorder.recordIfNeeded(for: workspace)

        XCTAssertEqual(store.observedCorrections, [])
    }

    func testWorkspaceWithoutSpokenTextDoesNotRecordCorrectionEvidence() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let recorder = WordCorrectionObservationRecorder(
            termDictionaryStore: store,
            observeComposeText: { _ in
                "Project Atlas 已经完成"
            }
        )
        let workspace = Workspace(
            mode: .compose,
            targetID: "compose-target",
            startLocation: 0,
            visibleText: "project adults 已经完成",
            hasSpoken: false
        )

        try recorder.recordIfNeeded(for: workspace)

        XCTAssertEqual(store.observedCorrections, [])
    }

    func testComposeWorkspaceSkipsObservationWhenCurrentTargetCannotBeReadBack() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let recorder = WordCorrectionObservationRecorder(
            termDictionaryStore: store,
            observeComposeText: { _ in nil }
        )
        let workspace = Workspace(
            mode: .compose,
            targetID: "paste-only-target",
            startLocation: 0,
            visibleText: "project adults 已经完成",
            hasSpoken: true
        )

        try recorder.recordIfNeeded(for: workspace)

        XCTAssertEqual(store.observedCorrections, [])
    }

    func testWikiWorkspaceNeverRecordsCorrectionEvidence() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let recorder = WordCorrectionObservationRecorder(
            termDictionaryStore: store,
            observeComposeText: { _ in
                XCTFail("Wiki workspace should not query compose observation")
                return nil
            },
            observeCaptureText: { _ in
                XCTFail("Wiki workspace should not query capture observation")
                return nil
            }
        )
        let workspace = Workspace(
            mode: .wiki,
            targetID: "wiki-page",
            startLocation: 0,
            visibleText: "project adults 已经完成",
            hasSpoken: true
        )

        try recorder.recordIfNeeded(for: workspace)

        XCTAssertEqual(store.observedCorrections, [])
    }

    func testComposeWorkspaceSkipsSentenceLevelRewrite() throws {
        let store = TermDictionaryStore(
            storageURL: try makeStorageURL(),
            fileManager: fileManager
        )
        let recorder = WordCorrectionObservationRecorder(
            termDictionaryStore: store,
            observeComposeText: { _ in
                "we should revisit the whole launch plan next friday"
            }
        )
        let workspace = Workspace(
            mode: .compose,
            targetID: "compose-target",
            startLocation: 0,
            visibleText: "project adults should ship next friday",
            hasSpoken: true
        )

        try recorder.recordIfNeeded(for: workspace)

        XCTAssertEqual(store.observedCorrections, [])
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

    private func makeCaptureFile(contents: String) throws -> URL {
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("capture-observation-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let fileURL = rootDirectory.appendingPathComponent("speakdock-test.md")
        let data = try XCTUnwrap(contents.data(using: .utf8))
        try data.write(to: fileURL)
        return fileURL
    }
}
