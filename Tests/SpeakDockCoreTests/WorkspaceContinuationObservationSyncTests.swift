import XCTest
@testable import SpeakDockCore

final class WorkspaceContinuationObservationSyncTests: XCTestCase {
    func testReturnsManualChangeWhenContinuingSameComposeWorkspaceAfterObservedEdit() {
        let workspace = Workspace(
            mode: .compose,
            targetID: "chat-box",
            startLocation: 0,
            rawContext: "hello",
            visibleText: "hello",
            hasSpoken: true
        )

        XCTAssertEqual(
            WorkspaceContinuationObservationSync.action(
                activeWorkspace: workspace,
                incomingMode: .compose,
                incomingTargetID: "chat-box",
                observedText: "hello edited"
            ),
            .manualTextChanged("hello edited")
        )
    }

    func testReturnsManualChangeWhenContinuingSameCaptureWorkspaceAfterObservedEdit() {
        let workspace = Workspace(
            mode: .capture,
            targetID: "/tmp/speakdock.md",
            startLocation: 0,
            rawContext: "hello",
            visibleText: "hello",
            hasSpoken: true
        )

        XCTAssertEqual(
            WorkspaceContinuationObservationSync.action(
                activeWorkspace: workspace,
                incomingMode: .capture,
                incomingTargetID: "/tmp/speakdock.md",
                observedText: "hello edited"
            ),
            .manualTextChanged("hello edited")
        )
    }

    func testReturnsNilWhenIncomingSpeechTargetsDifferentWorkspace() {
        let workspace = Workspace(
            mode: .compose,
            targetID: "chat-box",
            startLocation: 0,
            rawContext: "hello",
            visibleText: "hello",
            hasSpoken: true
        )

        XCTAssertNil(
            WorkspaceContinuationObservationSync.action(
                activeWorkspace: workspace,
                incomingMode: .compose,
                incomingTargetID: "other-box",
                observedText: "hello edited"
            )
        )
        XCTAssertNil(
            WorkspaceContinuationObservationSync.action(
                activeWorkspace: workspace,
                incomingMode: .capture,
                incomingTargetID: "chat-box",
                observedText: "hello edited"
            )
        )
        XCTAssertNil(
            WorkspaceContinuationObservationSync.action(
                activeWorkspace: nil,
                incomingMode: .compose,
                incomingTargetID: "chat-box",
                observedText: "hello edited"
            )
        )
    }
}
