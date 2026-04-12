import XCTest
@testable import SpeakDockMac

final class LevelSmootherTests: XCTestCase {
    func testRMSInputIsSmoothedWithAttackAndRelease() {
        var smoother = LevelSmoother()

        let rise = smoother.ingest(1.0)
        let fall = smoother.ingest(0.0)

        XCTAssertEqual(rise, 0.4, accuracy: 0.0001)
        XCTAssertEqual(fall, 0.34, accuracy: 0.0001)
    }

    func testLowLevelConvergesDownward() {
        var smoother = LevelSmoother()

        _ = smoother.ingest(1.0)
        _ = smoother.ingest(1.0)

        let decayLevels = (0..<8).map { _ in
            smoother.ingest(0.0)
        }

        XCTAssertLessThan(decayLevels.last ?? 1.0, 0.2)
        XCTAssertTrue(zip(decayLevels, decayLevels.dropFirst()).allSatisfy(>))
    }

    func testHighLevelRisesClearly() {
        var smoother = LevelSmoother()

        let quiet = smoother.ingest(0.1)
        let loud = smoother.ingest(0.9)

        XCTAssertGreaterThan(loud, 0.3)
        XCTAssertGreaterThan(loud - quiet, 0.25)
    }
}
