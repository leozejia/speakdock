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

    func testRunnerWritesEvalResultsUsingOpenAICompatibleEndpoint() throws {
        let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let scriptURL = rootURL.appendingPathComponent("scripts/run-asr-post-correction-eval.py")
        let stubServerURL = rootURL.appendingPathComponent("scripts/run-refine-stub-server.py")

        let fixture = """
        {
          "samples": [
            { "id": "term-001", "bucket": "term", "input": "project adults", "expected": "Project Atlas", "should_change": true, "source": "real-anonymized", "notes": "project name" }
          ]
        }
        """

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("asr-post-correction-eval-openai-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fixtureURL = tempDirectory.appendingPathComponent("fixture.json")
        let resultsURL = tempDirectory.appendingPathComponent("results.json")
        let requestURL = tempDirectory.appendingPathComponent("request.txt")
        try fixture.write(to: fixtureURL, atomically: true, encoding: .utf8)

        let port = try availableLocalPort()
        let server = Process()
        server.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        server.arguments = [
            stubServerURL.path,
            "--port", String(port),
            "--response-text", "Project Atlas",
            "--record-user-message", requestURL.path,
        ]
        server.standardOutput = Pipe()
        server.standardError = Pipe()

        try server.run()
        defer {
            if server.isRunning {
                server.terminate()
                server.waitUntilExit()
            }
        }

        XCTAssertTrue(waitForServerReady(port: port))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            scriptURL.path,
            "--fixture", fixtureURL.path,
            "--results", resultsURL.path,
            "--base-url", "http://127.0.0.1:\(port)/v1",
            "--api-key", "test-token",
            "--model", "gpt-5.4",
            "--prompt-profile", "fewshot_terms_homophone",
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
        XCTAssertTrue(output.contains("driver: openai-compatible"))

        let resultsData = try Data(contentsOf: resultsURL)
        let payload = try JSONSerialization.jsonObject(with: resultsData) as? [[String: Any]]
        XCTAssertEqual(payload?.count, 1)
        XCTAssertEqual(payload?.first?["output"] as? String, "Project Atlas")
        XCTAssertEqual(payload?.first?["outcome"] as? String, "corrected")

        let requestText = try String(contentsOf: requestURL, encoding: .utf8)
        XCTAssertEqual(requestText, "project adults 已经完成")
    }

    func testRunnerRejectsIncompleteOpenAICompatibleConfiguration() throws {
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
            .appendingPathComponent("asr-post-correction-eval-openai-\(UUID().uuidString)", isDirectory: true)
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
            "--base-url", "https://example.com/v1",
            "--model", "gpt-5.4",
        ]

        let stderrPipe = Pipe()
        process.standardOutput = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        XCTAssertNotEqual(process.terminationStatus, 0)

        let errorData = try stderrPipe.fileHandleForReading.readToEnd() ?? Data()
        let errorOutput = String(decoding: errorData, as: UTF8.self)
        XCTAssertTrue(errorOutput.contains("openai-compatible runs require --base-url, --model, and an API key"))
    }

    func testRunnerFailsFastWhenOpenAICompatibleEndpointReturnsHTTPError() throws {
        let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let scriptURL = rootURL.appendingPathComponent("scripts/run-asr-post-correction-eval.py")
        let stubServerURL = rootURL.appendingPathComponent("scripts/run-refine-stub-server.py")

        let fixture = """
        {
          "samples": [
            { "id": "term-001", "bucket": "term", "input": "project adults", "expected": "Project Atlas", "should_change": true, "source": "real-anonymized", "notes": "project name" }
          ]
        }
        """

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("asr-post-correction-eval-openai-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fixtureURL = tempDirectory.appendingPathComponent("fixture.json")
        let resultsURL = tempDirectory.appendingPathComponent("results.json")
        try fixture.write(to: fixtureURL, atomically: true, encoding: .utf8)

        let port = try availableLocalPort()
        let server = Process()
        server.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        server.arguments = [
            stubServerURL.path,
            "--port", String(port),
            "--response-text", "Project Atlas",
            "--status-code", "401",
        ]
        server.standardOutput = Pipe()
        server.standardError = Pipe()

        try server.run()
        defer {
            if server.isRunning {
                server.terminate()
                server.waitUntilExit()
            }
        }

        XCTAssertTrue(waitForServerReady(port: port))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            scriptURL.path,
            "--fixture", fixtureURL.path,
            "--results", resultsURL.path,
            "--base-url", "http://127.0.0.1:\(port)/v1",
            "--api-key", "test-token",
            "--model", "gpt-5.4",
        ]

        let stderrPipe = Pipe()
        process.standardOutput = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        XCTAssertNotEqual(process.terminationStatus, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: resultsURL.path))

        let errorData = try stderrPipe.fileHandleForReading.readToEnd() ?? Data()
        let errorOutput = String(decoding: errorData, as: UTF8.self)
        XCTAssertTrue(errorOutput.contains("openai-compatible request failed"))
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

    func testRunnerExposesTermAwareAndHomophoneAwarePromptProfiles() throws {
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
                "profiles": module.prompt_profiles(),
                "term_prompt": module.make_user_prompt("speak doc 今天更稳定", "fewshot_terms"),
                "homophone_prompt": module.make_user_prompt("现在先把评测炸门写死", "fewshot_terms_homophone"),
            }
            print(json.dumps(payload, ensure_ascii=False))
            """,
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let payload = try JSONSerialization.jsonObject(with: outputData) as? [String: Any]
        let profiles = payload?["profiles"] as? [String]
        let termPrompt = payload?["term_prompt"] as? String
        let homophonePrompt = payload?["homophone_prompt"] as? String

        XCTAssertTrue(profiles?.contains("fewshot_terms") == true)
        XCTAssertTrue(profiles?.contains("fewshot_terms_homophone") == true)
        XCTAssertTrue(termPrompt?.contains("SpeakDock 今天更稳定") == true)
        XCTAssertTrue(termPrompt?.contains("OpenAI-compatible 接口先留着") == true)
        XCTAssertTrue(homophonePrompt?.contains("现在先把评测闸门写死") == true)
        XCTAssertTrue(homophonePrompt?.contains("这里不要再漂移了") == true)
    }

    func testRunnerPromptAddsStructuredIdentifierHintsForMixedEngineeringFragments() throws {
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
                "prompt": module.make_user_prompt(
                    "这个字段用 should change 就行，主候选是 mlx community qwen three point five zero point eight b opt iq four bit",
                    "fewshot_terms_homophone"
                )
            }
            print(json.dumps(payload, ensure_ascii=False))
            """,
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let payload = try JSONSerialization.jsonObject(with: outputData) as? [String: String]
        let prompt = payload?["prompt"]

        XCTAssertTrue(prompt?.contains("以下工程片段如果明显是在指向固定写法，优先恢复成右侧格式") == true)
        XCTAssertTrue(prompt?.contains("should change -> should_change") == true)
        XCTAssertTrue(prompt?.contains("mlx community -> mlx-community") == true)
        XCTAssertTrue(prompt?.contains("qwen three point five -> Qwen3.5") == true)
        XCTAssertTrue(prompt?.contains("zero point eight b -> 0.8B") == true)
        XCTAssertTrue(prompt?.contains("opt iq -> OptiQ") == true)
        XCTAssertTrue(prompt?.contains("four bit -> 4bit") == true)
    }

    func testRunnerPromptAddsProductTermAndHomophoneHintsWhenKnownPhrasesAreHit() throws {
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
                "prompt": module.make_user_prompt(
                    "queen three asr 先别删，swift ui 页面先别动，今天先测图表组，这个版本先看邮化",
                    "fewshot_terms_homophone"
                )
            }
            print(json.dumps(payload, ensure_ascii=False))
            """,
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let payload = try JSONSerialization.jsonObject(with: outputData) as? [String: String]
        let prompt = payload?["prompt"]

        XCTAssertTrue(prompt?.contains("以下术语如果明显是在指向固定产品或技术名，优先恢复成右侧写法") == true)
        XCTAssertTrue(prompt?.contains("queen three asr -> Qwen3-ASR") == true)
        XCTAssertTrue(prompt?.contains("swift ui -> SwiftUI") == true)
        XCTAssertTrue(prompt?.contains("以下词如果明显是同音误识别，优先恢复成右侧写法") == true)
        XCTAssertTrue(prompt?.contains("图表组 -> 对照组") == true)
        XCTAssertTrue(prompt?.contains("邮化 -> 优化") == true)
    }

    func testRunnerPromptAddsWholeModelIdentifierHintsWhenKnownPhrasesAreHit() throws {
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
                "prompt": module.make_user_prompt(
                    "主候选就是 mlx community qwen three point five zero point eight b opt iq four bit，如果出问题就回到 qwen slash qwen three point five zero point eight b",
                    "fewshot_terms_homophone"
                )
            }
            print(json.dumps(payload, ensure_ascii=False))
            """,
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let payload = try JSONSerialization.jsonObject(with: outputData) as? [String: String]
        let prompt = payload?["prompt"]

        XCTAssertTrue(prompt?.contains("完整模型或仓库 ID 如果已经能确定，优先恢复成右侧整串写法") == true)
        XCTAssertTrue(prompt?.contains("mlx community qwen three point five zero point eight b opt iq four bit -> mlx-community/Qwen3.5-0.8B-OptiQ-4bit") == true)
        XCTAssertTrue(prompt?.contains("qwen slash qwen three point five zero point eight b -> Qwen/Qwen3.5-0.8B") == true)
    }

    func testRunnerStripsEchoedInputOutputWrapperFromModelOutput() throws {
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
                "wrapped": module.clean_output("输入：community 版本只是运行优化。\\n输出：community 版本只是运行优化。"),
                "plain": module.clean_output("SpeakDock 今天更稳定"),
            }
            print(json.dumps(payload, ensure_ascii=False))
            """,
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let payload = try JSONSerialization.jsonObject(with: outputData) as? [String: String]

        XCTAssertEqual(payload?["wrapped"], "community 版本只是运行优化。")
        XCTAssertEqual(payload?["plain"], "SpeakDock 今天更稳定")
    }

    private func availableLocalPort() throws -> Int {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            "-c",
            """
            import socket
            with socket.socket() as sock:
                sock.bind(("127.0.0.1", 0))
                print(sock.getsockname()[1])
            """,
        ]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let outputData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return try XCTUnwrap(Int(output))
    }

    private func waitForServerReady(port: Int) -> Bool {
        for _ in 0..<50 {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [
                "-c",
                """
                import socket
                import sys
                port = int(sys.argv[1])
                with socket.socket() as sock:
                    sock.settimeout(0.1)
                    try:
                        sock.connect(("127.0.0.1", port))
                    except OSError:
                        raise SystemExit(1)
                """,
                String(port),
            ]
            process.standardOutput = Pipe()
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    return true
                }
            } catch {
                return false
            }

            Thread.sleep(forTimeInterval: 0.1)
        }

        return false
    }
}
