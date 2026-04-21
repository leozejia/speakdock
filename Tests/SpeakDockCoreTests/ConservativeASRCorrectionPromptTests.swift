import XCTest
@testable import SpeakDockCore

final class ConservativeASRCorrectionPromptTests: XCTestCase {
    func testMakeUserPromptAddsStructuredIdentifierHintsForMixedEngineeringFragments() {
        let prompt = ConservativeASRCorrectionPrompt.makeUserPrompt(
            for: "这个字段用 should change 就行，主候选是 mlx community qwen three point five zero point eight b opt iq four bit"
        )

        XCTAssertTrue(prompt.contains("以下工程片段如果明显是在指向固定写法，优先恢复成右侧格式"))
        XCTAssertTrue(prompt.contains("should change -> should_change"))
        XCTAssertTrue(prompt.contains("mlx community -> mlx-community"))
        XCTAssertTrue(prompt.contains("qwen three point five -> Qwen3.5"))
        XCTAssertTrue(prompt.contains("zero point eight b -> 0.8B"))
        XCTAssertTrue(prompt.contains("opt iq -> OptiQ"))
        XCTAssertTrue(prompt.contains("four bit -> 4bit"))
    }

    func testMakeUserPromptAddsProductTermHintsWhenKnownTermsAreHit() {
        let prompt = ConservativeASRCorrectionPrompt.makeUserPrompt(
            for: "queen three asr 先别删，swift ui 页面先别动，apple speech 先当默认"
        )

        XCTAssertTrue(prompt.contains("以下术语如果明显是在指向固定产品或技术名，优先恢复成右侧写法"))
        XCTAssertTrue(prompt.contains("queen three asr -> Qwen3-ASR"))
        XCTAssertTrue(prompt.contains("swift ui -> SwiftUI"))
        XCTAssertTrue(prompt.contains("apple speech -> Apple Speech"))
    }

    func testMakeUserPromptAddsHomophoneHintsWhenKnownErrorsAreHit() {
        let prompt = ConservativeASRCorrectionPrompt.makeUserPrompt(
            for: "今天先测图表组，这个版本先看邮化，后面重点观册"
        )

        XCTAssertTrue(prompt.contains("以下词如果明显是同音误识别，优先恢复成右侧写法"))
        XCTAssertTrue(prompt.contains("图表组 -> 对照组"))
        XCTAssertTrue(prompt.contains("邮化 -> 优化"))
        XCTAssertTrue(prompt.contains("观册 -> 观测"))
    }

    func testMakeUserPromptAddsWholeModelIdentifierHintsWhenKnownPhrasesAreHit() {
        let prompt = ConservativeASRCorrectionPrompt.makeUserPrompt(
            for: "主候选就是 mlx community qwen three point five zero point eight b opt iq four bit，如果出问题就回到 qwen slash qwen three point five zero point eight b"
        )

        XCTAssertTrue(prompt.contains("完整模型或仓库 ID 如果已经能确定，优先恢复成右侧整串写法"))
        XCTAssertTrue(prompt.contains("mlx community qwen three point five zero point eight b opt iq four bit -> mlx-community/Qwen3.5-0.8B-OptiQ-4bit"))
        XCTAssertTrue(prompt.contains("qwen slash qwen three point five zero point eight b -> Qwen/Qwen3.5-0.8B"))
    }
}
