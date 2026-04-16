import Foundation
import XCTest

final class TraceReportScriptTests: XCTestCase {
    func testTraceReportSummarizesKindsResultsOriginsRoutesAndLatency() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-traces.py")

        let input = """
        2026-04-16 12:13:31.319 Df SpeakDock[95957:2e8a456] [com.leozejia.speakdock:trace] trace.finish interaction=E4C905BF-35B5-4643-852F-6BEF7F0026CE kind=recording origin=smoke result=composeCommitted total=0.120 route=compose commit=0.070
        2026-04-16 12:13:41.797 Df SpeakDock[96576:2e8a9a2] [com.leozejia.speakdock:trace] trace.finish interaction=EC89B546-9C1A-4B69-8DD3-DB9D60A2CE67 kind=submit origin=smoke result=submitSucceeded total=0.187
        2026-04-16 12:14:22.718 Df SpeakDock[98303:2e8b928] [com.leozejia.speakdock:trace] trace.finish interaction=F6A1773B-2FE8-4BE1-B2C2-106093010DE4 kind=submit origin=live result=submitFailed total=0.192
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

        XCTAssertTrue(output.contains("events: 3"))
        XCTAssertTrue(output.contains("- recording: 1"))
        XCTAssertTrue(output.contains("- submit: 2"))
        XCTAssertTrue(output.contains("- composeCommitted: 1"))
        XCTAssertTrue(output.contains("- submitSucceeded: 1"))
        XCTAssertTrue(output.contains("- submitFailed: 1"))
        XCTAssertTrue(output.contains("- smoke: 2"))
        XCTAssertTrue(output.contains("- live: 1"))
        XCTAssertTrue(output.contains("- compose: 1"))
        XCTAssertTrue(output.contains("- total: count=3 avg=166ms p50=187ms p95=192ms max=192ms"))
        XCTAssertTrue(output.contains("- commit: count=1 avg=70ms p50=70ms p95=70ms max=70ms"))
    }
}
