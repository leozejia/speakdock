public struct WorkspaceState: Equatable, Sendable {
    public var activeWorkspace: Workspace?

    public init(activeWorkspace: Workspace? = nil) {
        self.activeWorkspace = activeWorkspace
    }
}
