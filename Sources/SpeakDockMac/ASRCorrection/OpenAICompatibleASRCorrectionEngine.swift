import Foundation
import OSLog
import SpeakDockCore

enum OpenAICompatibleASRCorrectionEngineError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            AppLocalizer.string(.refineInvalidBaseURL)
        case .invalidResponse:
            AppLocalizer.string(.refineInvalidResponse)
        case let .unexpectedStatusCode(statusCode):
            AppLocalizer.formatted(.refineRequestFailedFormat, [String(statusCode)])
        }
    }
}

final class OpenAICompatibleASRCorrectionEngine: ASRCorrectionEngine {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func correct(
        _ request: ASRCorrectionRequest,
        configuration: ASRCorrectionConfiguration
    ) async throws -> String {
        guard let endpointURL = endpointURL(from: configuration.baseURL) else {
            SpeakDockLog.speech.error("asr correction request rejected because base URL is invalid")
            throw OpenAICompatibleASRCorrectionEngineError.invalidBaseURL
        }

        SpeakDockLog.speech.notice("asr correction request started")
        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(
                model: configuration.model,
                messages: [
                    .init(role: "system", content: ConservativeASRCorrectionPrompt.systemPrompt),
                    .init(role: "user", content: ConservativeASRCorrectionPrompt.makeUserPrompt(for: request.text)),
                ],
                temperature: 0
            )
        )

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            SpeakDockLog.speech.error("asr correction request returned invalid response")
            throw OpenAICompatibleASRCorrectionEngineError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            SpeakDockLog.speech.error("asr correction request failed with status: \(httpResponse.statusCode, privacy: .public)")
            throw OpenAICompatibleASRCorrectionEngineError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let correctedText = decodedResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        SpeakDockLog.speech.notice("asr correction request succeeded")
        return correctedText?.isEmpty == false ? correctedText! : request.text
    }

    private func endpointURL(from baseURL: String) -> URL? {
        guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }

        if url.path.hasSuffix("/chat/completions") {
            return url
        }

        return url
            .appendingPathComponent("chat", isDirectory: true)
            .appendingPathComponent("completions", isDirectory: false)
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}
