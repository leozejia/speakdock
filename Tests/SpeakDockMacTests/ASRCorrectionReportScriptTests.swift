import Foundation
import XCTest

final class ASRCorrectionReportScriptTests: XCTestCase {
    func testASRCorrectionReportSummarizesOutcomeAndChangeCounts() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-asr-correction.py")

        let input = """
        2026-04-19 10:02:11.000 Df SpeakDock[101:abc] [com.leozejia.speakdock:speech] asr correction commit finished: outcome=corrected, changed=true, inputLength=14, outputLength=13
        2026-04-19 10:02:22.000 Df SpeakDock[102:def] [com.leozejia.speakdock:speech] asr correction commit finished: outcome=unchanged, changed=false, inputLength=13, outputLength=13
        2026-04-19 10:02:33.000 Df SpeakDock[103:ghi] [com.leozejia.speakdock:speech] asr correction commit finished: outcome=fallback, changed=false, inputLength=14, outputLength=14
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path, "--stdin"]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        stdinPipe.fileHandleForWriting.write(Data(input.utf8))
        try stdinPipe.fileHandleForWriting.close()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(decoding: outputData, as: UTF8.self)

        XCTAssertTrue(output.contains("sessions: 3"))
        XCTAssertTrue(output.contains("- corrected: 1"))
        XCTAssertTrue(output.contains("- unchanged: 1"))
        XCTAssertTrue(output.contains("- fallback: 1"))
        XCTAssertTrue(output.contains("- true: 1"))
        XCTAssertTrue(output.contains("- false: 2"))
    }

    func testASRCorrectionReportShowsEvaluationReadinessAndRates() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-asr-correction.py")

        let input = """
        2026-04-19 10:02:11.000 Df SpeakDock[101:abc] [com.leozejia.speakdock:speech] asr correction commit finished: outcome=corrected, changed=true, inputLength=14, outputLength=13
        2026-04-19 10:02:22.000 Df SpeakDock[102:def] [com.leozejia.speakdock:speech] asr correction commit finished: outcome=unchanged, changed=false, inputLength=13, outputLength=13
        2026-04-19 10:02:33.000 Df SpeakDock[103:ghi] [com.leozejia.speakdock:speech] asr correction commit finished: outcome=fallback, changed=false, inputLength=14, outputLength=14
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptURL.path, "--stdin", "--min-samples", "5"]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        stdinPipe.fileHandleForWriting.write(Data(input.utf8))
        try stdinPipe.fileHandleForWriting.close()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(decoding: outputData, as: UTF8.self)

        XCTAssertTrue(output.contains("changed rate: 33.33%"))
        XCTAssertTrue(output.contains("fallback rate: 33.33%"))
        XCTAssertTrue(output.contains("evaluation readiness: 3/5 sessions (not ready)"))
    }
}
