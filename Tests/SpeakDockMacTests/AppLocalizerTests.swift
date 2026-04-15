import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class AppLocalizerTests: XCTestCase {
    func testEnglishOverrideReturnsEnglishString() {
        XCTAssertEqual(
            AppLocalizer.string(
                .settingsInputTitle,
                appLanguage: .english,
                preferredLanguages: ["zh-Hans"]
            ),
            "Input"
        )
    }

    func testSimplifiedChineseOverrideReturnsChineseString() {
        XCTAssertEqual(
            AppLocalizer.string(
                .settingsInputTitle,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "输入"
        )
    }

    func testFollowSystemFallsBackToEnglishWhenSystemLanguageIsUnsupported() {
        XCTAssertEqual(
            AppLocalizer.string(
                .settingsInputTitle,
                appLanguage: .followSystem,
                preferredLanguages: ["ja-JP"]
            ),
            "Input"
        )
    }

    func testEnglishOverrideReturnsLocalizedMenuCopy() {
        XCTAssertEqual(
            AppLocalizer.string(
                .menuQuickControlsTitle,
                appLanguage: .english,
                preferredLanguages: ["zh-Hans"]
            ),
            "Quick Controls"
        )
    }

    func testSimplifiedChineseOverrideReturnsLocalizedMenuCopy() {
        XCTAssertEqual(
            AppLocalizer.string(
                .menuQuickControlsTitle,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "快捷控制"
        )
    }

    func testFormattedStringUsesLocalizedFormat() {
        XCTAssertEqual(
            AppLocalizer.formatted(
                .settingsTermDictionarySavedCount,
                appLanguage: .english,
                preferredLanguages: ["en"],
                [3]
            ),
            "3 saved"
        )
    }
}
