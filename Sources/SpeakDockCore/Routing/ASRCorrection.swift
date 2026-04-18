import Foundation

public enum ASRCorrectionExecutionMode: Equatable, Sendable {
    case disabled
    case modelCorrection
}

public struct ASRCorrectionConfiguration: Equatable, Sendable {
    public var enabled: Bool
    public var baseURL: String
    public var apiKey: String
    public var model: String

    public init(
        enabled: Bool,
        baseURL: String,
        apiKey: String,
        model: String
    ) {
        self.enabled = enabled
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
    }

    public static let disabled = ASRCorrectionConfiguration(
        enabled: false,
        baseURL: "",
        apiKey: "",
        model: ""
    )

    public var isConfigured: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var executionMode: ASRCorrectionExecutionMode {
        enabled && isConfigured ? .modelCorrection : .disabled
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

public struct RecognitionCommitProcessor: Sendable {
    private let engine: any ASRCorrectionEngine

    public init(engine: any ASRCorrectionEngine = PassthroughASRCorrectionEngine()) {
        self.engine = engine
    }

    public func process(
        _ preparation: RecognitionCommitPreparation,
        configuration: ASRCorrectionConfiguration
    ) async -> String {
        let cleanText = preparation.committedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            return ""
        }

        guard preparation.shouldCallASRCorrection,
              configuration.executionMode == .modelCorrection
        else {
            return cleanText
        }

        do {
            let correctedText = try await engine.correct(
                ASRCorrectionRequest(text: cleanText),
                configuration: configuration
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            return correctedText.isEmpty ? cleanText : correctedText
        } catch {
            return cleanText
        }
    }
}
