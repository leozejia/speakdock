import Foundation
import XCTest

final class ASRPostCorrectionEvalRunnerScriptTests: XCTestCase {
    func testRunnerWritesEvalResultsUsingMockResponses() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-asr-post-correction-eval.py")

        let fixture = """
        {
          "samples": [
            { "id": "term-001", "bucket": "term", "input": "project adults", "expected": "Project Atlas", "should_change": true, "source": "real-anonymized", "notes": "project name" },
            { "id": "control-001", "bucket": "control", "input": "今天先补匿名夹具。", "expected": "今天先补匿名夹具。", "should_change": false, "source": "real-anonymized", "notes": "clean" }
          ]
        }
        """

        let mockResponses = """
        {
          "term-001": { "output": "Project Atlas", "latency_ms": 180, "peak_rss_mb": 620 },
          "control-001": { "output": "今天先补匿名夹具。", "latency_ms": 120, "peak_rss_mb": 600 }
        }
        """

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("asr-post-correction-eval-runner-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fixtureURL = tempDirectory.appendingPathComponent("fixture.json")
        let mockResponsesURL = tempDirectory.appendingPathComponent("mock-responses.json")
        let resultsURL = tempDirectory.appendingPathComponent("results.json")
        try fixture.write(to: fixtureURL, atomically: true, encoding: .utf8)
        try mockResponses.write(to: mockResponsesURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            scriptURL.path,
            "--fixture", fixtureURL.path,
            "--results", resultsURL.path,
            "--mock-responses", mockResponsesURL.path,
            "--prompt-profile", "fewshot",
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultsURL.path))

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(decoding: outputData, as: UTF8.self)
        XCTAssertTrue(output.contains("samples: 2"))
        XCTAssertTrue(output.contains("prompt profile: fewshot"))
        XCTAssertTrue(output.contains("driver: mock"))

        let resultsData = try Data(contentsOf: resultsURL)
        let payload = try JSONSerialization.jsonObject(with: resultsData) as? [[String: Any]]
        XCTAssertEqual(payload?.count, 2)

        let termResult = payload?.first(where: { ($0["id"] as? String) == "term-001" })
        XCTAssertEqual(termResult?["output"] as? String, "Project Atlas")
        XCTAssertEqual(termResult?["outcome"] as? String, "corrected")
        XCTAssertEqual(termResult?["latency_ms"] as? Double, 180)

        let controlResult = payload?.first(where: { ($0["id"] as? String) == "control-001" })
        XCTAssertEqual(controlResult?["output"] as? String, "今天先补匿名夹具。")
        XCTAssertEqual(controlResult?["outcome"] as? String, "unchanged")
        XCTAssertEqual(controlResult?["peak_rss_mb"] as? Double, 600)
    }

    func testRunnerRejectsMissingModelPathAndMockResponses() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-asr-post-correction-eval.py")

        let fixture = """
        {
          "samples": [
            { "id": "term-001", "bucket": "term", "input": "project adults", "expected": "Project Atlas", "should_change": true, "source": "real-anonymized", "notes": "project name" }
          ]
        }
        """

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("asr-post-correction-eval-runner-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fixtureURL = tempDirectory.appendingPathComponent("fixture.json")
        let resultsURL = tempDirectory.appendingPathComponent("results.json")
        try fixture.write(to: fixtureURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            scriptURL.path,
            "--fixture", fixtureURL.path,
            "--results", resultsURL.path,
        ]

        let stderrPipe = Pipe()
        process.standardOutput = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        XCTAssertNotEqual(process.terminationStatus, 0)

        let errorData = try stderrPipe.fileHandleForReading.readToEnd() ?? Data()
        let errorOutput = String(decoding: errorData, as: UTF8.self)
        XCTAssertTrue(errorOutput.contains("either --model-path or --mock-responses is required"))
    }

    func testRunnerNormalizesPeakRSSAcrossByteAndKilobyteUnits() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-asr-post-correction-eval.py")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            "-c",
            """
            import importlib.util
            import json
            import sys

            spec = importlib.util.spec_from_file_location("runner", r"\(scriptURL.path)")
            module = importlib.util.module_from_spec(spec)
            sys.modules[spec.name] = module
            spec.loader.exec_module(module)

            payload = {
                "bytes": round(module.normalize_peak_rss(805306368), 2),
                "kilobytes": round(module.normalize_peak_rss(786432), 2),
            }
            print(json.dumps(payload))
            """,
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let payload = try JSONSerialization.jsonObject(with: outputData) as? [String: Double]

        XCTAssertEqual(payload?["bytes"], 768)
        XCTAssertEqual(payload?["kilobytes"], 768)
    }
}
