import Foundation

public struct RecognitionCommitPreparation: Equatable, Sendable {
    public let committedText: String
    public let shouldCallModel: Bool

    public init(committedText: String, shouldCallModel: Bool) {
        self.committedText = committedText
        self.shouldCallModel = shouldCallModel
    }
}

public struct RecognitionCommitPreparer {
    private let cleanNormalizer: CleanNormalizer

    public init(cleanNormalizer: CleanNormalizer = CleanNormalizer()) {
        self.cleanNormalizer = cleanNormalizer
    }

    public func prepare(
        transcript: String,
        configuration _: RefineConfiguration
    ) -> RecognitionCommitPreparation {
        RecognitionCommitPreparation(
            committedText: cleanNormalizer.normalize(transcript),
            shouldCallModel: false
        )
    }
}

public struct WorkspaceRefinePreparation: Equatable, Sendable {
    public let sourceText: String
    public let modelInputText: String
    public let shouldCallModel: Bool

    public init(
        sourceText: String,
        modelInputText: String,
        shouldCallModel: Bool
    ) {
        self.sourceText = sourceText
        self.modelInputText = modelInputText
        self.shouldCallModel = shouldCallModel
    }
}

public struct WorkspaceRefinePreparer {
    private let cleanNormalizer: CleanNormalizer

    public init(cleanNormalizer: CleanNormalizer = CleanNormalizer()) {
        self.cleanNormalizer = cleanNormalizer
    }

    public func prepare(
        workspace: Workspace,
        observedText: String?,
        configuration: RefineConfiguration
    ) -> WorkspaceRefinePreparation {
        let sourceText = preferredWorkspaceText(
            observedText: observedText,
            visibleText: workspace.visibleText,
            rawContext: workspace.rawContext
        )
        let modelInputText = cleanNormalizer.normalize(sourceText)

        return WorkspaceRefinePreparation(
            sourceText: sourceText,
            modelInputText: modelInputText,
            shouldCallModel: configuration.enabled &&
                configuration.isConfigured &&
                !modelInputText.isEmpty
        )
    }

    private func preferredWorkspaceText(
        observedText: String?,
        visibleText: String,
        rawContext: String
    ) -> String {
        if let observedText = trimmedNonEmpty(observedText) {
            return observedText
        }

        if let visibleText = trimmedNonEmpty(visibleText) {
            return visibleText
        }

        return trimmedNonEmpty(rawContext) ?? ""
    }

    private func trimmedNonEmpty(_ text: String?) -> String? {
        guard let text else {
            return nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
