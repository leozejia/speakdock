import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class SettingsPaneTests: XCTestCase {
    func testPaneOrderMatchesSettingsShellNavigation() {
        XCTAssertEqual(SettingsPane.allCases, [.general, .dictionary, .refine])
        XCTAssertEqual(SettingsPane.defaultPane, .general)
    }

    func testEnglishPaneTitlesAreLocalized() {
        XCTAssertEqual(
            SettingsPane.general.title(appLanguage: .english),
            "General"
        )
        XCTAssertEqual(
            SettingsPane.dictionary.title(appLanguage: .english),
            "Dictionary"
        )
        XCTAssertEqual(
            SettingsPane.refine.title(appLanguage: .english),
            "Refine"
        )
    }

    func testChinesePaneTitlesAreLocalized() {
        XCTAssertEqual(
            SettingsPane.general.title(appLanguage: .simplifiedChinese),
            "通用"
        )
        XCTAssertEqual(
            SettingsPane.dictionary.title(appLanguage: .simplifiedChinese),
            "词典"
        )
        XCTAssertEqual(
            SettingsPane.refine.title(appLanguage: .simplifiedChinese),
            "整理"
        )
    }
}
