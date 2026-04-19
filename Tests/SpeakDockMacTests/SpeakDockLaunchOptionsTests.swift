import XCTest
@testable import SpeakDockMac

final class SpeakDockLaunchOptionsTests: XCTestCase {
    func testDefaultsToNormalMode() {
        let options = SpeakDockLaunchOptions(arguments: ["SpeakDock"])

        XCTAssertEqual(options.mode, .normal)
        XCTAssertEqual(options.composeProbeDuration, SpeakDockLaunchOptions.defaultComposeProbeDuration)
        XCTAssertNil(options.runtimeASRCorrectionConfigurationOverride)
    }

    func testProbeModeParsesDuration() {
        let options = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--probe-compose", "--probe-compose-duration", "45"]
        )

        XCTAssertEqual(options.mode, .composeProbe)
        XCTAssertEqual(options.composeProbeDuration, 45)
    }

    func testProbeDurationIsBounded() {
        let shortOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--probe-compose", "--probe-compose-duration", "1"]
        )
        let longOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--probe-compose", "--probe-compose-duration", "999"]
        )

        XCTAssertEqual(shortOptions.composeProbeDuration, SpeakDockLaunchOptions.minimumComposeProbeDuration)
        XCTAssertEqual(longOptions.composeProbeDuration, SpeakDockLaunchOptions.maximumComposeProbeDuration)
    }

    func testSmokeModeParsesTextAndDelay() {
        let options = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--smoke-hot-path", "--smoke-text", "Project Atlas", "--smoke-delay", "1.5"]
        )

        XCTAssertEqual(options.mode, .smokeHotPath)
        XCTAssertEqual(options.smokeText, "Project Atlas")
        XCTAssertEqual(options.smokeDelay, 1.5)
    }

    func testSmokeModeParsesContinuationPhaseAndSecondText() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-hot-path",
                "--smoke-hot-path-phase", "continue-after-observed-edit",
                "--smoke-text", "hello",
                "--smoke-text-2", " again",
            ]
        )

        XCTAssertEqual(options.mode, .smokeHotPath)
        XCTAssertEqual(options.smokeHotPathPhase, .continueAfterObservedEdit)
        XCTAssertEqual(options.smokeText, "hello")
        XCTAssertEqual(options.smokeSecondText, " again")
    }

    func testSmokeModeParsesUndoRecentSubmissionPhase() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-hot-path",
                "--smoke-hot-path-phase", "undo-recent-submission",
                "--smoke-text", "hello",
            ]
        )

        XCTAssertEqual(options.mode, .smokeHotPath)
        XCTAssertEqual(options.smokeHotPathPhase, .undoRecentSubmission)
        XCTAssertEqual(options.smokeText, "hello")
    }

    func testSmokeModeParsesCaptureContinuationPhaseAndCaptureRootOverride() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-hot-path",
                "--smoke-hot-path-phase", "capture-continue-after-observed-edit",
                "--smoke-text", "hello",
                "--smoke-text-2", " again",
                "--smoke-capture-root", "/tmp/speakdock-capture-smoke",
            ]
        )

        XCTAssertEqual(options.mode, .smokeHotPath)
        XCTAssertEqual(options.smokeHotPathPhase, .captureContinueAfterObservedEdit)
        XCTAssertEqual(options.smokeText, "hello")
        XCTAssertEqual(options.smokeSecondText, " again")
        XCTAssertEqual(options.smokeCaptureRootPath, "/tmp/speakdock-capture-smoke")
    }

    func testSmokeModeParsesCaptureUndoPhaseAndCaptureRootOverride() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-hot-path",
                "--smoke-hot-path-phase", "capture-undo-recent-submission",
                "--smoke-text", "hello",
                "--smoke-capture-root", "/tmp/speakdock-capture-smoke",
            ]
        )

        XCTAssertEqual(options.mode, .smokeHotPath)
        XCTAssertEqual(options.smokeHotPathPhase, .captureUndoRecentSubmission)
        XCTAssertEqual(options.smokeText, "hello")
        XCTAssertEqual(options.smokeCaptureRootPath, "/tmp/speakdock-capture-smoke")
    }

    func testSmokeDelayIsBounded() {
        let shortOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--smoke-hot-path", "--smoke-text", "hello", "--smoke-delay", "0.1"]
        )
        let longOptions = SpeakDockLaunchOptions(
            arguments: ["SpeakDock", "--smoke-hot-path", "--smoke-text", "hello", "--smoke-delay", "99"]
        )

        XCTAssertEqual(shortOptions.smokeDelay, SpeakDockLaunchOptions.minimumSmokeDelay)
        XCTAssertEqual(longOptions.smokeDelay, SpeakDockLaunchOptions.maximumSmokeDelay)
    }

    func testSmokeRefineModeParsesEndpointOverrides() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-refine",
                "--smoke-text", "Project Atlas",
                "--smoke-delay", "1.2",
                "--smoke-refine-base-url", "http://127.0.0.1:8080/v1",
                "--smoke-refine-api-key", "smoke-token",
                "--smoke-refine-model", "smoke-model",
            ]
        )

        XCTAssertEqual(options.mode, .smokeRefine)
        XCTAssertEqual(options.smokeText, "Project Atlas")
        XCTAssertEqual(options.smokeDelay, 1.2)
        XCTAssertEqual(options.smokeRefineBaseURL, "http://127.0.0.1:8080/v1")
        XCTAssertEqual(options.smokeRefineAPIKey, "smoke-token")
        XCTAssertEqual(options.smokeRefineModel, "smoke-model")
    }

    func testSmokeRefineModeParsesManualPhaseOverride() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-refine",
                "--smoke-refine-phase", "manual",
                "--smoke-text", "Project Atlas",
            ]
        )

        XCTAssertEqual(options.mode, .smokeRefine)
        XCTAssertEqual(options.smokeRefinePhase, .manual)
    }

    func testSmokeRefineModeParsesCaptureTargetAndCaptureRootOverride() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-refine",
                "--smoke-refine-phase", "manual",
                "--smoke-refine-target", "capture",
                "--smoke-text", "Project Atlas",
                "--smoke-capture-root", "/tmp/speakdock-capture-refine",
            ]
        )

        XCTAssertEqual(options.mode, .smokeRefine)
        XCTAssertEqual(options.smokeRefinePhase, .manual)
        XCTAssertEqual(options.smokeRefineTarget, .capture)
        XCTAssertEqual(options.smokeCaptureRootPath, "/tmp/speakdock-capture-refine")
    }

    func testSmokeRefineModeParsesDirtyUndoPhaseOverride() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-refine",
                "--smoke-refine-phase", "dirty-undo",
                "--smoke-text", "Project Atlas",
            ]
        )

        XCTAssertEqual(options.mode, .smokeRefine)
        XCTAssertEqual(options.smokeRefinePhase, .dirtyUndo)
    }

    func testSmokeTermLearningModeParsesSubmitDelayAndStorageOverride() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-term-learning",
                "--smoke-text", "project adults 已经完成",
                "--smoke-delay", "0.8",
                "--smoke-submit-delay", "1.7",
                "--smoke-term-dictionary-storage", "/tmp/speakdock-term-dictionary.json",
            ]
        )

        XCTAssertEqual(options.mode, .smokeTermLearning)
        XCTAssertEqual(options.smokeText, "project adults 已经完成")
        XCTAssertEqual(options.smokeDelay, 0.8)
        XCTAssertEqual(options.smokeSubmitDelay, 1.7)
        XCTAssertEqual(options.smokeTermDictionaryStoragePath, "/tmp/speakdock-term-dictionary.json")
    }

    func testASRCorrectionOverrideParsesEndpointSettings() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--asr-correction-base-url", "http://127.0.0.1:8080/v1",
                "--asr-correction-api-key", "dev-token",
                "--asr-correction-model", "gpt-4.1-mini",
            ]
        )

        guard let configuration = options.runtimeASRCorrectionConfigurationOverride else {
            return XCTFail("Expected runtime ASR correction override")
        }

        XCTAssertTrue(configuration.enabled)
        XCTAssertEqual(configuration.baseURL, "http://127.0.0.1:8080/v1")
        XCTAssertEqual(configuration.apiKey, "dev-token")
        XCTAssertEqual(configuration.model, "gpt-4.1-mini")
    }

    func testASRCorrectionOverrideRequiresCompleteConfiguration() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--asr-correction-base-url", "http://127.0.0.1:8080/v1",
                "--asr-correction-model", "gpt-4.1-mini",
            ]
        )

        XCTAssertNil(options.runtimeASRCorrectionConfigurationOverride)
    }

    func testSmokeASRCorrectionModeParsesAsDedicatedMode() {
        let options = SpeakDockLaunchOptions(
            arguments: [
                "SpeakDock",
                "--smoke-asr-correction",
                "--smoke-text", "project adults 已经完成",
            ]
        )

        XCTAssertEqual(options.mode, .smokeASRCorrection)
        XCTAssertEqual(options.smokeText, "project adults 已经完成")
    }
}
