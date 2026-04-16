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

            let appendedText = appendedSpeechText(text, for: workspace)
            workspace.hasSpoken = true
            workspace.rawContext += appendedText
            workspace.visibleText += appendedText
            workspace.endLocation += appendedText.count
            state.activeWorkspace = workspace

        case let .speechSegmentUndone(text):
            guard var workspace = state.activeWorkspace else {
                return
            }

            guard !text.isEmpty else {
                state.activeWorkspace = workspace
                return
            }

            let removedCount = removeAppendedSpeechText(text, from: &workspace.rawContext, for: workspace.mode)
            _ = removeAppendedSpeechText(text, from: &workspace.visibleText, for: workspace.mode)

            workspace.endLocation = max(workspace.startLocation, workspace.endLocation - removedCount)
            workspace.hasSpoken = !workspace.rawContext.isEmpty
            workspace.dirty = false
            workspace.isRefined = false
            state.activeWorkspace = workspace

        case let .refineApplied(text):
            guard var workspace = state.activeWorkspace else {
                return
            }

            workspace.visibleText = text
            workspace.endLocation = workspace.startLocation + text.count
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

            workspace.endLocation = workspace.startLocation + text.count
            state.activeWorkspace = workspace

        case .undoRefineRequested:
            guard var workspace = state.activeWorkspace else {
                return
            }

            workspace.visibleText = workspace.rawContext
            workspace.endLocation = workspace.startLocation + workspace.rawContext.count
            workspace.isRefined = false
            workspace.dirty = false
            state.activeWorkspace = workspace

        case .workspaceEnded:
            state.activeWorkspace = nil
        }
    }

    private static func appendedSpeechText(_ text: String, for workspace: Workspace) -> String {
        guard workspace.mode == .capture, !workspace.rawContext.isEmpty else {
            return text
        }

        return "\n\(text)"
    }

    @discardableResult
    private static func removeAppendedSpeechText(
        _ text: String,
        from value: inout String,
        for mode: Mode
    ) -> Int {
        if mode == .capture, value.hasSuffix("\n\(text)") {
            value.removeLast(text.count + 1)
            return text.count + 1
        }

        if value.hasSuffix(text) {
            value.removeLast(text.count)
            return text.count
        }

        return 0
    }
}
