import SpeakDockCore

struct SpeechRecognitionFallbackPolicy {
    static func fallbackResult(
        latestTranscript: String,
        diagnostics: SpeechRecognitionErrorDiagnostics,
        didRequestFinish: Bool,
        wantsRecognition: Bool
    ) -> RecognitionResult? {
        guard didRequestFinish, !wantsRecognition else {
            return nil
        }

        guard diagnostics.domain == "kAFAssistantErrorDomain",
              diagnostics.code == 1110
        else {
            return nil
        }

        return RecognitionResult(
            text: latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines),
            isFinal: true
        )
    }
}
