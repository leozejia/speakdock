import XCTest
@testable import SpeakDockCore

final class WorkspaceRefinePromptTests: XCTestCase {
    func testPromptTreatsRefineAsWorkspaceOrganization() {
        let prompt = WorkspaceRefinePrompt.systemPrompt

        XCTAssertTrue(prompt.contains("工作区整理助手"))
        XCTAssertTrue(prompt.contains("如果原文已经清楚可用"))
    }

    func testPromptPreservesMeaningLanguageAndTerms() {
        let prompt = WorkspaceRefinePrompt.systemPrompt

        XCTAssertTrue(prompt.contains("保留原意"))
        XCTAssertTrue(prompt.contains("默认不翻译"))
        XCTAssertTrue(prompt.contains("术语"))
    }

    func testDisabledRefineFallsBackToCleanOnlyMode() {
        let configuration = RefineConfiguration(
            enabled: false,
            baseURL: "https://example.com/v1",
            apiKey: "secret",
            model: "gpt-5.4"
        )

        XCTAssertEqual(configuration.executionMode, .cleanOnly)
    }

    func testCleanNormalizerOnlyAppliesDeterministicCleanup() {
        let normalizer = CleanNormalizer()

        XCTAssertEqual(normalizer.normalize("嗯  你好，，世界  "), "你好，世界")
    }
}
