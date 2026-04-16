import Foundation
import XCTest

final class SpeechErrorReportScriptTests: XCTestCase {
    func testSpeechErrorReportSummarizesOutcomeLanguageAndErrorCode() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-speech-errors.py")

        let input = """
        2026-04-16 12:13:31.319 Df SpeakDock[95957:2e8a456] [com.leozejia.speakdock:speech] speech recognition start requested: language=zh-CN
        2026-04-16 12:13:31.340 Df SpeakDock[95957:2e8a456] [com.leozejia.speakdock:speech] speech recognition started: language=zh-CN
        2026-04-16 12:13:31.611 E  SpeakDock[95957:2e8a456] [com.leozejia.speakdock:speech] speech recognition task reported error: domain=kAFAssistantErrorDomain, code=1101
        2026-04-16 12:14:02.015 Df SpeakDock[96003:2e8a621] [com.leozejia.speakdock:speech] speech recognition start requested: language=en-US
        2026-04-16 12:14:02.029 Df SpeakDock[96003:2e8a621] [com.leozejia.speakdock:speech] speech recognition started: language=en-US
        2026-04-16 12:14:03.105 Df SpeakDock[96003:2e8a621] [com.leozejia.speakdock:speech] speech recognition final result received
        2026-04-16 12:14:30.000 Df SpeakDock[96091:2e8a833] [com.leozejia.speakdock:speech] speech recognition start requested: language=zh-CN
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
        XCTAssertTrue(output.contains("- failed: 1"))
        XCTAssertTrue(output.contains("- succeeded: 1"))
        XCTAssertTrue(output.contains("- unfinished: 1"))
        XCTAssertTrue(output.contains("- en-US: 1"))
        XCTAssertTrue(output.contains("- zh-CN: 2"))
        XCTAssertTrue(output.contains("- kAFAssistantErrorDomain#1101: 1"))
    }
}
