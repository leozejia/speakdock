import AVFoundation
import SpeakDockCore

@MainActor
final class SpeechController {
    var onRecognitionResult: ((RecognitionResult) -> Void)?
    var onAvailabilityChanged: ((SpeechRecognitionAvailability) -> Void)?

    private let settingsStore: SettingsStore
    private let speechEngine: any SpeechEngine

    private(set) var latestTranscript = ""

    init(
        settingsStore: SettingsStore,
        speechEngine: any SpeechEngine = AppleSpeechEngine()
    ) {
        self.settingsStore = settingsStore
        self.speechEngine = speechEngine

        speechEngine.onResult = { [weak self] result in
            self?.latestTranscript = result.text
            self?.onRecognitionResult?(result)
        }
        speechEngine.onAvailabilityChanged = { [weak self] availability in
            self?.onAvailabilityChanged?(availability)
        }
    }

    func startSession() {
        latestTranscript = ""
        speechEngine.start(language: currentInputLanguage)
    }

    func finishSession() {
        speechEngine.finish()
    }

    func cancelSession() {
        latestTranscript = ""
        speechEngine.cancel()
    }

    func makeAudioBufferAppender() -> (AVAudioPCMBuffer) -> Void {
        let speechEngine = self.speechEngine
        return { buffer in
            speechEngine.appendAudioBuffer(buffer)
        }
    }

    private var currentInputLanguage: InputLanguageOption {
        settingsStore.settings.inputLanguage
    }
}
