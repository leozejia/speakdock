import XCTest
@testable import SpeakDockCore

final class UndoFlowTests: XCTestCase {
    func testRefinedWorkspaceSecondaryActionBecomesUndoRefine() {
        let workspace = Workspace(
            mode: .compose,
            targetID: "chat-box",
            startLocation: 0,
            rawContext: "原文",
            visibleText: "整理后文本",
            hasSpoken: true,
            dirty: false,
            isRefined: true
        )
        let flow = UndoFlowState()

        let action = flow.secondaryAction(for: workspace, now: 0)

        XCTAssertEqual(action.kind, .undoRefine(requiresConfirmation: false))
        XCTAssertEqual(action.title, "撤回")
    }

    func testDirtyRefineRequiresConfirmationBeforeUndo() {
        let workspace = Workspace(
            mode: .compose,
            targetID: "chat-box",
            startLocation: 0,
            rawContext: "原文",
            visibleText: "我手改过的整理结果",
            hasSpoken: true,
            dirty: true,
            isRefined: true
        )
        var flow = UndoFlowState()

        let firstTap = flow.handleSecondaryAction(for: workspace, now: 0)
        let confirmationAction = flow.secondaryAction(for: workspace, now: 0)
        let secondTap = flow.handleSecondaryAction(for: workspace, now: 0)

        XCTAssertEqual(firstTap, .requestUndoRefineConfirmation)
        XCTAssertEqual(confirmationAction.kind, .undoRefine(requiresConfirmation: true))
        XCTAssertEqual(confirmationAction.title, "确认撤回")
        XCTAssertEqual(secondTap, .undoRefine)
    }

    func testRecentSubmissionWithinUndoWindowTakesPriorityOverRefine() {
        let workspace = Workspace(
            mode: .capture,
            targetID: "/tmp/demo.md",
            startLocation: 0,
            rawContext: "第一句",
            visibleText: "第一句",
            hasSpoken: true
        )
        var flow = UndoFlowState(undoWindowDuration: 8)
        flow.registerSubmission(for: workspace, committedText: "第一句", timestamp: 10)

        let withinWindow = flow.secondaryAction(for: workspace, now: 17.9)
        let expiredWindow = flow.secondaryAction(for: workspace, now: 18.1)

        XCTAssertEqual(withinWindow.kind, .undoRecentSubmission)
        XCTAssertEqual(withinWindow.title, "撤回提交")
        XCTAssertEqual(expiredWindow.kind, .refine)
        XCTAssertEqual(expiredWindow.title, "整理")
    }

    func testCaptureRollbackOnlyRemovesMostRecentAppendedTail() {
        var state = WorkspaceState(
            activeWorkspace: Workspace(
                mode: .capture,
                targetID: "/tmp/demo.md",
                startLocation: 0
            )
        )

        WorkspaceReducer.reduce(state: &state, action: .speechAppended("第一句"))
        WorkspaceReducer.reduce(state: &state, action: .speechAppended("第二句"))
        WorkspaceReducer.reduce(state: &state, action: .speechSegmentUndone("第二句"))

        XCTAssertEqual(state.activeWorkspace?.rawContext, "第一句")
        XCTAssertEqual(state.activeWorkspace?.visibleText, "第一句")
    }

    func testDoubleSubmitEndsCurrentWorkspace() {
        var state = WorkspaceState(
            activeWorkspace: Workspace(
                mode: .compose,
                targetID: "chat-box",
                startLocation: 0,
                rawContext: "你好",
                visibleText: "你好",
                hasSpoken: true
            )
        )

        WorkspaceReducer.reduce(state: &state, action: .workspaceEnded)

        XCTAssertNil(state.activeWorkspace)
    }
}
