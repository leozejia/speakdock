import Foundation
import XCTest

@MainActor
final class TermLearningReportScriptTests: XCTestCase {
    func testTermLearningReportSummarizesAnonymousFixtureSnapshotAndOutcomeCounts() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-term-learning.py")
        let fixture = try TermLearningFixtureSupport.loadFixture()
        let replayResult = try TermLearningFixtureSupport.replayFixture(fixture)
        let storageURL = replayResult.storageURL

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path, "--storage", storageURL.path]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(decoding: outputData, as: UTF8.self)

        XCTAssertTrue(output.contains("Term Learning Report"))
        XCTAssertTrue(output.contains("confirmed entries: 2"))
        XCTAssertTrue(output.contains("observed corrections: 3"))
        XCTAssertTrue(output.contains("learning events: 9"))
        XCTAssertTrue(output.contains("- conflicted: 1"))
        XCTAssertTrue(output.contains("- observed: 6"))
        XCTAssertTrue(output.contains("- promoted: 1"))
        XCTAssertTrue(output.contains("- skippedConfirmed: 1"))
        XCTAssertTrue(output.contains("- local rank -> LocalRank evidence=1/3 status=observed"))
        XCTAssertTrue(output.contains("- pilot one -> PilotOne evidence=3/3 status=conflicted"))
        XCTAssertTrue(output.contains("- pilot one -> Pilot 1 evidence=1/3 status=conflicted"))
        XCTAssertTrue(output.contains("- Project Atlas <- project adults"))
        XCTAssertTrue(output.contains("- SpeakDock <- speak doc"))
    }
}
