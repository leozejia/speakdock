import XCTest

final class BuildScriptTests: XCTestCase {
    func testAdHocSigningUsesStableDesignatedRequirementForTCC() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("--requirements"))
        XCTAssertTrue(script.contains("designated => identifier"))
        XCTAssertTrue(script.contains("CFBundleIdentifier"))
    }

    func testShowLogsScriptFiltersBySpeakDockSubsystem() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/show-logs.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("subsystem == \"com.leozejia.speakdock\""))
        XCTAssertTrue(script.contains("/usr/bin/log"))
        XCTAssertTrue(script.contains("--info"))
        XCTAssertTrue(script.contains("--debug"))
        XCTAssertTrue(script.contains("--last"))
    }
}
