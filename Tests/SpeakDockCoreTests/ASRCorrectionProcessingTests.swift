import XCTest
@testable import SpeakDockCore

final class ASRCorrectionProcessingTests: XCTestCase {
    func testRecognitionCommitPreparationEnablesASRCorrectionWhenConfigurationIsComplete() {
        let preparer = RecognitionCommitPreparer()

        let preparation = preparer.prepare(
            transcript: "  project adults  ",
            configuration: ASRCorrectionConfiguration(
                enabled: true,
                baseURL: "https://api.example.com/v1",
                apiKey: "token",
                model: "gpt-4.1-mini"
            )
        )

        XCTAssertEqual(preparation.committedText, "project adults")
        XCTAssertTrue(preparation.shouldCallASRCorrection)
    }

    func testRecognitionCommitProcessorUsesCorrectedTranscriptWhenASRCorrectionSucceeds() async {
        let processor = RecognitionCommitProcessor(
            engine: StubASRCorrectionEngine(result: .success("Project Atlas"))
        )
        let preparation = RecognitionCommitPreparation(
            committedText: "project adults",
            shouldCallASRCorrection: true
        )

        let committedText = await processor.process(
            preparation,
            configuration: configuredASRCorrectionConfiguration()
        )

        XCTAssertEqual(committedText, "Project Atlas")
    }

    func testRecognitionCommitProcessorFallsBackToCleanTextWhenASRCorrectionFails() async {
        let processor = RecognitionCommitProcessor(
            engine: StubASRCorrectionEngine(result: .failure(StubASRCorrectionError.failed))
        )
        let preparation = RecognitionCommitPreparation(
            committedText: "project adults",
            shouldCallASRCorrection: true
        )

        let committedText = await processor.process(
            preparation,
            configuration: configuredASRCorrectionConfiguration()
        )

        XCTAssertEqual(committedText, "project adults")
    }

    func testRecognitionCommitProcessorResultMarksCorrectedOutcomeWhenTextChanges() async {
        let processor = RecognitionCommitProcessor(
            engine: StubASRCorrectionEngine(result: .success("Project Atlas"))
        )
        let preparation = RecognitionCommitPreparation(
            committedText: "project adults",
            shouldCallASRCorrection: true
        )

        let result = await processor.processResult(
            preparation,
            configuration: configuredASRCorrectionConfiguration()
        )

        XCTAssertEqual(result.committedText, "Project Atlas")
        XCTAssertEqual(result.correctionOutcome, .corrected)
        XCTAssertTrue(result.didChangeText)
    }

    func testRecognitionCommitProcessorResultMarksUnchangedOutcomeWhenTextStaysSame() async {
        let processor = RecognitionCommitProcessor(
            engine: StubASRCorrectionEngine(result: .success("project adults"))
        )
        let preparation = RecognitionCommitPreparation(
            committedText: "project adults",
            shouldCallASRCorrection: true
        )

        let result = await processor.processResult(
            preparation,
            configuration: configuredASRCorrectionConfiguration()
        )

        XCTAssertEqual(result.committedText, "project adults")
        XCTAssertEqual(result.correctionOutcome, .unchanged)
        XCTAssertFalse(result.didChangeText)
    }

    func testRecognitionCommitProcessorResultMarksFallbackOutcomeWhenEngineFails() async {
        let processor = RecognitionCommitProcessor(
            engine: StubASRCorrectionEngine(result: .failure(StubASRCorrectionError.failed))
        )
        let preparation = RecognitionCommitPreparation(
            committedText: "project adults",
            shouldCallASRCorrection: true
        )

        let result = await processor.processResult(
            preparation,
            configuration: configuredASRCorrectionConfiguration()
        )

        XCTAssertEqual(result.committedText, "project adults")
        XCTAssertEqual(result.correctionOutcome, .fallback)
        XCTAssertFalse(result.didChangeText)
    }

    private func configuredASRCorrectionConfiguration() -> ASRCorrectionConfiguration {
        ASRCorrectionConfiguration(
            enabled: true,
            baseURL: "https://api.example.com/v1",
            apiKey: "token",
            model: "gpt-4.1-mini"
        )
    }
}

private struct StubASRCorrectionEngine: ASRCorrectionEngine {
    let result: Result<String, StubASRCorrectionError>

    func correct(
        _ request: ASRCorrectionRequest,
        configuration _: ASRCorrectionConfiguration
    ) async throws -> String {
        XCTAssertFalse(request.text.isEmpty)
        return try result.get()
    }
}

private enum StubASRCorrectionError: Error {
    case failed
}
