import XCTest
@testable import SpeakDockMac

final class SpeakDockLaunchOptionsTests: XCTestCase {
    func testDefaultsToNormalMode() {
        let options = SpeakDockLaunchOptions(arguments: ["SpeakDock"])

        XCTAssertEqual(options.mode, .normal)
        XCTAssertEqual(options.composeProbeDuration, SpeakDockLaunchOptions.defaultComposeProbeDuration)
    }

    func testProbeModeParsesDuration() {
        let options = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--probe-compose", "--probe-compose-duration", "45"]
        )

        XCTAssertEqual(options.mode, .composeProbe)
        XCTAssertEqual(options.composeProbeDuration, 45)
    }

    func testProbeDurationIsBounded() {
        let shortOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--probe-compose", "--probe-compose-duration", "1"]
        )
        let longOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--probe-compose", "--probe-compose-duration", "999"]
        )

        XCTAssertEqual(shortOptions.composeProbeDuration, SpeakDockLaunchOptions.minimumComposeProbeDuration)
        XCTAssertEqual(longOptions.composeProbeDuration, SpeakDockLaunchOptions.maximumComposeProbeDuration)
    }

    func testSmokeModeParsesTextAndDelay() {
        let options = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--smoke-hot-path", "--smoke-text", "Project Atlas", "--smoke-delay", "1.5"]
        )

        XCTAssertEqual(options.mode, .smokeHotPath)
        XCTAssertEqual(options.smokeText, "Project Atlas")
        XCTAssertEqual(options.smokeDelay, 1.5)
    }

    func testSmokeDelayIsBounded() {
        let shortOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--smoke-hot-path", "--smoke-text", "hello", "--smoke-delay", "0.1"]
        )
        let longOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--smoke-hot-path", "--smoke-text", "hello", "--smoke-delay", "99"]
        )

        XCTAssertEqual(shortOptions.smokeDelay, SpeakDockLaunchOptions.minimumSmokeDelay)
        XCTAssertEqual(longOptions.smokeDelay, SpeakDockLaunchOptions.maximumSmokeDelay)
    }

    func testSmokeRefineModeParsesEndpointOverrides() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-refine",
                "--smoke-text", "Project Atlas",
                "--smoke-delay", "1.2",
                "--smoke-refine-base-url", "http://127.0.0.1:8080/v1",
                "--smoke-refine-api-key", "smoke-token",
                "--smoke-refine-model", "smoke-model",
            ]
        )

        XCTAssertEqual(options.mode, .smokeRefine)
        XCTAssertEqual(options.smokeText, "Project Atlas")
        XCTAssertEqual(options.smokeDelay, 1.2)
        XCTAssertEqual(options.smokeRefineBaseURL, "http://127.0.0.1:8080/v1")
        XCTAssertEqual(options.smokeRefineAPIKey, "smoke-token")
        XCTAssertEqual(options.smokeRefineModel, "smoke-model")
    }
}
