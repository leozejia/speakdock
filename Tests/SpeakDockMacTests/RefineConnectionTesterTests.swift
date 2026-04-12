import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class RefineConnectionTesterTests: XCTestCase {
    func testRejectsIncompleteConfiguration() async {
        let tester = RefineConnectionTester(
            engine: StubRefineEngine(result: .success("ok"))
        )

        do {
            _ = try await tester.test(
                configuration: RefineConfiguration(
                    enabled: true,
                    baseURL: "",
                    apiKey: "secret",
                    model: "gpt-4.1-mini"
                )
            )
            XCTFail("Expected incomplete configuration to fail")
        } catch {
            XCTAssertEqual(
                error as? RefineConnectionTesterError,
                .incompleteConfiguration
            )
        }
    }

    func testReturnsTrimmedResponseFromEngine() async throws {
        let tester = RefineConnectionTester(
            engine: StubRefineEngine(result: .success("  refined text  ")),
            sampleText: "sample"
        )

        let result = try await tester.test(
            configuration: RefineConfiguration(
                enabled: true,
                baseURL: "https://example.com/v1",
                apiKey: "secret",
                model: "gpt-4.1-mini"
            )
        )

        XCTAssertEqual(result, "refined text")
    }

    func testFallsBackToSampleTextWhenEngineReturnsEmptyContent() async throws {
        let tester = RefineConnectionTester(
            engine: StubRefineEngine(result: .success("   ")),
            sampleText: "sample"
        )

        let result = try await tester.test(
            configuration: RefineConfiguration(
                enabled: true,
                baseURL: "https://example.com/v1",
                apiKey: "secret",
                model: "gpt-4.1-mini"
            )
        )

        XCTAssertEqual(result, "sample")
    }
}

private struct StubRefineEngine: RefineEngine {
    let result: Result<String, StubRefineEngineError>

    func refine(
        _ request: RefineRequest,
        configuration: RefineConfiguration
    ) async throws -> String {
        try result.get()
    }
}

private enum StubRefineEngineError: Error {
    case failed
}
