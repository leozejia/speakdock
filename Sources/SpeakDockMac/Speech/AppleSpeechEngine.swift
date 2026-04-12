import AVFoundation
import Foundation
import Speech
import SpeakDockCore

enum SpeechRecognitionAvailability: Equatable, Sendable {
    case available
    case unavailable(label: String)
}

final class AppleSpeechEngine: @unchecked Sendable {
    var onResult: ((RecognitionResult) -> Void)?
    var onAvailabilityChanged: ((SpeechRecognitionAvailability) -> Void)?

    private let queue = DispatchQueue(label: "SpeakDock.AppleSpeechEngine")
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var wantsRecognition = false
    private var currentLanguage = LanguageOption.defaultOption

    func start(language: LanguageOption) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.wantsRecognition = true
            self.currentLanguage = language

            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized:
                self.startRecognitionIfNeeded(language: language)

            case .notDetermined:
                self.requestAuthorization()

            case .denied, .restricted:
                self.reportUnavailable()

            @unknown default:
                self.reportUnavailable()
            }
        }
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        queue.sync {
            recognitionRequest?.append(buffer)
        }
    }

    func finish() {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.wantsRecognition = false
            self.recognitionRequest?.endAudio()
        }
    }

    func cancel() {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.wantsRecognition = false
            self.resetRecognition(cancelTask: true)
        }
    }

    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self else {
                return
            }

            self.queue.async {
                switch status {
                case .authorized:
                    self.startRecognitionIfNeeded(language: self.currentLanguage)

                case .denied, .restricted, .notDetermined:
                    self.reportUnavailable()

                @unknown default:
                    self.reportUnavailable()
                }
            }
        }
    }

    private func startRecognitionIfNeeded(language: LanguageOption) {
        guard wantsRecognition else {
            return
        }

        resetRecognition(cancelTask: true)

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.rawValue)) else {
            reportUnavailable()
            return
        }

        guard recognizer.isAvailable else {
            reportUnavailable()
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        self.recognizer = recognizer
        self.recognitionRequest = request
        notifyAvailability(.available)

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else {
                return
            }

            if let result {
                self.notifyResult(
                    RecognitionResult(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal
                    )
                )

                if result.isFinal {
                    self.queue.async {
                        self.resetRecognition(cancelTask: false)
                    }
                }
            }

            if error != nil {
                self.queue.async {
                    let shouldReport = self.wantsRecognition
                    self.resetRecognition(cancelTask: false)
                    if shouldReport {
                        self.reportUnavailable()
                    }
                }
            }
        }
    }

    private func reportUnavailable() {
        resetRecognition(cancelTask: true)
        notifyAvailability(.unavailable(label: "Speech Recognition Unavailable"))
    }

    private func resetRecognition(cancelTask: Bool) {
        if cancelTask {
            recognitionTask?.cancel()
        }

        recognitionTask = nil
        recognitionRequest = nil
        recognizer = nil
    }

    private func notifyResult(_ result: RecognitionResult) {
        let handler = onResult
        DispatchQueue.main.async {
            handler?(result)
        }
    }

    private func notifyAvailability(_ availability: SpeechRecognitionAvailability) {
        let handler = onAvailabilityChanged
        DispatchQueue.main.async {
            handler?(availability)
        }
    }
}
