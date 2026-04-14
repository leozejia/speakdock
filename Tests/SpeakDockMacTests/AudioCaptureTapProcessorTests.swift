import AVFoundation
import XCTest
@testable import SpeakDockMac

private final class AudioCaptureTapProcessorRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var capturedBufferCount = 0
    private var levelUpdates: [Float] = []

    func recordBuffer() {
        lock.withLock {
            capturedBufferCount += 1
        }
    }

    func recordLevel(_ level: Float) {
        lock.withLock {
            levelUpdates.append(level)
        }
    }

    func snapshot() -> (capturedBufferCount: Int, levelUpdates: [Float]) {
        lock.withLock {
            (capturedBufferCount, levelUpdates)
        }
    }
}

final class AudioCaptureTapProcessorTests: XCTestCase {
    @MainActor
    func testSpeechAudioBufferAppenderCreatedOnMainActorCanRunOffMainThread() throws {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2))
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let speechController = SpeechController(
            settingsStore: SettingsStore(defaults: defaults, migrator: CaptureRootMigrator())
        )
        let appender = speechController.makeAudioBufferAppender()

        DispatchQueue.global(qos: .userInitiated).sync {
            appender(buffer)
        }
    }

    @MainActor
    func testAudioTapBlockCreatedOnMainActorCanRunOffMainThread() throws {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2))
        buffer.frameLength = 2
        buffer.floatChannelData?[0][0] = 0.2
        buffer.floatChannelData?[0][1] = 0.4

        let recorder = AudioCaptureTapProcessorRecorder()
        let levelExpectation = expectation(description: "level update is delivered on the main actor")
        let tapBlock = makeAudioCaptureTapBlock(
            onAudioBufferCaptured: { _ in
                recorder.recordBuffer()
            },
            onLevelChanged: { level in
                recorder.recordLevel(level)
                levelExpectation.fulfill()
            }
        )

        DispatchQueue.global(qos: .userInitiated).sync {
            tapBlock(buffer, AVAudioTime(sampleTime: 0, atRate: 44_100))
        }

        wait(for: [levelExpectation], timeout: 1)

        let snapshot = recorder.snapshot()
        XCTAssertEqual(snapshot.capturedBufferCount, 1)
        XCTAssertEqual(snapshot.levelUpdates.count, 1)
        XCTAssertGreaterThan(snapshot.levelUpdates[0], 0)
    }

    func testTapProcessorCanRunOffMainThreadAndDispatchLevelUpdates() throws {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2))
        buffer.frameLength = 2
        buffer.floatChannelData?[0][0] = 0.2
        buffer.floatChannelData?[0][1] = 0.4

        let recorder = AudioCaptureTapProcessorRecorder()
        let levelExpectation = expectation(description: "level update is delivered on the main actor")
        var processor = AudioCaptureTapProcessor(
            onAudioBufferCaptured: { _ in
                recorder.recordBuffer()
            },
            onLevelChanged: { level in
                recorder.recordLevel(level)
                levelExpectation.fulfill()
            }
        )

        DispatchQueue.global().sync {
            processor.handle(buffer)
        }

        wait(for: [levelExpectation], timeout: 1)

        let snapshot = recorder.snapshot()
        XCTAssertEqual(snapshot.capturedBufferCount, 1)
        XCTAssertEqual(snapshot.levelUpdates.count, 1)
        XCTAssertGreaterThan(snapshot.levelUpdates[0], 0)
    }
}
