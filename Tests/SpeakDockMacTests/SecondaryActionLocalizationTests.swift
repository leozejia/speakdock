import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class SecondaryActionLocalizationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppLocalizer.setCurrentAppLanguage(.english)
    }

    override func tearDown() {
        AppLocalizer.setCurrentAppLanguage(.followSystem)
        super.tearDown()
    }

    func testEnglishTitlesAreMappedInMacLayer() {
        XCTAssertEqual(
            SecondaryActionPresentation(kind: .refine, title: "整理", isEnabled: true).localizedTitle(),
            "Refine"
        )
        XCTAssertEqual(
            SecondaryActionPresentation(
                kind: .undoRefine(requiresConfirmation: false),
                title: "撤回",
                isEnabled: true
            ).localizedTitle(),
            "Undo"
        )
        XCTAssertEqual(
            SecondaryActionPresentation(
                kind: .undoRefine(requiresConfirmation: true),
                title: "确认撤回",
                isEnabled: true
            ).localizedTitle(),
            "Confirm Undo"
        )
        XCTAssertEqual(
            SecondaryActionPresentation(kind: .undoRecentSubmission, title: "撤回提交", isEnabled: true).localizedTitle(),
            "Undo Submit"
        )
    }

    func testChineseTitlesAreMappedInMacLayer() {
        AppLocalizer.setCurrentAppLanguage(.simplifiedChinese)

        XCTAssertEqual(
            SecondaryActionPresentation(kind: .refine, title: "整理", isEnabled: true).localizedTitle(),
            "整理"
        )
        XCTAssertEqual(
            SecondaryActionPresentation(
                kind: .undoRefine(requiresConfirmation: false),
                title: "撤回",
                isEnabled: true
            ).localizedTitle(),
            "撤回"
        )
        XCTAssertEqual(
            SecondaryActionPresentation(
                kind: .undoRefine(requiresConfirmation: true),
                title: "确认撤回",
                isEnabled: true
            ).localizedTitle(),
            "确认撤回"
        )
        XCTAssertEqual(
            SecondaryActionPresentation(kind: .undoRecentSubmission, title: "撤回提交", isEnabled: true).localizedTitle(),
            "撤回提交"
        )
    }
}
