import AVFoundation
import Foundation
import OSLog
import Speech
import SpeakDockCore

enum SpeechRecognitionAvailability: Equatable, Sendable {
    case available
    case unavailable(label: String)

    static var unavailableLabel: String {
        AppLocalizer.string(.speechRecognitionUnavailable)
    }
}

protocol SpeechEngine: AnyObject {
    var onResult: ((RecognitionResult) -> Void)? { get set }
    var onAvailabilityChanged: ((SpeechRecognitionAvailability) -> Void)? { get set }

    func start(language: InputLanguageOption)
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer)
    func finish()
    func cancel()
}

final class AppleSpeechEngine: SpeechEngine, @unchecked Sendable {
    var onResult: ((RecognitionResult) -> Void)?
    var onAvailabilityChanged: ((SpeechRecognitionAvailability) -> Void)?

    private let queue = DispatchQueue(label: "SpeakDock.AppleSpeechEngine")
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var wantsRecognition = false
    private var currentLanguage = InputLanguageOption.defaultOption
    private var latestRecognitionTranscript = ""
    private var didRequestFinish = false

    func start(language: InputLanguageOption) {
        SpeakDockLog.speech.notice("speech recognition start requested: language=\(language.rawValue, privacy: .public)")
        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.wantsRecognition = true
            self.currentLanguage = language

            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized:
                SpeakDockLog.permission.debug("speech recognition permission already authorized")
                self.startRecognitionIfNeeded(language: language)

            case .notDetermined:
                SpeakDockLog.permission.notice("requesting speech recognition permission")
                self.requestAuthorization()

            case .denied, .restricted:
                SpeakDockLog.permission.warning("speech recognition permission denied or restricted")
                self.reportUnavailable()

            @unknown default:
                SpeakDockLog.permission.warning("speech recognition permission unknown authorization status")
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
        SpeakDockLog.speech.notice("speech recognition finish requested")
        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.wantsRecognition = false
            self.didRequestFinish = true
            self.recognitionRequest?.endAudio()
        }
    }

    func cancel() {
        SpeakDockLog.speech.notice("speech recognition cancel requested")
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
                    SpeakDockLog.permission.notice("speech recognition permission granted")
                    self.startRecognitionIfNeeded(language: self.currentLanguage)

                case .denied, .restricted, .notDetermined:
                    SpeakDockLog.permission.warning("speech recognition permission unavailable after request")
                    self.reportUnavailable()

                @unknown default:
                    SpeakDockLog.permission.warning("speech recognition permission unknown status after request")
                    self.reportUnavailable()
                }
            }
        }
    }

    private func startRecognitionIfNeeded(language: InputLanguageOption) {
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
        request.taskHint = .dictation

        self.recognizer = recognizer
        self.recognitionRequest = request
        self.latestRecognitionTranscript = ""
        self.didRequestFinish = false
        SpeakDockLog.speech.notice("speech recognition started: language=\(language.rawValue, privacy: .public)")
        notifyAvailability(.available)

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else {
                return
            }

            if let result {
                let transcript = result.bestTranscription.formattedString
                let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedTranscript.isEmpty {
                    self.latestRecognitionTranscript = trimmedTranscript
                }
                self.notifyResult(
                    RecognitionResult(
                        text: transcript,
                        isFinal: result.isFinal
                    )
                )

                if result.isFinal {
                    SpeakDockLog.speech.notice("speech recognition final result received")
                    self.queue.async {
                        self.resetRecognition(cancelTask: false)
                    }
                }
            }

            if let error {
                let diagnostics = SpeechRecognitionErrorDiagnostics(error: error)
                SpeakDockLog.speech.error(
                    "speech recognition task reported error: domain=\(diagnostics.domain, privacy: .public), code=\(diagnostics.code, privacy: .public)"
                )

                if let fallbackResult = SpeechRecognitionFallbackPolicy.fallbackResult(
                    latestTranscript: self.latestRecognitionTranscript,
                    diagnostics: diagnostics,
                    didRequestFinish: self.didRequestFinish,
                    wantsRecognition: self.wantsRecognition
                ) {
                    SpeakDockLog.speech.notice(
                        "speech recognition using final transcript fallback: domain=\(diagnostics.domain, privacy: .public), code=\(diagnostics.code, privacy: .public), transcriptLength=\(fallbackResult.text.count, privacy: .public)"
                    )
                    self.notifyResult(fallbackResult)
                }

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
        SpeakDockLog.speech.error("speech recognition unavailable")
        notifyAvailability(.unavailable(label: SpeechRecognitionAvailability.unavailableLabel))
    }

    private func resetRecognition(cancelTask: Bool) {
        if cancelTask {
            recognitionTask?.cancel()
        }

        recognitionTask = nil
        recognitionRequest = nil
        recognizer = nil
        latestRecognitionTranscript = ""
        didRequestFinish = false
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
