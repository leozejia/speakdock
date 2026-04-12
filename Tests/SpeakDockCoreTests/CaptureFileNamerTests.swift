import XCTest
@testable import SpeakDockCore

final class CaptureFileNamerTests: XCTestCase {
    func testFileNameMatchesArchitectureTimestampFormat() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3_600)!

        let components = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 4,
            day: 11,
            hour: 23,
            minute: 16,
            second: 5
        )
        let date = components.date!

        let namer = CaptureFileNamer(timeZone: calendar.timeZone)

        XCTAssertEqual(namer.makeFileName(for: date), "speakdock-20260411-231605.md")
    }

    func testFileNameAlwaysUsesBrandPrefixAndMarkdownExtension() {
        let namer = CaptureFileNamer(timeZone: TimeZone(secondsFromGMT: 0)!)
        let fileName = namer.makeFileName(for: Date(timeIntervalSince1970: 0))

        XCTAssertTrue(fileName.hasPrefix("speakdock-"))
        XCTAssertTrue(fileName.hasSuffix(".md"))
    }
}
