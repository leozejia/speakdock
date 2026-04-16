import XCTest
@testable import SpeakDockCore

final class ObservedWorkspaceTextSyncTests: XCTestCase {
    func testReturnsManualChangeActionWhenObservedTextDiffers() {
        XCTAssertEqual(
            ObservedWorkspaceTextSync.action(
                currentVisibleText: "Hello, world.",
                observedText: "Hello, world! edited"
            ),
            WorkspaceReducer.Action.manualTextChanged("Hello, world! edited")
        )
    }

    func testReturnsNilWhenObservedTextMatchesOrIsUnavailable() {
        XCTAssertNil(
            ObservedWorkspaceTextSync.action(
                currentVisibleText: "Hello, world.",
                observedText: "Hello, world."
            )
        )
        XCTAssertNil(
            ObservedWorkspaceTextSync.action(
                currentVisibleText: "Hello, world.",
                observedText: nil
            )
        )
    }
}
