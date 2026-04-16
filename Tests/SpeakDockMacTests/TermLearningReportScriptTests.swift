import Foundation
import XCTest

final class TermLearningReportScriptTests: XCTestCase {
    func testTermLearningReportSummarizesCurrentSnapshotAndOutcomeCounts() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-term-learning.py")
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("term-learning-report-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let storageURL = temporaryDirectory.appendingPathComponent("term-dictionary.json")
        let snapshot = """
        {
          "confirmedEntries": [
            {
              "canonicalTerm": "SpeakDock",
              "aliases": ["speak dock"]
            }
          ],
          "pendingCandidates": [],
          "observedCorrections": [
            {
              "canonicalTerm": "Project Atlas",
              "alias": "project adults",
              "evidenceCount": 2
            },
            {
              "canonicalTerm": "Project Alice",
              "alias": "project adults",
              "evidenceCount": 1
            }
          ],
          "learningEvents": [
            {
              "canonicalTerm": "Project Atlas",
              "alias": "project adults",
              "outcome": "observed",
              "evidenceCount": 1
            },
            {
              "canonicalTerm": "Project Atlas",
              "alias": "project adults",
              "outcome": "observed",
              "evidenceCount": 2
            },
            {
              "canonicalTerm": "Project Atlas",
              "alias": "project adults",
              "outcome": "conflicted",
              "evidenceCount": 3
            },
            {
              "canonicalTerm": "SpeakDock",
              "alias": "speak dock",
              "outcome": "skippedConfirmed",
              "evidenceCount": 0
            }
          ]
        }
        """
        try snapshot.write(to: storageURL, atomically: true, encoding: .utf8)

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
        XCTAssertTrue(output.contains("confirmed entries: 1"))
        XCTAssertTrue(output.contains("observed corrections: 2"))
        XCTAssertTrue(output.contains("learning events: 4"))
        XCTAssertTrue(output.contains("- conflicted: 1"))
        XCTAssertTrue(output.contains("- observed: 2"))
        XCTAssertTrue(output.contains("- skippedConfirmed: 1"))
        XCTAssertTrue(output.contains("- project adults -> Project Atlas evidence=2/3 status=conflicted"))
        XCTAssertTrue(output.contains("- project adults -> Project Alice evidence=1/3 status=conflicted"))
        XCTAssertTrue(output.contains("- SpeakDock <- speak dock"))
    }
}
