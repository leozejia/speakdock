public enum WorkspaceReducer {
    public enum Action: Equatable, Sendable {
        case focusChanged(targetID: String, mode: Mode, cursorLocation: Int)
        case cursorMoved(cursorLocation: Int)
        case speechAppended(String)
        case speechSegmentUndone(String)
        case refineApplied(String)
        case manualTextChanged(String)
        case undoRefineRequested
        case workspaceEnded
    }

    public static func reduce(state: inout WorkspaceState, action: Action) {
        switch action {
        case let .focusChanged(targetID, mode, cursorLocation):
            state.activeWorkspace = Workspace(
                mode: mode,
                targetID: targetID,
                startLocation: cursorLocation
            )

        case let .cursorMoved(cursorLocation):
            guard var workspace = state.activeWorkspace else {
                return
            }

            guard workspace.hasSpoken == false else {
                state.activeWorkspace = workspace
                return
            }

            workspace.startLocation = cursorLocation
            workspace.endLocation = cursorLocation
            state.activeWorkspace = workspace

        case let .speechAppended(text):
            guard var workspace = state.activeWorkspace else {
                return
            }

            if workspace.isRefined {
                workspace.rawContext = workspace.visibleText
                workspace.endLocation = workspace.startLocation + workspace.visibleText.count
                workspace.isRefined = false
                workspace.dirty = false
            }

            workspace.hasSpoken = true
            workspace.rawContext += text
            workspace.visibleText += text
            workspace.endLocation += text.count
            state.activeWorkspace = workspace

        case let .speechSegmentUndone(text):
            guard var workspace = state.activeWorkspace else {
                return
            }

            guard !text.isEmpty else {
                state.activeWorkspace = workspace
                return
            }

            if workspace.rawContext.hasSuffix(text) {
                workspace.rawContext.removeLast(text.count)
            }

            if workspace.visibleText.hasSuffix(text) {
                workspace.visibleText.removeLast(text.count)
            }

            workspace.endLocation = max(workspace.startLocation, workspace.endLocation - text.count)
            workspace.hasSpoken = !workspace.rawContext.isEmpty
            workspace.dirty = false
            workspace.isRefined = false
            state.activeWorkspace = workspace

        case let .refineApplied(text):
            guard var workspace = state.activeWorkspace else {
                return
            }

            workspace.visibleText = text
            workspace.isRefined = true
            workspace.dirty = false
            state.activeWorkspace = workspace

        case let .manualTextChanged(text):
            guard var workspace = state.activeWorkspace else {
                return
            }

            workspace.visibleText = text

            if workspace.isRefined {
                workspace.dirty = true
            } else {
                workspace.rawContext = text
                workspace.dirty = false
            }

            state.activeWorkspace = workspace

        case .undoRefineRequested:
            guard var workspace = state.activeWorkspace else {
                return
            }

            workspace.visibleText = workspace.rawContext
            workspace.isRefined = false
            workspace.dirty = false
            state.activeWorkspace = workspace

        case .workspaceEnded:
            state.activeWorkspace = nil
        }
    }
}
