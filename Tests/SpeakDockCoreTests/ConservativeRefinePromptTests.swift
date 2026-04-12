import XCTest
@testable import SpeakDockCore

final class ConservativeRefinePromptTests: XCTestCase {
    func testPromptEmphasizesOnlyFixingObviousRecognitionErrors() {
        let prompt = ConservativeRefinePrompt.systemPrompt

        XCTAssertTrue(prompt.contains("只修复明显识别错误"))
        XCTAssertTrue(prompt.contains("如果原文已经正确"))
    }

    func testPromptExplicitlyForbidsPolishRewriteAndDeletion() {
        let prompt = ConservativeRefinePrompt.systemPrompt

        XCTAssertTrue(prompt.contains("不要润色"))
        XCTAssertTrue(prompt.contains("不要改写"))
        XCTAssertTrue(prompt.contains("不要删减"))
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
