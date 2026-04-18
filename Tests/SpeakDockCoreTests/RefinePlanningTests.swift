import XCTest
@testable import SpeakDockCore

final class RefinePlanningTests: XCTestCase {
    func testRecognitionCommitPreparationAlwaysStaysCleanOnlyAndSkipsASRCorrectionByDefault() {
        let preparer = RecognitionCommitPreparer()
        let preparation = preparer.prepare(
            transcript: "嗯  Project Atlas，，",
            configuration: configuredRefineConfiguration()
        )

        XCTAssertEqual(preparation.committedText, "Project Atlas，")
        XCTAssertFalse(preparation.shouldCallASRCorrection)
    }

    func testWorkspaceRefinePreparationPrefersObservedCurrentTextAndEnablesModelWhenConfigured() {
        let preparer = WorkspaceRefinePreparer()
        let workspace = Workspace(
            mode: .compose,
            targetID: "chat-box",
            startLocation: 0,
            rawContext: "第一版口述",
            visibleText: "屏幕里的当前文本",
            hasSpoken: true
        )

        let preparation = preparer.prepare(
            workspace: workspace,
            observedText: "  用户手改后的最终文本  ",
            configuration: configuredRefineConfiguration()
        )

        XCTAssertEqual(preparation.sourceText, "用户手改后的最终文本")
        XCTAssertEqual(preparation.modelInputText, "用户手改后的最终文本")
        XCTAssertTrue(preparation.shouldCallModel)
    }

    func testWorkspaceRefinePreparationFallsBackToVisibleTextAndSkipsModelWhenConfigurationIsIncomplete() {
        let preparer = WorkspaceRefinePreparer()
        let workspace = Workspace(
            mode: .compose,
            targetID: "chat-box",
            startLocation: 0,
            rawContext: "原始口述",
            visibleText: "  当前工作区文本  ",
            hasSpoken: true
        )

        let preparation = preparer.prepare(
            workspace: workspace,
            observedText: nil,
            configuration: RefineConfiguration(
                enabled: true,
                baseURL: "",
                apiKey: "token",
                model: "gpt-4.1-mini"
            )
        )

        XCTAssertEqual(preparation.sourceText, "当前工作区文本")
        XCTAssertEqual(preparation.modelInputText, "当前工作区文本")
        XCTAssertFalse(preparation.shouldCallModel)
    }

    private func configuredRefineConfiguration() -> RefineConfiguration {
        RefineConfiguration(
            enabled: true,
            baseURL: "https://api.example.com/v1",
            apiKey: "token",
            model: "gpt-4.1-mini"
        )
    }
}
