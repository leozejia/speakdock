import Foundation
import XCTest

final class ASRPostCorrectionEvalReportScriptTests: XCTestCase {
    func testEvalReportSummarizesOverallAndPerBucketMetrics() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-asr-post-correction-eval.py")

        let fixture = """
        {
          "samples": [
            { "id": "term-001", "bucket": "term", "input": "project adults", "expected": "Project Atlas", "should_change": true, "source": "real-anonymized", "notes": "project name" },
            { "id": "mixed-001", "bucket": "mixed", "input": "make smoke asr correction", "expected": "make smoke-asr-correction", "should_change": true, "source": "real-anonymized", "notes": "make target" },
            { "id": "homophone-001", "bucket": "homophone", "input": "评测炸门", "expected": "评测闸门", "should_change": true, "source": "real-anonymized", "notes": "homophone" },
            { "id": "control-001", "bucket": "control", "input": "今天先补匿名夹具。", "expected": "今天先补匿名夹具。", "should_change": false, "source": "real-anonymized", "notes": "clean" }
          ]
        }
        """

        let results = """
        [
          { "id": "term-001", "output": "Project Atlas", "latency_ms": 120, "peak_rss_mb": 600, "outcome": "corrected" },
          { "id": "mixed-001", "output": "make smoke-asr-correction", "latency_ms": 180, "peak_rss_mb": 620, "outcome": "corrected" },
          { "id": "homophone-001", "output": "评测炸门", "latency_ms": 140, "peak_rss_mb": 610, "outcome": "unchanged" },
          { "id": "control-001", "output": "今天先补匿名夹具。", "latency_ms": 110, "peak_rss_mb": 590, "outcome": "unchanged" }
        ]
        """

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("asr-post-correction-eval-script-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fixtureURL = tempDirectory.appendingPathComponent("fixture.json")
        let resultsURL = tempDirectory.appendingPathComponent("results.json")
        try fixture.write(to: fixtureURL, atomically: true, encoding: .utf8)
        try results.write(to: resultsURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path, "--fixture", fixtureURL.path, "--results", resultsURL.path]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(decoding: outputData, as: UTF8.self)

        XCTAssertTrue(output.contains("samples: 4"))
        XCTAssertTrue(output.contains("exact match: 3/4 (75.00%)"))
        XCTAssertTrue(output.contains("over-edit: 0"))
        XCTAssertTrue(output.contains("fallback: 0"))
        XCTAssertTrue(output.contains("bucket term: 1/1 (100.00%)"))
        XCTAssertTrue(output.contains("bucket homophone: 0/1 (0.00%)"))
        XCTAssertTrue(output.contains("p50 latency: 130.00ms"))
        XCTAssertTrue(output.contains("p95 latency: 180.00ms"))
        XCTAssertTrue(output.contains("peak rss: 620.00MB"))
    }

    func testEvalReportFlagsOverEditAndFallback() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-asr-post-correction-eval.py")

        let fixture = """
        {
          "samples": [
            { "id": "control-001", "bucket": "control", "input": "不要改这句话。", "expected": "不要改这句话。", "should_change": false, "source": "real-anonymized", "notes": "clean" },
            { "id": "term-001", "bucket": "term", "input": "speak doc", "expected": "SpeakDock", "should_change": true, "source": "real-anonymized", "notes": "project name" }
          ]
        }
        """

        let results = """
        [
          { "id": "control-001", "output": "不要修改这句话。", "latency_ms": 200, "peak_rss_mb": 700, "outcome": "corrected" },
          { "id": "term-001", "output": "speak doc", "latency_ms": 250, "peak_rss_mb": 710, "outcome": "fallback" }
        ]
        """

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("asr-post-correction-eval-script-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fixtureURL = tempDirectory.appendingPathComponent("fixture.json")
        let resultsURL = tempDirectory.appendingPathComponent("results.json")
        try fixture.write(to: fixtureURL, atomically: true, encoding: .utf8)
        try results.write(to: resultsURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path, "--fixture", fixtureURL.path, "--results", resultsURL.path]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(decoding: outputData, as: UTF8.self)

        XCTAssertTrue(output.contains("exact match: 0/2 (0.00%)"))
        XCTAssertTrue(output.contains("over-edit: 1"))
        XCTAssertTrue(output.contains("fallback: 1"))
        XCTAssertTrue(output.contains("control over-edit: 1"))
    }
}
