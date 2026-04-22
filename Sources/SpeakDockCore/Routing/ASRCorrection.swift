import Foundation

public enum ASRCorrectionProvider: String, Equatable, Codable, Sendable, CaseIterable {
    case disabled
    case onDevice
    case customEndpoint
}

public enum ASRCorrectionExecutionMode: Equatable, Sendable {
    case disabled
    case modelCorrection
}

public struct ASRCorrectionConfiguration: Equatable, Sendable {
    public var provider: ASRCorrectionProvider
    public var enabled: Bool
    public var baseURL: String
    public var apiKey: String
    public var model: String

    public init(
        provider: ASRCorrectionProvider,
        enabled: Bool,
        baseURL: String,
        apiKey: String,
        model: String
    ) {
        self.provider = provider
        self.enabled = enabled
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
    }

    public static let disabled = ASRCorrectionConfiguration(
        provider: .disabled,
        enabled: false,
        baseURL: "",
        apiKey: "",
        model: ""
    )

    public var isConfigured: Bool {
        let hasBaseURL = !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasModel = !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAPIKey = !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return switch provider {
        case .disabled:
            false
        case .onDevice:
            hasBaseURL && hasModel
        case .customEndpoint:
            hasBaseURL && hasModel && hasAPIKey
        }
    }

    public var executionMode: ASRCorrectionExecutionMode {
        enabled && provider != .disabled && isConfigured ? .modelCorrection : .disabled
    }
}

public struct ASRCorrectionRequest: Equatable, Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol ASRCorrectionEngine: Sendable {
    func correct(
        _ request: ASRCorrectionRequest,
        configuration: ASRCorrectionConfiguration
    ) async throws -> String
}

public struct PassthroughASRCorrectionEngine: ASRCorrectionEngine {
    public init() {}

    public func correct(
        _ request: ASRCorrectionRequest,
        configuration _: ASRCorrectionConfiguration
    ) async throws -> String {
        request.text
    }
}

public enum RecognitionCommitCorrectionOutcome: String, Equatable, Sendable {
    case notRequested
    case corrected
    case unchanged
    case fallback
}

public struct RecognitionCommitProcessingResult: Equatable, Sendable {
    public let committedText: String
    public let correctionOutcome: RecognitionCommitCorrectionOutcome

    public init(
        committedText: String,
        correctionOutcome: RecognitionCommitCorrectionOutcome
    ) {
        self.committedText = committedText
        self.correctionOutcome = correctionOutcome
    }

    public var didChangeText: Bool {
        correctionOutcome == .corrected
    }
}

public struct RecognitionCommitProcessor: Sendable {
    private let engine: any ASRCorrectionEngine

    public init(engine: any ASRCorrectionEngine = PassthroughASRCorrectionEngine()) {
        self.engine = engine
    }

    public func process(
        _ preparation: RecognitionCommitPreparation,
        configuration: ASRCorrectionConfiguration
    ) async -> String {
        await processResult(
            preparation,
            configuration: configuration
        ).committedText
    }

    public func processResult(
        _ preparation: RecognitionCommitPreparation,
        configuration: ASRCorrectionConfiguration
    ) async -> RecognitionCommitProcessingResult {
        let cleanText = preparation.committedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            return RecognitionCommitProcessingResult(
                committedText: "",
                correctionOutcome: .notRequested
            )
        }

        guard preparation.shouldCallASRCorrection,
              configuration.executionMode == .modelCorrection
        else {
            return RecognitionCommitProcessingResult(
                committedText: cleanText,
                correctionOutcome: .notRequested
            )
        }

        do {
            let correctedText = try await engine.correct(
                ASRCorrectionRequest(text: cleanText),
                configuration: configuration
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !correctedText.isEmpty else {
                return RecognitionCommitProcessingResult(
                    committedText: cleanText,
                    correctionOutcome: .fallback
                )
            }

            return RecognitionCommitProcessingResult(
                committedText: correctedText,
                correctionOutcome: correctedText == cleanText ? .unchanged : .corrected
            )
        } catch {
            return RecognitionCommitProcessingResult(
                committedText: cleanText,
                correctionOutcome: .fallback
            )
        }
    }
}
