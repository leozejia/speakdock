public enum ObservedWorkspaceTextSync {
    public static func action(
        currentVisibleText: String,
        observedText: String?
    ) -> WorkspaceReducer.Action? {
        guard let observedText else {
            return nil
        }

        guard observedText != currentVisibleText else {
            return nil
        }

        return .manualTextChanged(observedText)
    }
}
