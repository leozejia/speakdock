import XCTest
@testable import SpeakDockCore

final class AppSettingsTests: XCTestCase {
    func testLegacySettingsDecodeDefaultsShowDockIconToTrue() throws {
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

        XCTAssertTrue(decoded.showDockIcon)
    }
}
