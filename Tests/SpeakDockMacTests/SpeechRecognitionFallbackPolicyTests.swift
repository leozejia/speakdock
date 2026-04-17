import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class SpeechRecognitionFallbackPolicyTests: XCTestCase {
    func testUsesFinalTranscriptFallbackForFinishedNoSpeechError() {
        let diagnostics = SpeechRecognitionErrorDiagnostics(
            error: NSError(domain: "kAFAssistantErrorDomain", code: 1110)
        )

        let result = SpeechRecognitionFallbackPolicy.fallbackResult(
            latestTranscript: "Project Atlas",
            diagnostics: diagnostics,
            didRequestFinish: true,
            wantsRecognition: false
        )

        XCTAssertEqual(result, RecognitionResult(text: "Project Atlas", isFinal: true))
    }

    func testUsesEmptyFinalFallbackWhenFinishedNoSpeechErrorHasNoPartialTranscript() {
        let diagnostics = SpeechRecognitionErrorDiagnostics(
            error: NSError(domain: "kAFAssistantErrorDomain", code: 1110)
        )

        let result = SpeechRecognitionFallbackPolicy.fallbackResult(
            latestTranscript: "   ",
            diagnostics: diagnostics,
            didRequestFinish: true,
            wantsRecognition: false
        )

        XCTAssertEqual(result, RecognitionResult(text: "", isFinal: true))
    }

    func testDoesNotFallbackBeforeFinishWasRequested() {
        let diagnostics = SpeechRecognitionErrorDiagnostics(
            error: NSError(domain: "kAFAssistantErrorDomain", code: 1110)
        )

        let result = SpeechRecognitionFallbackPolicy.fallbackResult(
            latestTranscript: "Project Atlas",
            diagnostics: diagnostics,
            didRequestFinish: false,
            wantsRecognition: false
        )

        XCTAssertNil(result)
    }

    func testDoesNotFallbackForDifferentErrorCode() {
        let diagnostics = SpeechRecognitionErrorDiagnostics(
            error: NSError(domain: "kAFAssistantErrorDomain", code: 1101)
        )

        let result = SpeechRecognitionFallbackPolicy.fallbackResult(
            latestTranscript: "Project Atlas",
            diagnostics: diagnostics,
            didRequestFinish: true,
            wantsRecognition: false
        )

        XCTAssertNil(result)
    }
}
