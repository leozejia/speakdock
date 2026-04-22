import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class OnDeviceASRCorrectionServerSupervisorTests: XCTestCase {
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
            }
        )

        supervisor.sync(
            configuration: ASRCorrectionConfiguration(
                provider: .onDevice,
                enabled: true,
                baseURL: OnDeviceASRCorrectionDefaults.baseURL,
                apiKey: "",
                model: OnDeviceASRCorrectionDefaults.modelIdentifier
            )
        )

        let command = try XCTUnwrap(launchedCommand)
        XCTAssertTrue(command.arguments.contains("--host"))
        XCTAssertTrue(command.arguments.contains("127.0.0.1"))
        XCTAssertTrue(command.arguments.contains("--port"))
        XCTAssertTrue(command.arguments.contains("42100"))
        XCTAssertTrue(command.arguments.contains("--model"))
        XCTAssertTrue(command.arguments.contains(OnDeviceASRCorrectionDefaults.modelIdentifier))
    }

    func testSyncStopsRunningServerWhenConfigurationLeavesOnDeviceMode() throws {
        let process = ProcessSpy()
        let supervisor = OnDeviceASRCorrectionServerSupervisor(
            commandBuilder: { configuration in
                OnDeviceASRCorrectionServerCommandBuilder.makeCommand(for: configuration)
            },
            launcher: { _ in
                process.isRunning = true
                return process
            }
        )

        supervisor.sync(
            configuration: ASRCorrectionConfiguration(
                provider: .onDevice,
                enabled: true,
                baseURL: OnDeviceASRCorrectionDefaults.baseURL,
                apiKey: "",
                model: OnDeviceASRCorrectionDefaults.modelIdentifier
            )
        )
        supervisor.sync(configuration: ASRCorrectionConfiguration.disabled)

        XCTAssertEqual(process.terminateCallCount, 1)
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
