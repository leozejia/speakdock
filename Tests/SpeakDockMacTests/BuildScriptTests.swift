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

    func testBuildScriptRefreshesAndCopiesAppIcon() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("generate-app-icon.sh"))
        XCTAssertTrue(script.contains("render-app-icon.swift"))
        XCTAssertTrue(script.contains("SpeakDock.icns"))
    }

    func testBuildScriptCopiesSwiftPMResourceBundlesIntoAppResources() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains(".bundle"))
        XCTAssertTrue(script.contains("Contents/Resources"))
        XCTAssertTrue(script.contains("cp -R"))
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

    func testComposeProbeScriptLaunchesSpeakDockBundleWithProbeArguments() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-compose-probe.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("scripts/build-app.sh"))
        XCTAssertTrue(script.contains("open -n -W"))
        XCTAssertTrue(script.contains("--args --probe-compose --probe-compose-duration"))
    }
}
