import XCTest
@testable import SpeakDockCore

final class LanguageOptionTests: XCTestCase {
    func testDefaultLanguageIsSimplifiedChinese() {
        XCTAssertEqual(LanguageOption.defaultOption, .simplifiedChinese)
        XCTAssertEqual(LanguageOption.defaultOption.rawValue, "zh-CN")
    }

    func testSupportedLanguagesMatchArchitecture() {
        XCTAssertEqual(
            Set(LanguageOption.allCases.map(\.rawValue)),
            Set(["en-US", "zh-CN", "zh-TW", "ja-JP", "ko-KR"])
        )
    }

    func testLanguageValuesCanBeEncodedAndDecodedSafely() throws {
        let encoded = try JSONEncoder().encode([
            LanguageOption.english,
            .simplifiedChinese,
            .korean,
        ])
        let decoded = try JSONDecoder().decode([LanguageOption].self, from: encoded)

        XCTAssertEqual(decoded, [.english, .simplifiedChinese, .korean])
    }
}
