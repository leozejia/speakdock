import XCTest

final class PermissionPlistTests: XCTestCase {
    func testInfoPlistDeclaresSystemPrivacyUsageDescriptions() throws {
        let infoPlistURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/SpeakDockMac/Resources/Info.plist")
        let data = try Data(contentsOf: infoPlistURL)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        let microphoneUsage = try XCTUnwrap(plist["NSMicrophoneUsageDescription"] as? String)
        let speechUsage = try XCTUnwrap(plist["NSSpeechRecognitionUsageDescription"] as? String)

        XCTAssertFalse(microphoneUsage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertFalse(speechUsage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
