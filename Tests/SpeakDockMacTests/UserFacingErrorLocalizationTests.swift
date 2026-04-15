import XCTest
@testable import SpeakDockMac

final class UserFacingErrorLocalizationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppLocalizer.setCurrentAppLanguage(.english)
    }

    override func tearDown() {
        AppLocalizer.setCurrentAppLanguage(.followSystem)
        super.tearDown()
    }

    func testEnglishUserFacingErrorsAreLocalized() {
        XCTAssertEqual(
            OpenAICompatibleRefineEngineError.invalidBaseURL.localizedDescription,
            "Invalid Refine Base URL"
        )
        XCTAssertEqual(
            OpenAICompatibleRefineEngineError.invalidResponse.localizedDescription,
            "Invalid Refine Response"
        )
        XCTAssertEqual(
            OpenAICompatibleRefineEngineError.unexpectedStatusCode(429).localizedDescription,
            "Refine Request Failed (429)"
        )
        XCTAssertEqual(
            RefineConnectionTesterError.incompleteConfiguration.localizedDescription,
            "Fill Base URL / API Key / Model first"
        )
        XCTAssertEqual(
            CaptureRootMigrationError.destinationConflict("note.md").localizedDescription,
            "Destination already contains \"note.md\"."
        )
        XCTAssertEqual(
            CaptureRootMigrationError.sourceIsNotDirectory.localizedDescription,
            "Current capture root is not a directory."
        )
        XCTAssertEqual(
            CaptureRootMigrationError.destinationIsNotDirectory.localizedDescription,
            "New capture root is not a directory."
        )
        XCTAssertEqual(
            TermDictionaryStoreError.emptyCanonicalTerm.localizedDescription,
            "Canonical term is required."
        )
        XCTAssertEqual(
            TermDictionaryStoreError.missingAlias.localizedDescription,
            "Add at least one alias before saving."
        )
        XCTAssertEqual(RefineConnectionTester().sampleText, "Hello SpeakDock, this is a connection test.")
    }

    func testChineseUserFacingErrorsAreLocalized() {
        AppLocalizer.setCurrentAppLanguage(.simplifiedChinese)

        XCTAssertEqual(
            OpenAICompatibleRefineEngineError.invalidBaseURL.localizedDescription,
            "Refine Base URL 无效"
        )
        XCTAssertEqual(
            OpenAICompatibleRefineEngineError.invalidResponse.localizedDescription,
            "Refine 返回结果无效"
        )
        XCTAssertEqual(
            OpenAICompatibleRefineEngineError.unexpectedStatusCode(429).localizedDescription,
            "Refine 请求失败（429）"
        )
        XCTAssertEqual(
            RefineConnectionTesterError.incompleteConfiguration.localizedDescription,
            "请先填写 Base URL / API Key / Model"
        )
        XCTAssertEqual(
            CaptureRootMigrationError.destinationConflict("note.md").localizedDescription,
            "目标目录已存在“note.md”。"
        )
        XCTAssertEqual(
            CaptureRootMigrationError.sourceIsNotDirectory.localizedDescription,
            "当前 capture 根目录不是文件夹。"
        )
        XCTAssertEqual(
            CaptureRootMigrationError.destinationIsNotDirectory.localizedDescription,
            "新的 capture 根目录不是文件夹。"
        )
        XCTAssertEqual(
            TermDictionaryStoreError.emptyCanonicalTerm.localizedDescription,
            "规范词不能为空。"
        )
        XCTAssertEqual(
            TermDictionaryStoreError.missingAlias.localizedDescription,
            "保存前至少添加一个别名。"
        )
        XCTAssertEqual(RefineConnectionTester().sampleText, "你好 SpeakDock，这是一段连接测试。")
    }
}
