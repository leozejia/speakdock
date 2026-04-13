import AVFoundation
import Foundation

struct AudioCaptureTapProcessor {
    private var smoother = LevelSmoother()
    private let onAudioBufferCaptured: ((AVAudioPCMBuffer) -> Void)?
    private let onLevelChanged: (@MainActor (Float) -> Void)?

    init(
        onAudioBufferCaptured: ((AVAudioPCMBuffer) -> Void)?,
        onLevelChanged: (@MainActor (Float) -> Void)?
    ) {
        self.onAudioBufferCaptured = onAudioBufferCaptured
        self.onLevelChanged = onLevelChanged
    }

    mutating func handle(_ buffer: AVAudioPCMBuffer) {
        onAudioBufferCaptured?(buffer)

        let normalizedLevel = Self.normalizedRMSLevel(from: buffer)
        let smoothedLevel = smoother.ingest(normalizedLevel)
        let onLevelChanged = onLevelChanged
        Task { @MainActor in
            onLevelChanged?(smoothedLevel)
        }
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
        return min(max(rms * 10, 0), 1)
    }
}

func makeAudioCaptureTapBlock(
    onAudioBufferCaptured: ((AVAudioPCMBuffer) -> Void)?,
    onLevelChanged: (@MainActor (Float) -> Void)?
) -> AVAudioNodeTapBlock {
    let handler = AudioCaptureTapBlockHandler(
        processor: AudioCaptureTapProcessor(
            onAudioBufferCaptured: onAudioBufferCaptured,
            onLevelChanged: onLevelChanged
        )
    )

    return { buffer, _ in
        handler.handle(buffer)
    }
}

private final class AudioCaptureTapBlockHandler: @unchecked Sendable {
    private var processor: AudioCaptureTapProcessor

    init(processor: AudioCaptureTapProcessor) {
        self.processor = processor
    }

    func handle(_ buffer: AVAudioPCMBuffer) {
        processor.handle(buffer)
    }
}
