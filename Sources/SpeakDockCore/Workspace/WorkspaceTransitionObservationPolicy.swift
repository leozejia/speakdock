public enum WorkspaceTransitionObservationPolicy {
    public static func endedWorkspaceBeforeTransition(
        current: Workspace?,
        nextMode: Mode,
        nextTargetID: String
    ) -> Workspace? {
        guard let current else {
            return nil
        }

        guard current.mode != nextMode || current.targetID != nextTargetID else {
            return nil
        }

        return current
    }
}
