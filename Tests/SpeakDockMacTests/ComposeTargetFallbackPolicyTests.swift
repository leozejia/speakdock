import ApplicationServices
import XCTest
@testable import SpeakDockMac

final class ComposeTargetFallbackPolicyTests: XCTestCase {
    func testSystemWideNoValueFallsBackToFrontmostApplicationLookup() {
        XCTAssertTrue(
            ComposeTargetFallbackPolicy.shouldQueryFrontmostApplication(
                afterSystemWideFocusedElementError: .noValue
            )
        )
    }

    func testAPIDisabledDoesNotFallBackToFrontmostApplicationLookup() {
        XCTAssertFalse(
            ComposeTargetFallbackPolicy.shouldQueryFrontmostApplication(
                afterSystemWideFocusedElementError: .apiDisabled
            )
        )
    }

    func testWeChatCanUsePasteOnlyFrontmostApplicationFallback() {
        XCTAssertTrue(
            ComposeTargetFallbackPolicy.shouldUsePasteOnlyFrontmostApplicationFallback(
                bundleIdentifier: "com.tencent.xinWeChat"
            )
        )
    }

    func testUnknownBundleCannotUsePasteOnlyFrontmostApplicationFallback() {
        XCTAssertFalse(
            ComposeTargetFallbackPolicy.shouldUsePasteOnlyFrontmostApplicationFallback(
                bundleIdentifier: "com.example.Unknown"
            )
        )
    }
}
