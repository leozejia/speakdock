import XCTest
@testable import SpeakDockMac
import SpeakDockCore

@MainActor
final class TermLearningFixtureBaselineTests: XCTestCase {
    func testAnonymousFixtureReplaysIntoExpectedSnapshot() throws {
        let fixture = try TermLearningFixtureSupport.loadFixture()
        let replayResult = try TermLearningFixtureSupport.replayFixture(fixture)
        let snapshot = replayResult.snapshot

        XCTAssertEqual(snapshot.pendingCandidates, [])
        XCTAssertEqual(snapshot.confirmedEntries, fixture.expectations.confirmedEntries)
        XCTAssertEqual(
            TermLearningFixtureSupport.sortedObservedCorrections(snapshot.observedCorrections),
            TermLearningFixtureSupport.sortedObservedCorrections(fixture.expectations.observedCorrections)
        )
        XCTAssertEqual(
            TermLearningFixtureSupport.outcomeCounts(from: snapshot),
            fixture.expectations.outcomeCounts
        )
    }
}
