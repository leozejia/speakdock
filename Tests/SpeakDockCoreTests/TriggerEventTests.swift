import XCTest
@testable import SpeakDockCore

final class TriggerEventTests: XCTestCase {
    func testPressReleaseProducesRecordingAction() {
        var machine = TriggerStateMachine(
            quickTapThreshold: 0.18,
            doubleClickWindow: 0.30
        )

        let pressActions = machine.handle(.press(timestamp: 0.0))
        let releaseActions = machine.handle(.release(timestamp: 0.45))

        XCTAssertEqual(pressActions, [])
        XCTAssertEqual(releaseActions, [.recording(startTimestamp: 0.0, endTimestamp: 0.45)])
    }

    func testQuickDoubleClickProducesSubmitAction() {
        var machine = TriggerStateMachine(
            quickTapThreshold: 0.18,
            doubleClickWindow: 0.30
        )

        XCTAssertEqual(machine.handle(.press(timestamp: 0.00)), [])
        XCTAssertEqual(machine.handle(.release(timestamp: 0.04)), [])
        XCTAssertEqual(machine.handle(.press(timestamp: 0.15)), [])
        XCTAssertEqual(machine.handle(.release(timestamp: 0.19)), [.submit])
    }

    func testInvalidEventOrderIsIgnored() {
        var machine = TriggerStateMachine()

        XCTAssertEqual(machine.handle(.release(timestamp: 0.0)), [])
        XCTAssertEqual(machine.handle(.press(timestamp: 1.0)), [])
        XCTAssertEqual(machine.handle(.press(timestamp: 1.1)), [])
    }
}
