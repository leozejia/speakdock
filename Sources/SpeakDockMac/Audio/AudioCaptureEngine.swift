import AVFoundation
import Foundation

enum AudioCaptureAvailability: Equatable, Sendable {
    case available
    case unavailable(label: String)
}

@MainActor
final class AudioCaptureEngine {
    var onLevelChanged: ((Float) -> Void)?
    var onAudioBufferCaptured: ((AVAudioPCMBuffer) -> Void)?
    var onAvailabilityChanged: ((AudioCaptureAvailability) -> Void)?

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
        var smoother = LevelSmoother()

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            self?.onAudioBufferCaptured?(buffer)
            let normalizedLevel = Self.normalizedRMSLevel(from: buffer)
            let smoothedLevel = smoother.ingest(normalizedLevel)

            DispatchQueue.main.async {
                self?.onLevelChanged?(smoothedLevel)
            }
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

    private static func normalizedRMSLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard
            let channelData = buffer.floatChannelData,
            buffer.frameLength > 0,
            buffer.format.channelCount > 0
        else {
            return 0
        }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        var sumSquares: Float = 0

        for channelIndex in 0..<channelCount {
            let samples = channelData[channelIndex]
            for sampleIndex in 0..<frameCount {
                let sample = samples[sampleIndex]
                sumSquares += sample * sample
            }
        }

        let meanSquare = sumSquares / Float(frameCount * channelCount)
        let rms = sqrt(meanSquare)
        let normalized = min(max(rms * 10, 0), 1)
        return normalized
    }
}
