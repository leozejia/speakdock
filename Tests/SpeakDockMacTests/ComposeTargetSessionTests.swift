import XCTest
@testable import SpeakDockMac

final class ComposeTargetSessionTests: XCTestCase {
    func testCapturedComposeTargetTakesPriorityOverLaterNoTarget() {
        var session = ComposeTargetSession()

        session.begin(availability: .available(targetID: "target-a"))

        XCTAssertTrue(session.hasCapturedTarget)
        XCTAssertEqual(
            session.resolvedAvailability(current: .noTarget),
            .available(targetID: "target-a")
        )
    }

    func testNoCapturedTargetFallsBackToCurrentAvailability() {
        let session = ComposeTargetSession()

        XCTAssertFalse(session.hasCapturedTarget)
        XCTAssertEqual(
            session.resolvedAvailability(current: .noTarget),
            .noTarget
        )
    }

    func testEndClearsCapturedTarget() {
        var session = ComposeTargetSession()

        session.begin(availability: .available(targetID: "target-a"))
        session.end()

        XCTAssertFalse(session.hasCapturedTarget)
        XCTAssertEqual(
            session.resolvedAvailability(current: .noTarget),
            .noTarget
        )
    }
}
