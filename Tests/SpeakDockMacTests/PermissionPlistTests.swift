import XCTest

final class PermissionPlistTests: XCTestCase {
    func testInfoPlistDeclaresInputMonitoringUsage() throws {
        let infoPlistURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/SpeakDockMac/Resources/Info.plist")
        let data = try Data(contentsOf: infoPlistURL)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        let usageDescription = try XCTUnwrap(plist["NSInputMonitoringUsageDescription"] as? String)
        XCTAssertFalse(usageDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
