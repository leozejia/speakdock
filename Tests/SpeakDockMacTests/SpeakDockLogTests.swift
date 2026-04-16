import XCTest
@testable import SpeakDockMac

final class SpeakDockLogTests: XCTestCase {
    func testSubsystemAndCategoriesAreStableForUnifiedLogging() {
        XCTAssertEqual(SpeakDockLog.subsystem, "com.leozejia.speakdock")
        XCTAssertEqual(
            SpeakDockLog.Category.allCases.map(\.rawValue),
            [
                "lifecycle",
                "permission",
                "trace",
                "trigger",
                "audio",
                "speech",
                "compose",
                "capture",
                "refine",
            ]
        )
    }
}
