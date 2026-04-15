import AVFoundation
import Foundation

enum AudioCaptureAvailability: Equatable, Sendable {
    case available
    case unavailable(label: String)

    static var unavailableLabel: String {
        AppLocalizer.string(.overlayMicrophoneUnavailable)
    }
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
        SpeakDockLog.audio.notice("audio capture start requested")

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            SpeakDockLog.permission.debug("microphone permission already authorized")
            startCaptureIfNeeded()

        case .notDetermined:
            SpeakDockLog.permission.notice("requesting microphone permission")
            requestMicrophoneAccess()

        case .denied, .restricted:
            SpeakDockLog.permission.warning("microphone permission denied or restricted")
            reportUnavailable()

        @unknown default:
            SpeakDockLog.permission.warning("microphone permission unknown authorization status")
            reportUnavailable()
        }
    }

    func stop() {
        SpeakDockLog.audio.notice("audio capture stop requested")
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
                    SpeakDockLog.permission.notice("microphone permission granted")
                    self.startCaptureIfNeeded()
                } else {
                    SpeakDockLog.permission.warning("microphone permission denied")
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
        let tapBlock = makeAudioCaptureTapBlock(
            onAudioBufferCaptured: onAudioBufferCaptured,
            onLevelChanged: onLevelChanged
        )

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format, block: tapBlock)

        do {
            engine.prepare()
            try engine.start()
            isCapturing = true
            SpeakDockLog.audio.notice("audio capture started")
            onAvailabilityChanged?(.available)
            onLevelChanged?(0)
        } catch {
            inputNode.removeTap(onBus: 0)
            SpeakDockLog.audio.error("audio capture failed to start")
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
        SpeakDockLog.audio.notice("audio capture stopped")
        onLevelChanged?(0)
    }

    private func reportUnavailable() {
        stopCapture()
        SpeakDockLog.audio.error("audio capture unavailable")
        onAvailabilityChanged?(.unavailable(label: AudioCaptureAvailability.unavailableLabel))
    }

}
