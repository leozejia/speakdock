import XCTest
@testable import SpeakDockMac

final class RuntimeLocalizationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppLocalizer.setCurrentAppLanguage(.english)
    }

    override func tearDown() {
        AppLocalizer.setCurrentAppLanguage(.followSystem)
        super.tearDown()
    }

    func testOverlayDefaultsFollowChineseAppLanguage() {
        AppLocalizer.setCurrentAppLanguage(.simplifiedChinese)

        XCTAssertEqual(OverlayPhase.listening.title, "正在听")
        XCTAssertEqual(OverlayContent(phase: .listening).resolvedTranscript, "正在听...")
        XCTAssertEqual(OverlayContent(phase: .listening).secondaryActionTitle, "整理")
    }

    func testOverlayDefaultsFollowEnglishAppLanguage() {
        XCTAssertEqual(OverlayPhase.refining.title, "Refining")
        XCTAssertEqual(OverlayContent(phase: .thinking).resolvedTranscript, "Processing...")
        XCTAssertEqual(OverlayContent(phase: .thinking).secondaryActionTitle, "Refine")
    }

    func testUnavailableRuntimeLabelsFollowChineseAppLanguage() {
        AppLocalizer.setCurrentAppLanguage(.simplifiedChinese)

        XCTAssertEqual(AudioCaptureAvailability.unavailableLabel, "麦克风不可用")
        XCTAssertEqual(SpeechRecognitionAvailability.unavailableLabel, "语音识别不可用")
        XCTAssertEqual(ClipboardComposeTargetError.composeUnavailableReason, "无法直接输入")
    }

    func testUnavailableRuntimeLabelsFollowEnglishAppLanguage() {
        XCTAssertEqual(AudioCaptureAvailability.unavailableLabel, "Microphone Unavailable")
        XCTAssertEqual(SpeechRecognitionAvailability.unavailableLabel, "Speech Recognition Unavailable")
        XCTAssertEqual(ClipboardComposeTargetError.composeUnavailableReason, "Compose Unavailable")
    }
}
