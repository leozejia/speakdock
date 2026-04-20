import Foundation
import XCTest

final class ASRSampleAccumulationReportScriptTests: XCTestCase {
    func testSpeechErrorReportIncludesRecentFailedSamplesForDirectTriage() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-speech-errors.py")

        let input = """
        2026-04-20 08:10:00.000 Df SpeakDock[201:aaa] [com.leozejia.speakdock:speech] speech recognition start requested: language=zh-CN
        2026-04-20 08:10:00.111 E  SpeakDock[201:aaa] [com.leozejia.speakdock:speech] speech recognition task reported error: domain=kAFAssistantErrorDomain, code=1110
        2026-04-20 08:12:30.000 Df SpeakDock[202:bbb] [com.leozejia.speakdock:speech] speech recognition start requested: language=en-US
        2026-04-20 08:12:31.050 Df SpeakDock[202:bbb] [com.leozejia.speakdock:speech] speech recognition final result received
        2026-04-20 08:15:45.000 Df SpeakDock[203:ccc] [com.leozejia.speakdock:speech] speech recognition start requested: language=zh-CN
        2026-04-20 08:15:45.222 E  SpeakDock[203:ccc] [com.leozejia.speakdock:speech] speech recognition task reported error: domain=kAFAssistantErrorDomain, code=1101
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

        XCTAssertTrue(output.contains("recent failed samples"))
        XCTAssertTrue(output.contains("- 2026-04-20 08:10:00 zh-CN kAFAssistantErrorDomain#1110"))
        XCTAssertTrue(output.contains("- 2026-04-20 08:15:45 zh-CN kAFAssistantErrorDomain#1101"))
    }
}
