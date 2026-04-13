import AVFoundation
import Foundation

enum AudioCaptureAvailability: Equatable, Sendable {
    case available
    case unavailable(label: String)
}

@MainActor
final class AudioCaptureEngine {
    var onLevelChanged: (@MainActor (Float) -> Void)?
    var onAudioBufferCaptured: ((AVAudioPCMBuffer) -> Void)?
    var onAvailabilityChanged: (@MainActor (AudioCaptureAvailability) -> Void)?

    private let engine: AVAudioEngine
    private var wantsCapture = false
    private var isCapturing = false

    init(engine: AVAudioEngine = AVAudioEngine()) {
        self.engine = engine
    }

    func start() {
        wantsCapture = true

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            startCaptureIfNeeded()

        case .notDetermined:
            requestMicrophoneAccess()

        case .denied, .restricted:
            reportUnavailable()

        @unknown default:
            reportUnavailable()
        }
    }

    func stop() {
        wantsCapture = false
        stopCapture()
    }

    private func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                if granted {
                    self.startCaptureIfNeeded()
                } else {
                    self.reportUnavailable()
                }
            }
        }
    }

    private func startCaptureIfNeeded() {
        guard wantsCapture, !isCapturing else {
            return
        }

        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        var tapProcessor = AudioCaptureTapProcessor(
            onAudioBufferCaptured: onAudioBufferCaptured,
            onLevelChanged: onLevelChanged
        )

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            tapProcessor.handle(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
            isCapturing = true
            onAvailabilityChanged?(.available)
            onLevelChanged?(0)
        } catch {
            inputNode.removeTap(onBus: 0)
            reportUnavailable()
        }
    }

    private func stopCapture() {
        guard isCapturing else {
            onLevelChanged?(0)
            return
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        engine.reset()
        isCapturing = false
        onLevelChanged?(0)
    }

    private func reportUnavailable() {
        stopCapture()
        onAvailabilityChanged?(.unavailable(label: "Microphone Unavailable"))
    }

}
