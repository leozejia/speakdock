import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class OnDeviceASRCorrectionServerSupervisorTests: XCTestCase {
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

    private func makeOnDeviceConfiguration() -> ASRCorrectionConfiguration {
        ASRCorrectionConfiguration(
            provider: .onDevice,
            enabled: true,
            baseURL: OnDeviceASRCorrectionDefaults.baseURL,
            apiKey: "",
            model: OnDeviceASRCorrectionDefaults.modelIdentifier
        )
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
