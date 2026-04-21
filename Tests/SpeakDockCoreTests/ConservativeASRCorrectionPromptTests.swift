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
}
