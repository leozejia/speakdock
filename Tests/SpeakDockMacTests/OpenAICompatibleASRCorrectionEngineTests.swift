import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class OpenAICompatibleASRCorrectionEngineTests: XCTestCase {
    override func setUp() {
        super.setUp()
        mockASRCorrectionRequestStore.requestHandler = nil
    }

    override func tearDown() {
        mockASRCorrectionRequestStore.requestHandler = nil
        super.tearDown()
    }

    func testCorrectSendsChatCompletionRequestWithASRCorrectionPrompt() async throws {
        mockASRCorrectionRequestStore.requestHandler = { [self] request in
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://example.com/v1/chat/completions"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret")

            let body = try XCTUnwrap(httpBody(from: request))
            let payload = try JSONDecoder().decode(MockChatCompletionRequest.self, from: body)
            XCTAssertEqual(payload.model, "gpt-4.1-mini")
            XCTAssertEqual(payload.temperature, 0)
            XCTAssertEqual(payload.messages.count, 2)
            XCTAssertEqual(payload.messages[0].role, "system")
            XCTAssertEqual(payload.messages[0].content, ConservativeASRCorrectionPrompt.systemPrompt)
            XCTAssertEqual(payload.messages[1].role, "user")
            XCTAssertEqual(
                payload.messages[1].content,
                ConservativeASRCorrectionPrompt.makeUserPrompt(for: "project adults")
            )

            return (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                #"{"choices":[{"message":{"role":"assistant","content":"Project Atlas"}}]}"#.data(using: .utf8)!
            )
        }

        let engine = OpenAICompatibleASRCorrectionEngine(session: makeSession())
        let result = try await engine.correct(
            ASRCorrectionRequest(text: "project adults"),
            configuration: configuredConfiguration()
        )

        XCTAssertEqual(result, "Project Atlas")
    }

    func testCorrectFallsBackToOriginalTextWhenResponseContentIsEmpty() async throws {
        mockASRCorrectionRequestStore.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                #"{"choices":[{"message":{"role":"assistant","content":"   "}}]}"#.data(using: .utf8)!
            )
        }

        let engine = OpenAICompatibleASRCorrectionEngine(session: makeSession())
        let result = try await engine.correct(
            ASRCorrectionRequest(text: "project adults"),
            configuration: configuredConfiguration()
        )

        XCTAssertEqual(result, "project adults")
    }

    private func configuredConfiguration() -> ASRCorrectionConfiguration {
        ASRCorrectionConfiguration(
            provider: .customEndpoint,
            enabled: true,
            baseURL: "https://example.com/v1",
            apiKey: "secret",
            model: "gpt-4.1-mini"
        )
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockASRCorrectionURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func httpBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        let bufferSize = 1024
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                return nil
            }
            if read == 0 {
                break
            }
            data.append(buffer, count: read)
        }

        return data
    }
}

private final class MockASRCorrectionURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = mockASRCorrectionRequestStore.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private let mockASRCorrectionRequestStore = MockASRCorrectionRequestStore()

private final class MockASRCorrectionRequestStore: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return handler
        }
        set {
            lock.lock()
            handler = newValue
            lock.unlock()
        }
    }
}

private struct MockChatCompletionRequest: Decodable {
    let model: String
    let messages: [MockChatMessage]
    let temperature: Double
}

private struct MockChatMessage: Decodable {
    let role: String
    let content: String
}
