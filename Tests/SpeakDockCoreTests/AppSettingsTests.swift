import XCTest
@testable import SpeakDockCore

final class AppSettingsTests: XCTestCase {
    func testLegacySettingsDecodeMigratesLanguageCodeIntoInputLanguageAndDefaultsAppLanguage() throws {
        let legacyJSON = """
        {
          "languageCode": "zh-CN",
          "captureRootPath": "/tmp",
          "triggerSelection": {
            "kind": "fn"
          },
          "refineEnabled": false,
          "refineBaseURL": "",
          "refineAPIKey": "",
          "refineModel": ""
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppSettings.self, from: legacyJSON)

        XCTAssertEqual(decoded.appLanguage, .followSystem)
        XCTAssertEqual(decoded.inputLanguage, .simplifiedChinese)
    }

    func testSettingsEncodeWritesSplitLanguageFieldsWithoutLegacyLanguageCodeOrDockToggle() throws {
        let settings = AppSettings(
            appLanguage: .english,
            inputLanguage: .japanese,
            captureRootPath: "/tmp",
            triggerSelection: .fn,
            refineEnabled: false,
            refineBaseURL: "",
            refineAPIKey: "",
            refineModel: ""
        )

        let encoded = try JSONEncoder().encode(settings)
        let payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )

        XCTAssertEqual(payload["appLanguage"] as? String, "en")
        XCTAssertEqual(payload["inputLanguage"] as? String, "ja-JP")
        XCTAssertNil(payload["languageCode"])
        XCTAssertNil(payload["showDockIcon"])
    }
}
