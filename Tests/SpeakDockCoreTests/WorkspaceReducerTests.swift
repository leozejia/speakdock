import XCTest
@testable import SpeakDockCore

final class WorkspaceReducerTests: XCTestCase {
    func testFocusSwitchCreatesNewWorkspace() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 3
            )
        )

        let firstWorkspace = try XCTUnwrap(state.activeWorkspace)

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-2",
                mode: .compose,
                cursorLocation: 8
            )
        )

        let secondWorkspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertNotEqual(secondWorkspace.id, firstWorkspace.id)
        XCTAssertEqual(secondWorkspace.mode, .compose)
        XCTAssertEqual(secondWorkspace.targetID, "field-2")
        XCTAssertEqual(secondWorkspace.startLocation, 8)
        XCTAssertEqual(secondWorkspace.endLocation, 8)
        XCTAssertEqual(secondWorkspace.rawContext, "")
        XCTAssertEqual(secondWorkspace.visibleText, "")
    }

    func testCursorMoveBeforeFirstSpeechUpdatesStartLocation() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 3
            )
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .cursorMoved(cursorLocation: 7)
        )

        let workspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertEqual(workspace.startLocation, 7)
        XCTAssertEqual(workspace.endLocation, 7)
        XCTAssertFalse(workspace.hasSpoken)
    }

    func testCursorMoveAfterFirstSpeechKeepsStartLocationFrozen() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 3
            )
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended("hello")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .cursorMoved(cursorLocation: 11)
        )

        let workspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertEqual(workspace.startLocation, 3)
        XCTAssertEqual(workspace.rawContext, "hello")
        XCTAssertTrue(workspace.hasSpoken)
    }

    func testSpeechAppendAccumulatesRawContext() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 1
            )
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended("hello")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended(" world")
        )

        let workspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertEqual(workspace.rawContext, "hello world")
        XCTAssertEqual(workspace.visibleText, "hello world")
    }

    func testUndoAfterRefineRestoresRawContext() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 1
            )
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended("hello world")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .refineApplied("Hello, world.")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .undoRefineRequested
        )

        let workspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertEqual(workspace.rawContext, "hello world")
        XCTAssertEqual(workspace.visibleText, "hello world")
        XCTAssertFalse(workspace.isRefined)
        XCTAssertFalse(workspace.dirty)
    }

    func testManualEditAfterRefineMarksWorkspaceDirty() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 1
            )
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended("hello world")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .refineApplied("Hello, world.")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .manualTextChanged("Hello, world! again")
        )

        let workspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertTrue(workspace.isRefined)
        XCTAssertTrue(workspace.dirty)
        XCTAssertEqual(workspace.rawContext, "hello world")
        XCTAssertEqual(workspace.visibleText, "Hello, world! again")
    }

    func testRefineAppliedUpdatesEndLocationToMatchVisibleTextLength() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 1
            )
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended("hello")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .refineApplied("Hello, world.")
        )

        let workspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertEqual(workspace.startLocation, 1)
        XCTAssertEqual(workspace.endLocation, 14)
        XCTAssertEqual(workspace.visibleText, "Hello, world.")
    }

    func testSpeechAppendAfterRefineAbsorbsRefinedTextAsNewBase() throws {
        var state = WorkspaceState()

        WorkspaceReducer.reduce(
            state: &state,
            action: .focusChanged(
                targetID: "field-1",
                mode: .compose,
                cursorLocation: 1
            )
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended("hello world")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .refineApplied("Hello, world.")
        )

        WorkspaceReducer.reduce(
            state: &state,
            action: .speechAppended(" again")
        )

        let workspace = try XCTUnwrap(state.activeWorkspace)

        XCTAssertEqual(workspace.rawContext, "Hello, world. again")
        XCTAssertEqual(workspace.visibleText, "Hello, world. again")
        XCTAssertFalse(workspace.isRefined)
        XCTAssertFalse(workspace.dirty)
        XCTAssertTrue(workspace.hasSpoken)
    }
}
