import Foundation
import Observation
import SpeakDockCore

protocol OnDeviceASRCorrectionServerProcessControlling: AnyObject {
    var isRunning: Bool { get }
    func terminate()
}

struct OnDeviceASRCorrectionServerCommand: Equatable {
    let executablePath: String
    let arguments: [String]
}

enum OnDeviceASRCorrectionServerFailure: Equatable {
    case executableUnavailable
    case launchFailed
    case readinessTimedOut
    case readinessUnexpectedStatus(Int)
}

enum OnDeviceASRCorrectionServerStatus: Equatable {
    case inactive
    case starting
    case ready
    case failed(OnDeviceASRCorrectionServerFailure)
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

        if !trimmedOverride.isEmpty {
            executablePath = trimmedOverride
        } else if fileManager.isExecutableFile(atPath: devExecutablePath) {
            executablePath = devExecutablePath
        } else if let pathExecutable = resolveExecutableInPATH(
            named: "mlx_lm.server",
            environment: environment,
            fileManager: fileManager
        ) {
            executablePath = pathExecutable
        } else {
            return nil
        }

        return OnDeviceASRCorrectionServerCommand(
            executablePath: executablePath,
            arguments: [
                "--model", configuration.model,
                "--host", host,
                "--port", String(port),
            ]
        )
    }

    private static func resolveExecutableInPATH(
        named executableName: String,
        environment: [String: String],
        fileManager: FileManager
    ) -> String? {
        guard let pathValue = environment["PATH"] else {
            return nil
        }

        for directory in pathValue.split(separator: ":") {
            let candidatePath = URL(fileURLWithPath: String(directory), isDirectory: true)
                .appendingPathComponent(executableName)
                .path
            if fileManager.isExecutableFile(atPath: candidatePath) {
                return candidatePath
            }
        }

        return nil
    }
}

enum OnDeviceASRCorrectionServerReadinessChecker {
    static func check(
        configuration: ASRCorrectionConfiguration,
        session: URLSession = .shared
    ) async -> OnDeviceASRCorrectionServerStatus {
        guard let readinessURL = URL(string: configuration.baseURL)?
            .appendingPathComponent("models") else {
            return .failed(.readinessTimedOut)
        }

        for _ in 0..<15 {
            if Task.isCancelled {
                return .inactive
            }

            var request = URLRequest(url: readinessURL)
            request.timeoutInterval = 0.35

            do {
                let (_, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        return .ready
                    }
                    return .failed(.readinessUnexpectedStatus(httpResponse.statusCode))
                }
            } catch {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }

        return .failed(.readinessTimedOut)
    }
}

@MainActor
@Observable
final class OnDeviceASRCorrectionServerSupervisor {
    typealias CommandBuilder = (ASRCorrectionConfiguration) -> OnDeviceASRCorrectionServerCommand?
    typealias Launcher = (OnDeviceASRCorrectionServerCommand) throws -> any OnDeviceASRCorrectionServerProcessControlling
    typealias ReadinessChecker = (ASRCorrectionConfiguration) async -> OnDeviceASRCorrectionServerStatus

    private(set) var status: OnDeviceASRCorrectionServerStatus = .inactive
    private(set) var statusDetail: String?
    private let commandBuilder: CommandBuilder
    private let launcher: Launcher
    private let readinessChecker: ReadinessChecker
    private var runningProcess: (any OnDeviceASRCorrectionServerProcessControlling)?
    private var runningCommand: OnDeviceASRCorrectionServerCommand?
    private var readinessTask: Task<Void, Never>?

    init(
        commandBuilder: @escaping CommandBuilder = { configuration in
            OnDeviceASRCorrectionServerCommandBuilder.makeCommand(for: configuration)
        },
        launcher: @escaping Launcher = { command in
            try FoundationOnDeviceASRCorrectionServerProcess.launch(command: command)
        },
        readinessChecker: @escaping ReadinessChecker = { configuration in
            await OnDeviceASRCorrectionServerReadinessChecker.check(configuration: configuration)
        }
    ) {
        self.commandBuilder = commandBuilder
        self.launcher = launcher
        self.readinessChecker = readinessChecker
    }

    func sync(configuration: ASRCorrectionConfiguration) {
        guard configuration.provider == .onDevice,
              configuration.executionMode == .modelCorrection else {
            stop()
            return
        }

        guard let command = commandBuilder(configuration) else {
            stop()
            status = .failed(.executableUnavailable)
            statusDetail = "mlx_lm.server is unavailable"
            SpeakDockLog.speech.error("on-device asr correction server executable unavailable")
            return
        }

        if let runningProcess,
           runningProcess.isRunning,
           runningCommand == command,
           status == .starting || status == .ready {
            return
        }

        if runningProcess != nil {
            stop()
        }

        do {
            let process = try launcher(command)
            runningProcess = process
            runningCommand = command
            status = .starting
            statusDetail = nil
            SpeakDockLog.speech.notice("on-device asr correction server started")
            startReadinessCheck(for: configuration)
        } catch {
            runningProcess = nil
            runningCommand = nil
            readinessTask?.cancel()
            readinessTask = nil
            status = .failed(.launchFailed)
            statusDetail = error.localizedDescription
            SpeakDockLog.speech.error("on-device asr correction server failed to start: \(error.localizedDescription, privacy: .private)")
        }
    }

    func stop() {
        readinessTask?.cancel()
        readinessTask = nil

        guard let runningProcess else {
            status = .inactive
            statusDetail = nil
            return
        }

        if runningProcess.isRunning {
            runningProcess.terminate()
            SpeakDockLog.speech.notice("on-device asr correction server stopped")
        }

        self.runningProcess = nil
        self.runningCommand = nil
        self.status = .inactive
        self.statusDetail = nil
    }

    private func startReadinessCheck(for configuration: ASRCorrectionConfiguration) {
        readinessTask?.cancel()
        readinessTask = Task { [weak self] in
            guard let self else {
                return
            }

            let readinessStatus = await readinessChecker(configuration)

            await MainActor.run {
                guard !Task.isCancelled else {
                    return
                }

                guard self.runningCommand != nil else {
                    return
                }

                switch readinessStatus {
                case .inactive:
                    break
                case .starting:
                    self.status = .starting
                    self.statusDetail = nil
                case .ready:
                    self.status = .ready
                    self.statusDetail = nil
                    SpeakDockLog.speech.notice("on-device asr correction server ready")
                case let .failed(failure):
                    self.status = .failed(failure)
                    self.statusDetail = failure.detail
                    SpeakDockLog.speech.error("on-device asr correction server not ready: \(failure.logDescription, privacy: .public)")
                }

                self.readinessTask = nil
            }
        }
    }
}

private extension OnDeviceASRCorrectionServerFailure {
    var logDescription: String {
        switch self {
        case .executableUnavailable:
            "executable unavailable"
        case .launchFailed:
            "launch failed"
        case .readinessTimedOut:
            "readiness timed out"
        case let .readinessUnexpectedStatus(statusCode):
            "unexpected readiness status \(statusCode)"
        }
    }

    var detail: String {
        switch self {
        case .executableUnavailable:
            "mlx_lm.server is unavailable"
        case .launchFailed:
            "mlx_lm.server failed to launch"
        case .readinessTimedOut:
            "mlx_lm.server did not become ready in time"
        case let .readinessUnexpectedStatus(statusCode):
            "mlx_lm.server responded with status \(statusCode)"
        }
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
