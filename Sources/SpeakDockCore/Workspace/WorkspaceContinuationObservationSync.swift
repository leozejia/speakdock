public enum WorkspaceContinuationObservationSync {
    public static func action(
        activeWorkspace: Workspace?,
        incomingMode: Mode,
        incomingTargetID: String,
        observedText: String?
    ) -> WorkspaceReducer.Action? {
        guard let activeWorkspace,
              activeWorkspace.mode == incomingMode,
              activeWorkspace.targetID == incomingTargetID
        else {
            return nil
        }

        return ObservedWorkspaceTextSync.action(
            currentVisibleText: activeWorkspace.visibleText,
            observedText: observedText
        )
    }
}
