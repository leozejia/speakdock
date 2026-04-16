import XCTest
@testable import SpeakDockMac

final class EditableTextObservationContextTests: XCTestCase {
    func testObservedTextUsesCapturedPrefixAndSuffix() {
        let context = EditableTextObservationContext(
            fullText: "hello selected world",
            selectedRange: NSRange(location: 6, length: 8)
        )

        XCTAssertEqual(
            context?.observedText(in: "hello corrected world"),
            "corrected"
        )
    }
}
