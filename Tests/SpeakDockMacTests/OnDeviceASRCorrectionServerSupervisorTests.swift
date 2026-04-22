import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class OnDeviceASRCorrectionServerSupervisorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        mockOnDeviceASRCorrectionReadinessRequestStore.requestHandler = nil
    }

    override func tearDown() {
        mockOnDeviceASRCorrectionReadinessRequestStore.requestHandler = nil
        super.tearDown()
    }

    func testCommandBuilderReturnsNilWhenExecutableCannotBeResolved() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let command = OnDeviceASRCorrectionServerCommandBuilder.makeCommand(
            for: makeOnDeviceConfiguration(),
            environment: [
                OnDeviceASRCorrectionServerCommandBuilder.executableOverrideEnvironmentKey: "",
                "PATH": "/definitely/missing",
            ],
            currentDirectoryPath: temporaryDirectory.path
        )

        XCTAssertNil(command)
    }

    @MainActor
    func testSyncStartsMLXLMServerWhenOnDeviceCorrectionIsEnabled() throws {
        let process = ProcessSpy()
        var launchedCommand: OnDeviceASRCorrectionServerCommand?
        let supervisor = OnDeviceASRCorrectionServerSupervisor(
            commandBuilder: { configuration in
                OnDeviceASRCorrectionServerCommandBuilder.makeCommand(for: configuration)
            },
            launcher: { command in
                launchedCommand = command
                process.isRunning = true
                return process
            },
            readinessChecker: { _ in
                .ready
            }
        )

        supervisor.sync(
            configuration: makeOnDeviceConfiguration()
        )

        let command = try XCTUnwrap(launchedCommand)
        XCTAssertTrue(command.arguments.contains("--host"))
        XCTAssertTrue(command.arguments.contains("127.0.0.1"))
        XCTAssertTrue(command.arguments.contains("--port"))
        XCTAssertTrue(command.arguments.contains("42100"))
        XCTAssertTrue(command.arguments.contains("--model"))
        XCTAssertTrue(command.arguments.contains(OnDeviceASRCorrectionDefaults.modelIdentifier))
    }

    @MainActor
    func testSyncMarksStatusFailedWhenExecutableIsUnavailable() {
        let supervisor = OnDeviceASRCorrectionServerSupervisor(
            commandBuilder: { _ in nil },
            launcher: { _ in
                XCTFail("launcher should not be called when executable is unavailable")
                return ProcessSpy()
            },
            readinessChecker: { _ in
                .ready
            }
        )

        supervisor.sync(configuration: makeOnDeviceConfiguration())

        XCTAssertEqual(supervisor.status, .failed(.executableUnavailable))
    }

    @MainActor
    func testSyncMarksStatusReadyAfterReadinessProbeSucceeds() async {
        let process = ProcessSpy()
        let supervisor = OnDeviceASRCorrectionServerSupervisor(
            commandBuilder: { _ in
                OnDeviceASRCorrectionServerCommand(
                    executablePath: "/usr/bin/true",
                    arguments: []
                )
            },
            launcher: { _ in
                process.isRunning = true
                return process
            },
            readinessChecker: { _ in
                .ready
            }
        )

        supervisor.sync(configuration: makeOnDeviceConfiguration())
        for _ in 0..<10 {
            if supervisor.status == .ready {
                break
            }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTAssertEqual(supervisor.status, .ready)
    }

    @MainActor
    func testSyncStopsRunningServerWhenConfigurationLeavesOnDeviceMode() throws {
        let process = ProcessSpy()
        let supervisor = OnDeviceASRCorrectionServerSupervisor(
            commandBuilder: { configuration in
                OnDeviceASRCorrectionServerCommandBuilder.makeCommand(for: configuration)
            },
            launcher: { _ in
                process.isRunning = true
                return process
            },
            readinessChecker: { _ in
                .ready
            }
        )

        supervisor.sync(configuration: makeOnDeviceConfiguration())
        supervisor.sync(configuration: ASRCorrectionConfiguration.disabled)

        XCTAssertEqual(process.terminateCallCount, 1)
        XCTAssertEqual(supervisor.status, .inactive)
    }

    func testReadinessCheckerReturnsReadyWhenConfiguredModelAppearsInModelsList() async throws {
        mockOnDeviceASRCorrectionReadinessRequestStore.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "http://127.0.0.1:42100/v1/models")
            return (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                #"{"data":[{"id":"Qwen3.5-2B-OptiQ-4bit"},{"id":"other-model"}]}"#.data(using: .utf8)!
            )
        }

        let result = await OnDeviceASRCorrectionServerReadinessChecker.check(
            configuration: makeOnDeviceConfiguration(),
            session: makeReadinessSession()
        )

        XCTAssertEqual(result.status, .ready)
        XCTAssertNil(result.detail)
    }

    func testReadinessCheckerReturnsModelUnavailableWhenConfiguredModelIsMissing() async throws {
        mockOnDeviceASRCorrectionReadinessRequestStore.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                #"{"data":[{"id":"some-other-model"},{"id":"fallback-model"}]}"#.data(using: .utf8)!
            )
        }

        let result = await OnDeviceASRCorrectionServerReadinessChecker.check(
            configuration: makeOnDeviceConfiguration(),
            session: makeReadinessSession()
        )

        XCTAssertEqual(result.status, .failed(.modelUnavailable))
        XCTAssertTrue(result.detail?.contains("Qwen3.5-2B-OptiQ-4bit") == true)
        XCTAssertTrue(result.detail?.contains("some-other-model") == true)
    }

    private func makeOnDeviceConfiguration() -> ASRCorrectionConfiguration {
        ASRCorrectionConfiguration(
            provider: .onDevice,
            enabled: true,
            baseURL: OnDeviceASRCorrectionDefaults.baseURL,
            apiKey: "",
            model: OnDeviceASRCorrectionDefaults.modelIdentifier
        )
    }

    private func makeReadinessSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockOnDeviceASRCorrectionReadinessURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class ProcessSpy: OnDeviceASRCorrectionServerProcessControlling {
    var isRunning = false
    var terminateCallCount = 0

    func terminate() {
        terminateCallCount += 1
        isRunning = false
    }
}

private final class MockOnDeviceASRCorrectionReadinessURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = mockOnDeviceASRCorrectionReadinessRequestStore.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private let mockOnDeviceASRCorrectionReadinessRequestStore = MockOnDeviceASRCorrectionReadinessRequestStore()

private final class MockOnDeviceASRCorrectionReadinessRequestStore: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return handler
        }
        set {
            lock.lock()
            handler = newValue
            lock.unlock()
        }
    }
}
