import Foundation
import XCTest

final class ASRPostCorrectionFixtureBaselineTests: XCTestCase {
    func testAnonymousFixtureExistsAndDefinesExpectedBucketCounts() throws {
        guard let fixtureURL = Bundle.module.url(
            forResource: "asr-post-correction-anonymous-baseline",
            withExtension: "json"
        ) else {
            XCTFail("Missing asr post-correction anonymous baseline fixture")
            return
        }

        let data = try Data(contentsOf: fixtureURL)
        let fixture = try JSONDecoder().decode(ASRPostCorrectionFixture.self, from: data)

        XCTAssertEqual(fixture.samples.count, 48)
        XCTAssertEqual(fixture.bucketCounts["term"], 12)
        XCTAssertEqual(fixture.bucketCounts["mixed"], 12)
        XCTAssertEqual(fixture.bucketCounts["homophone"], 12)
        XCTAssertEqual(fixture.bucketCounts["control"], 12)
    }
}
