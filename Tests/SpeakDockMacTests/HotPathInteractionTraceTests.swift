import XCTest
@testable import SpeakDockMac

final class HotPathInteractionTraceTests: XCTestCase {
    func testFinishSummaryIncludesStableInteractionIDAndStageDurations() {
        let interactionID = UUID(uuidString: "12345678-1234-5678-1234-567812345678")!
        var trace = HotPathInteractionTrace(
            id: interactionID,
            kind: .recording,
            origin: .live,
            startedAt: 10
        )

        trace.markPressEnded(at: 12.4)
        trace.markRecognitionFinal(at: 13.1)
        trace.markCommitStarted(route: .compose, at: 13.25)

        let summary = trace.finish(result: .composeCommitted, at: 13.4)

        XCTAssertEqual(summary.interactionID, interactionID.uuidString)
        XCTAssertEqual(summary.kind, .recording)
        XCTAssertEqual(summary.origin, .live)
        XCTAssertEqual(summary.route, .compose)
        XCTAssertEqual(summary.result, .composeCommitted)
        XCTAssertEqual(summary.totalDuration, 3.4, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(summary.pressDuration), 2.4, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(summary.recognitionDuration), 0.7, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(summary.commitDuration), 0.15, accuracy: 0.0001)
        XCTAssertEqual(
            summary.logMessage,
            "trace.finish interaction=12345678-1234-5678-1234-567812345678 kind=recording origin=live result=composeCommitted total=3.400 route=compose press=2.400 recognition=0.700 commit=0.150"
        )
    }

    func testFinishSummaryUsesSmokeOriginAndOmitsMissingStages() {
        let interactionID = UUID(uuidString: "87654321-4321-8765-4321-876543218765")!
        let trace = HotPathInteractionTrace(
            id: interactionID,
            kind: .recording,
            origin: .smoke,
            startedAt: 20
        )

        let summary = trace.finish(result: .emptyTranscript, at: 20.5)

        XCTAssertEqual(summary.interactionID, interactionID.uuidString)
        XCTAssertEqual(summary.origin, .smoke)
        XCTAssertEqual(summary.result, .emptyTranscript)
        XCTAssertNil(summary.route)
        XCTAssertNil(summary.pressDuration)
        XCTAssertNil(summary.recognitionDuration)
        XCTAssertNil(summary.commitDuration)
        XCTAssertEqual(summary.totalDuration, 0.5, accuracy: 0.0001)
    }
}
