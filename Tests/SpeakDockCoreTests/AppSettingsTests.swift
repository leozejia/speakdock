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
          "asrCorrectionProvider": "disabled",
          "asrCorrectionBaseURL": "",
          "asrCorrectionAPIKey": "",
          "asrCorrectionModel": "",
          "refineEnabled": false,
          "refineBaseURL": "",
          "refineAPIKey": "",
          "refineModel": ""
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppSettings.self, from: legacyJSON)

        XCTAssertEqual(decoded.appLanguage, .followSystem)
        XCTAssertEqual(decoded.inputLanguage, .simplifiedChinese)
        XCTAssertEqual(decoded.asrCorrectionProvider, .disabled)
        XCTAssertEqual(decoded.asrCorrectionBaseURL, "")
        XCTAssertEqual(decoded.asrCorrectionAPIKey, "")
        XCTAssertEqual(decoded.asrCorrectionModel, "")
    }

    func testSettingsEncodeWritesSplitLanguageFieldsWithoutLegacyLanguageCodeOrDockToggle() throws {
        let settings = AppSettings(
            appLanguage: .english,
            inputLanguage: .japanese,
            captureRootPath: "/tmp",
            triggerSelection: .fn,
            asrCorrectionProvider: .customEndpoint,
            asrCorrectionBaseURL: "https://example.com/v1",
            asrCorrectionAPIKey: "secret",
            asrCorrectionModel: "gpt-5.3-chat-latest",
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
        XCTAssertEqual(payload["asrCorrectionProvider"] as? String, "customEndpoint")
        XCTAssertEqual(payload["asrCorrectionBaseURL"] as? String, "https://example.com/v1")
        XCTAssertEqual(payload["asrCorrectionAPIKey"] as? String, "secret")
        XCTAssertEqual(payload["asrCorrectionModel"] as? String, "gpt-5.3-chat-latest")
        XCTAssertNil(payload["languageCode"])
        XCTAssertNil(payload["showDockIcon"])
    }
}
