import Foundation
import SpeakDockCore

enum RefineConnectionTesterError: LocalizedError, Equatable {
    case incompleteConfiguration

    var errorDescription: String? {
        switch self {
        case .incompleteConfiguration:
            "Fill Base URL / API Key / Model first"
        }
    }
}

protocol RefineConnectionTesting: Sendable {
    func test(configuration: RefineConfiguration) async throws -> String
}

struct RefineConnectionTester: RefineConnectionTesting {
    let engine: any RefineEngine
    let sampleText: String

    init(
        engine: any RefineEngine = OpenAICompatibleRefineEngine(),
        sampleText: String = "你好 SpeakDock，测试连接。"
    ) {
        self.engine = engine
        self.sampleText = sampleText
    }

    func test(configuration: RefineConfiguration) async throws -> String {
        guard configuration.isConfigured else {
            throw RefineConnectionTesterError.incompleteConfiguration
        }

        let response = try await engine.refine(
            RefineRequest(text: sampleText),
            configuration: configuration
        )
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedResponse.isEmpty ? sampleText : trimmedResponse
    }
}
