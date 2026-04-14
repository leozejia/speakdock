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
}
