import XCTest
import AVFoundation
import SpeakDockCore
@testable import SpeakDockMac

@MainActor
final class SpeechControllerTests: XCTestCase {
    func testStartSessionUsesConfiguredInputLanguageInsteadOfAppLanguage() {
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.appLanguage = .english
        settingsStore.settings.inputLanguage = .korean

        let speechEngine = SpySpeechEngine()
        let controller = SpeechController(
            settingsStore: settingsStore,
            speechEngine: speechEngine
        )

        controller.startSession()

        XCTAssertEqual(speechEngine.startedLanguages, [.korean])
    }
}

private final class SpySpeechEngine: SpeechEngine {
    var onResult: ((RecognitionResult) -> Void)?
    var onAvailabilityChanged: ((SpeechRecognitionAvailability) -> Void)?
    var startedLanguages: [InputLanguageOption] = []

    func start(language: InputLanguageOption) {
        startedLanguages.append(language)
    }

    func appendAudioBuffer(_: AVAudioPCMBuffer) {}

    func finish() {}

    func cancel() {}
}
