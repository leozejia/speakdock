import XCTest
@testable import SpeakDockMac
import SpeakDockCore

@MainActor
final class SubmitObservationSemanticsTests: XCTestCase {
    private let fileManager = FileManager.default

    func testSubmitKeepsVisibleTextForWordEvidenceButUsesObservedTextForRefineInput() throws {
        let storageURL = try makeStorageURL()
        let store = TermDictionaryStore(
            storageURL: storageURL,
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
            rawContext: "project adults 已经完成",
            visibleText: "project adults 已经完成",
            hasSpoken: true
        )

        try recorder.recordIfNeeded(for: workspace)

        let preparation = WorkspaceRefinePreparer().prepare(
            workspace: workspace,
            observedText: "Project Atlas 已经完成",
            configuration: RefineConfiguration(
                enabled: true,
                baseURL: "https://api.example.com/v1",
                apiKey: "token",
                model: "gpt-4.1-mini"
            )
        )

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
        XCTAssertEqual(preparation.sourceText, "Project Atlas 已经完成")
        XCTAssertEqual(preparation.modelInputText, "Project Atlas 已经完成")
        XCTAssertTrue(preparation.shouldCallModel)
    }

    private func makeStorageURL() throws -> URL {
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("submit-observation-semantics-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        return rootDirectory
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("SpeakDock", isDirectory: true)
            .appendingPathComponent("term-dictionary.json")
    }
}
