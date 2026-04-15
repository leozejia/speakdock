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

    func testChineseRefineConfigurationCopyIsLocalized() throws {
        let baseURLPlaceholderKey = try XCTUnwrap(
            AppLocalizedStringKey(rawValue: "settings.base_url.placeholder")
        )
        let apiKeyPlaceholderKey = try XCTUnwrap(
            AppLocalizedStringKey(rawValue: "settings.api_key.placeholder")
        )
        let modelPlaceholderKey = try XCTUnwrap(
            AppLocalizedStringKey(rawValue: "settings.model.placeholder")
        )

        XCTAssertEqual(
            AppLocalizer.string(
                .settingsBaseURLLabel,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "接口地址"
        )
        XCTAssertEqual(
            AppLocalizer.string(
                .settingsAPIKeyLabel,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "API 密钥"
        )
        XCTAssertEqual(
            AppLocalizer.string(
                .settingsModelLabel,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "模型"
        )
        XCTAssertEqual(
            AppLocalizer.string(
                .menuSettings,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "设置"
        )
        XCTAssertEqual(
            AppLocalizer.string(
                baseURLPlaceholderKey,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "https://example.com/v1"
        )
        XCTAssertEqual(
            AppLocalizer.string(
                apiKeyPlaceholderKey,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "请输入 API 密钥"
        )
        XCTAssertEqual(
            AppLocalizer.string(
                modelPlaceholderKey,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "例如 gpt-5.4"
        )
        XCTAssertEqual(
            AppLocalizer.string(
                .menuActionsUnavailableSubtitle,
                appLanguage: .simplifiedChinese,
                preferredLanguages: ["en"]
            ),
            "Fn 当前不可用，请去设置里手动切换触发方式。"
        )
    }
}
