import Foundation

public enum SecondaryActionKind: Equatable, Sendable {
    case refine
    case undoRefine(requiresConfirmation: Bool)
    case undoRecentSubmission
}

public struct SecondaryActionPresentation: Equatable, Sendable {
    public let kind: SecondaryActionKind
    public let title: String
    public let isEnabled: Bool

    public init(kind: SecondaryActionKind, title: String, isEnabled: Bool) {
        self.kind = kind
        self.title = title
        self.isEnabled = isEnabled
    }
}

public struct RecentSubmission: Equatable, Sendable {
    public let workspaceID: UUID
    public let mode: Mode
    public let targetID: String
    public let committedText: String
    public let timestamp: TimeInterval

    public init(
        workspaceID: UUID,
        mode: Mode,
        targetID: String,
        committedText: String,
        timestamp: TimeInterval
    ) {
        self.workspaceID = workspaceID
        self.mode = mode
        self.targetID = targetID
        self.committedText = committedText
        self.timestamp = timestamp
    }
}

public enum SecondaryActionExecution: Equatable, Sendable {
    case none
    case refine
    case requestUndoRefineConfirmation
    case undoRefine
    case undoRecentSubmission(RecentSubmission)
}

public struct UndoFlowState: Sendable {
    public let undoWindowDuration: TimeInterval

    private var recentSubmission: RecentSubmission?
    private var pendingUndoRefineConfirmationWorkspaceID: UUID?

    public init(undoWindowDuration: TimeInterval = 8) {
        self.undoWindowDuration = undoWindowDuration
    }

    public mutating func registerSubmission(
        for workspace: Workspace,
        committedText: String,
        timestamp: TimeInterval
    ) {
        recentSubmission = RecentSubmission(
            workspaceID: workspace.id,
            mode: workspace.mode,
            targetID: workspace.targetID,
            committedText: committedText,
            timestamp: timestamp
        )
    }

    public mutating func clearPendingConfirmation() {
        pendingUndoRefineConfirmationWorkspaceID = nil
    }

    public mutating func clearRecentSubmission() {
        recentSubmission = nil
    }

    public func secondaryAction(
        for workspace: Workspace?,
        now: TimeInterval
    ) -> SecondaryActionPresentation {
        guard let workspace else {
            return SecondaryActionPresentation(
                kind: .refine,
                title: "整理",
                isEnabled: false
            )
        }

        if workspace.isRefined {
            let requiresConfirmation = workspace.dirty &&
                pendingUndoRefineConfirmationWorkspaceID == workspace.id
            return SecondaryActionPresentation(
                kind: .undoRefine(requiresConfirmation: requiresConfirmation),
                title: requiresConfirmation ? "确认撤回" : "撤回",
                isEnabled: true
            )
        }

        if let recentSubmission = activeRecentSubmission(now: now), recentSubmission.workspaceID == workspace.id {
            return SecondaryActionPresentation(
                kind: .undoRecentSubmission,
                title: "撤回提交",
                isEnabled: true
            )
        }

        let isEnabled = canRefine(workspace)
        return SecondaryActionPresentation(
            kind: .refine,
            title: "整理",
            isEnabled: isEnabled
        )
    }

    public mutating func handleSecondaryAction(
        for workspace: Workspace?,
        now: TimeInterval
    ) -> SecondaryActionExecution {
        guard let workspace else {
            return .none
        }

        pruneExpiredSubmission(now: now)

        if workspace.isRefined {
            if workspace.dirty, pendingUndoRefineConfirmationWorkspaceID != workspace.id {
                pendingUndoRefineConfirmationWorkspaceID = workspace.id
                return .requestUndoRefineConfirmation
            }

            pendingUndoRefineConfirmationWorkspaceID = nil
            return .undoRefine
        }

        if let recentSubmission, recentSubmission.workspaceID == workspace.id {
            self.recentSubmission = nil
            return .undoRecentSubmission(recentSubmission)
        }

        pendingUndoRefineConfirmationWorkspaceID = nil
        return canRefine(workspace) ? .refine : .none
    }

    private func activeRecentSubmission(now: TimeInterval) -> RecentSubmission? {
        guard let recentSubmission else {
            return nil
        }

        guard now - recentSubmission.timestamp <= undoWindowDuration else {
            return nil
        }

        return recentSubmission
    }

    private mutating func pruneExpiredSubmission(now: TimeInterval) {
        guard let recentSubmission else {
            return
        }

        if now - recentSubmission.timestamp > undoWindowDuration {
            self.recentSubmission = nil
        }
    }

    private func canRefine(_ workspace: Workspace) -> Bool {
        !workspace.rawContext.isEmpty
    }
}
