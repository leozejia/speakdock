import XCTest
@testable import SpeakDockCore

final class LanguageOptionTests: XCTestCase {
    func testDefaultInputLanguageIsSimplifiedChinese() {
        XCTAssertEqual(InputLanguageOption.defaultOption, .simplifiedChinese)
        XCTAssertEqual(InputLanguageOption.defaultOption.rawValue, "zh-CN")
    }

    func testSupportedInputLanguagesMatchArchitecture() {
        XCTAssertEqual(
            Set(InputLanguageOption.allCases.map(\.rawValue)),
            Set(["en-US", "zh-CN", "zh-TW", "ja-JP", "ko-KR"])
        )
    }

    func testInputLanguageValuesCanBeEncodedAndDecodedSafely() throws {
        let encoded = try JSONEncoder().encode([
            InputLanguageOption.english,
            .simplifiedChinese,
            .korean,
        ])
        let decoded = try JSONDecoder().decode([InputLanguageOption].self, from: encoded)

        XCTAssertEqual(decoded, [.english, .simplifiedChinese, .korean])
    }

    func testSupportedAppLanguagesMatchCurrentPlan() {
        XCTAssertEqual(
            Set(AppLanguageOption.allCases.map(\.rawValue)),
            Set(["system", "en", "zh-Hans"])
        )
    }

    func testAppLanguageValuesCanBeEncodedAndDecodedSafely() throws {
        let encoded = try JSONEncoder().encode([
            AppLanguageOption.followSystem,
            .english,
            .simplifiedChinese,
        ])
        let decoded = try JSONDecoder().decode([AppLanguageOption].self, from: encoded)

        XCTAssertEqual(decoded, [.followSystem, .english, .simplifiedChinese])
    }
}
