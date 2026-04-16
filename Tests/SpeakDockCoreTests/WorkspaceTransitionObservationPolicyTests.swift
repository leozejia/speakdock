import XCTest
@testable import SpeakDockCore

final class WorkspaceTransitionObservationPolicyTests: XCTestCase {
    func testReturnsNilWhenThereIsNoCurrentWorkspace() {
        XCTAssertNil(
            WorkspaceTransitionObservationPolicy.endedWorkspaceBeforeTransition(
                current: nil,
                nextMode: .compose,
                nextTargetID: "field-1"
            )
        )
    }

    func testReturnsNilWhenTransitionStaysOnSameWorkspace() {
        let workspace = Workspace(
            mode: .compose,
            targetID: "field-1",
            startLocation: 0,
            rawContext: "hello",
            visibleText: "hello",
            hasSpoken: true
        )

        XCTAssertNil(
            WorkspaceTransitionObservationPolicy.endedWorkspaceBeforeTransition(
                current: workspace,
                nextMode: .compose,
                nextTargetID: "field-1"
            )
        )
    }

    func testReturnsCurrentWorkspaceWhenTargetChanges() throws {
        let workspace = Workspace(
            mode: .compose,
            targetID: "field-1",
            startLocation: 0,
            rawContext: "hello",
            visibleText: "hello",
            hasSpoken: true
        )

        let endedWorkspace = try XCTUnwrap(
            WorkspaceTransitionObservationPolicy.endedWorkspaceBeforeTransition(
                current: workspace,
                nextMode: .compose,
                nextTargetID: "field-2"
            )
        )

        XCTAssertEqual(endedWorkspace.id, workspace.id)
    }

    func testReturnsCurrentWorkspaceWhenModeChanges() throws {
        let workspace = Workspace(
            mode: .capture,
            targetID: "/tmp/a.md",
            startLocation: 0,
            rawContext: "hello",
            visibleText: "hello",
            hasSpoken: true
        )

        let endedWorkspace = try XCTUnwrap(
            WorkspaceTransitionObservationPolicy.endedWorkspaceBeforeTransition(
                current: workspace,
                nextMode: .compose,
                nextTargetID: "field-1"
            )
        )

        XCTAssertEqual(endedWorkspace.id, workspace.id)
    }
}
