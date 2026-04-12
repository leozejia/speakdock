import Foundation
import SpeakDockCore

enum OpenAICompatibleRefineEngineError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            "Invalid Refine Base URL"
        case .invalidResponse:
            "Invalid Refine Response"
        case let .unexpectedStatusCode(statusCode):
            "Refine Request Failed (\(statusCode))"
        }
    }
}

final class OpenAICompatibleRefineEngine: RefineEngine {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func refine(
        _ request: RefineRequest,
        configuration: RefineConfiguration
    ) async throws -> String {
        guard let endpointURL = endpointURL(from: configuration.baseURL) else {
            throw OpenAICompatibleRefineEngineError.invalidBaseURL
        }

        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(
                model: configuration.model,
                messages: [
                    .init(role: "system", content: ConservativeRefinePrompt.systemPrompt),
                    .init(role: "user", content: ConservativeRefinePrompt.makeUserPrompt(for: request.text)),
                ],
                temperature: 0
            )
        )

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAICompatibleRefineEngineError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw OpenAICompatibleRefineEngineError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return decodedResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? request.text
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
