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
}
