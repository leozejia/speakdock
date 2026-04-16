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

    func testBuildScriptCopiesLocalizationDirectoriesIntoMainBundleResources() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("Resources/Localization"))
        XCTAssertTrue(script.contains("*.lproj"))
        XCTAssertTrue(script.contains("mkdir -p"))
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

    func testShowTracesScriptFiltersByTraceCategory() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/show-traces.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("subsystem == \"com.leozejia.speakdock\""))
        XCTAssertTrue(script.contains("category == \"trace\""))
        XCTAssertTrue(script.contains("trace.finish"))
        XCTAssertTrue(script.contains("/usr/bin/log"))
    }

    func testComposeProbeScriptLaunchesSpeakDockBundleWithProbeArguments() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-compose-probe.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("scripts/build-app.sh"))
        XCTAssertTrue(script.contains("open -n -W"))
        XCTAssertTrue(script.contains("--args --probe-compose --probe-compose-duration"))
    }

    func testBuildTestHostScriptBuildsHostBundle() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-test-host.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("--product SpeakDockTestHost"))
        XCTAssertTrue(script.contains("SpeakDockTestHost.app"))
        XCTAssertTrue(script.contains("Sources/SpeakDockTestHost/Resources/Info.plist"))
    }

    func testSmokeComposeScriptLaunchesSmokeModeAgainstTestHost() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-compose.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("build-test-host.sh"))
        XCTAssertTrue(script.contains("--smoke-hot-path"))
        XCTAssertTrue(script.contains("--smoke-text"))
        XCTAssertTrue(script.contains("SpeakDockTestHost"))
    }

    func testSmokeRefineScriptLaunchesLocalRefineStubAndSmokeMode() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("run-refine-stub-server.py"))
        XCTAssertTrue(script.contains("--smoke-refine"))
        XCTAssertTrue(script.contains("--smoke-refine-base-url"))
        XCTAssertTrue(script.contains("SpeakDockTestHost"))
    }
}
