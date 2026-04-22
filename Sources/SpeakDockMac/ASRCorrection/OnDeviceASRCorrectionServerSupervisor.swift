import Foundation
import SpeakDockCore

protocol OnDeviceASRCorrectionServerProcessControlling: AnyObject {
    var isRunning: Bool { get }
    func terminate()
}

struct OnDeviceASRCorrectionServerCommand: Equatable {
    let executablePath: String
    let arguments: [String]
}

enum OnDeviceASRCorrectionServerCommandBuilder {
    static let executableOverrideEnvironmentKey = "SPEAKDOCK_MLX_LM_SERVER_EXECUTABLE"
    static let devExecutableRelativePath = ".tmp/asr-eval-venv/bin/mlx_lm.server"

    static func makeCommand(
        for configuration: ASRCorrectionConfiguration,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        currentDirectoryPath: String = FileManager.default.currentDirectoryPath,
        fileManager: FileManager = .default
    ) -> OnDeviceASRCorrectionServerCommand? {
        guard configuration.provider == .onDevice,
              configuration.executionMode == .modelCorrection,
              let endpointURL = URL(string: configuration.baseURL),
              let host = endpointURL.host
        else {
            return nil
        }

        let port = endpointURL.port ?? 80
        let trimmedOverride = environment[executableOverrideEnvironmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let devExecutablePath = URL(fileURLWithPath: currentDirectoryPath, isDirectory: true)
            .appendingPathComponent(devExecutableRelativePath)
            .path

        let executablePath: String
        let argumentsPrefix: [String]

        if !trimmedOverride.isEmpty {
            executablePath = trimmedOverride
            argumentsPrefix = []
        } else if fileManager.isExecutableFile(atPath: devExecutablePath) {
            executablePath = devExecutablePath
            argumentsPrefix = []
        } else {
            executablePath = "/usr/bin/env"
            argumentsPrefix = ["mlx_lm.server"]
        }

        return OnDeviceASRCorrectionServerCommand(
            executablePath: executablePath,
            arguments: argumentsPrefix + [
                "--model", configuration.model,
                "--host", host,
                "--port", String(port),
            ]
        )
    }
}

final class OnDeviceASRCorrectionServerSupervisor {
    typealias CommandBuilder = (ASRCorrectionConfiguration) -> OnDeviceASRCorrectionServerCommand?
    typealias Launcher = (OnDeviceASRCorrectionServerCommand) throws -> any OnDeviceASRCorrectionServerProcessControlling

    private let commandBuilder: CommandBuilder
    private let launcher: Launcher
    private var runningProcess: (any OnDeviceASRCorrectionServerProcessControlling)?
    private var runningCommand: OnDeviceASRCorrectionServerCommand?

    init(
        commandBuilder: @escaping CommandBuilder = { configuration in
            OnDeviceASRCorrectionServerCommandBuilder.makeCommand(for: configuration)
        },
        launcher: @escaping Launcher = { command in
            try FoundationOnDeviceASRCorrectionServerProcess.launch(command: command)
        }
    ) {
        self.commandBuilder = commandBuilder
        self.launcher = launcher
    }

    func sync(configuration: ASRCorrectionConfiguration) {
        guard let command = commandBuilder(configuration) else {
            stop()
            return
        }

        if let runningProcess,
           runningProcess.isRunning,
           runningCommand == command {
            return
        }

        if runningProcess != nil {
            stop()
        }

        do {
            let process = try launcher(command)
            runningProcess = process
            runningCommand = command
            SpeakDockLog.speech.notice("on-device asr correction server started")
        } catch {
            runningProcess = nil
            runningCommand = nil
            SpeakDockLog.speech.error("on-device asr correction server failed to start: \(error.localizedDescription, privacy: .private)")
        }
    }

    func stop() {
        guard let runningProcess else {
            return
        }

        if runningProcess.isRunning {
            runningProcess.terminate()
            SpeakDockLog.speech.notice("on-device asr correction server stopped")
        }

        self.runningProcess = nil
        self.runningCommand = nil
    }
}

private final class FoundationOnDeviceASRCorrectionServerProcess: OnDeviceASRCorrectionServerProcessControlling {
    private let process: Process

    init(process: Process) {
        self.process = process
    }

    var isRunning: Bool {
        process.isRunning
    }

    func terminate() {
        process.terminate()
    }

    static func launch(command: OnDeviceASRCorrectionServerCommand) throws -> FoundationOnDeviceASRCorrectionServerProcess {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executablePath)
        process.arguments = command.arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        return FoundationOnDeviceASRCorrectionServerProcess(process: process)
    }
}
