import Foundation
import SpeakDockCore

struct SpeakDockLaunchOptions: Equatable {
    enum Mode: Equatable {
        case normal
        case composeProbe
        case smokeHotPath
        case smokeASRCorrection
        case smokeRefine
        case smokeTermLearning
    }

    enum SmokeRefinePhase: Equatable {
        case submit
        case manual
        case dirtyUndo
    }

    enum SmokeRefineTarget: Equatable {
        case compose
        case capture
    }

    enum SmokeHotPathPhase: Equatable {
        case commit
        case undoRecentSubmission
        case switchTargetUndoRecentSubmission
        case continueAfterObservedEdit
        case captureContinueAfterObservedEdit
        case captureUndoRecentSubmission
    }

    static let defaultComposeProbeDuration: TimeInterval = 30
    static let minimumComposeProbeDuration: TimeInterval = 5
    static let maximumComposeProbeDuration: TimeInterval = 300
    static let defaultSmokeDelay: TimeInterval = 1.5
    static let minimumSmokeDelay: TimeInterval = 0.5
    static let maximumSmokeDelay: TimeInterval = 8
    static let defaultSmokeSubmitDelay: TimeInterval = 1.5
    static let minimumSmokeSubmitDelay: TimeInterval = 0.5
    static let maximumSmokeSubmitDelay: TimeInterval = 8
    static let defaultSmokeText = "SpeakDock smoke"

    let mode: Mode
    let composeProbeDuration: TimeInterval
    let smokeText: String
    let smokeSecondText: String
    let smokeDelay: TimeInterval
    let smokeSubmitDelay: TimeInterval
    let smokeHotPathPhase: SmokeHotPathPhase
    let smokeRefinePhase: SmokeRefinePhase
    let smokeRefineTarget: SmokeRefineTarget
    let smokeRefineBaseURL: String
    let smokeRefineAPIKey: String
    let smokeRefineModel: String
    let asrCorrectionBaseURL: String
    let asrCorrectionAPIKey: String
    let asrCorrectionModel: String
    let onDeviceASRCorrectionExecutableOverridePath: String
    let smokeTermDictionaryStoragePath: String
    let smokeCaptureRootPath: String
    private let requestedASRCorrectionProvider: ASRCorrectionProvider?

    init(arguments: [String] = CommandLine.arguments) {
        if arguments.contains("--probe-compose") {
            mode = .composeProbe
        } else if arguments.contains("--smoke-asr-correction") {
            mode = .smokeASRCorrection
        } else if arguments.contains("--smoke-term-learning") {
            mode = .smokeTermLearning
        } else if arguments.contains("--smoke-refine") {
            mode = .smokeRefine
        } else if arguments.contains("--smoke-hot-path") {
            mode = .smokeHotPath
        } else {
            mode = .normal
        }

        let requestedDuration = Self.durationValue(
            after: "--probe-compose-duration",
            in: arguments
        ) ?? Self.defaultComposeProbeDuration
        composeProbeDuration = min(
            max(requestedDuration, Self.minimumComposeProbeDuration),
            Self.maximumComposeProbeDuration
        )

        let requestedSmokeDelay = Self.durationValue(
            after: "--smoke-delay",
            in: arguments
        ) ?? Self.defaultSmokeDelay
        smokeDelay = min(
            max(requestedSmokeDelay, Self.minimumSmokeDelay),
            Self.maximumSmokeDelay
        )
        let requestedSmokeSubmitDelay = Self.durationValue(
            after: "--smoke-submit-delay",
            in: arguments
        ) ?? Self.defaultSmokeSubmitDelay
        smokeSubmitDelay = min(
            max(requestedSmokeSubmitDelay, Self.minimumSmokeSubmitDelay),
            Self.maximumSmokeSubmitDelay
        )
        smokeText = Self.stringValue(
            after: "--smoke-text",
            in: arguments
        ) ?? Self.defaultSmokeText
        smokeSecondText = Self.stringValue(
            after: "--smoke-text-2",
            in: arguments
        ) ?? ""
        smokeHotPathPhase = Self.smokeHotPathPhaseValue(in: arguments)
        smokeRefinePhase = Self.smokeRefinePhaseValue(in: arguments)
        smokeRefineTarget = Self.smokeRefineTargetValue(in: arguments)
        smokeRefineBaseURL = Self.stringValue(
            after: "--smoke-refine-base-url",
            in: arguments
        ) ?? ""
        smokeRefineAPIKey = Self.stringValue(
            after: "--smoke-refine-api-key",
            in: arguments
        ) ?? ""
        smokeRefineModel = Self.stringValue(
            after: "--smoke-refine-model",
            in: arguments
        ) ?? ""
        asrCorrectionBaseURL = Self.stringValue(
            after: "--asr-correction-base-url",
            in: arguments
        ) ?? ""
        asrCorrectionAPIKey = Self.stringValue(
            after: "--asr-correction-api-key",
            in: arguments
        ) ?? ""
        asrCorrectionModel = Self.stringValue(
            after: "--asr-correction-model",
            in: arguments
        ) ?? ""
        onDeviceASRCorrectionExecutableOverridePath = Self.stringValue(
            after: "--on-device-asr-correction-executable",
            in: arguments
        ) ?? ""
        requestedASRCorrectionProvider = Self.asrCorrectionProviderValue(in: arguments)
            ?? Self.inferredASRCorrectionProvider(
                baseURL: asrCorrectionBaseURL,
                apiKey: asrCorrectionAPIKey,
                model: asrCorrectionModel
            )
        smokeTermDictionaryStoragePath = Self.stringValue(
            after: "--smoke-term-dictionary-storage",
            in: arguments
        ) ?? ""
        smokeCaptureRootPath = Self.stringValue(
            after: "--smoke-capture-root",
            in: arguments
        ) ?? ""
    }

    var runtimeASRCorrectionConfigurationOverride: ASRCorrectionConfiguration? {
        switch requestedASRCorrectionProvider {
        case nil:
            return nil
        case .disabled:
            return .disabled
        case .onDevice:
            return ASRCorrectionConfiguration(
                provider: .onDevice,
                enabled: true,
                baseURL: Self.nonEmptyString(asrCorrectionBaseURL) ?? OnDeviceASRCorrectionDefaults.baseURL,
                apiKey: "",
                model: Self.nonEmptyString(asrCorrectionModel) ?? OnDeviceASRCorrectionDefaults.modelIdentifier
            )
        case .customEndpoint:
            let configuration = ASRCorrectionConfiguration(
                provider: .customEndpoint,
                enabled: true,
                baseURL: asrCorrectionBaseURL,
                apiKey: asrCorrectionAPIKey,
                model: asrCorrectionModel
            )

            guard configuration.executionMode == .modelCorrection else {
                return nil
            }

            return configuration
        }
    }

    private static func durationValue(after flag: String, in arguments: [String]) -> TimeInterval? {
        guard let flagIndex = arguments.firstIndex(of: flag) else {
            return nil
        }

        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex else {
            return nil
        }

        return TimeInterval(arguments[valueIndex])
    }

    private static func stringValue(after flag: String, in arguments: [String]) -> String? {
        guard let flagIndex = arguments.firstIndex(of: flag) else {
            return nil
        }

        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex else {
            return nil
        }

        return arguments[valueIndex]
    }

    private static func asrCorrectionProviderValue(in arguments: [String]) -> ASRCorrectionProvider? {
        switch stringValue(after: "--asr-correction-provider", in: arguments) {
        case "disabled":
            .disabled
        case "on-device", "onDevice":
            .onDevice
        case "custom", "custom-endpoint", "customEndpoint":
            .customEndpoint
        default:
            nil
        }
    }

    private static func inferredASRCorrectionProvider(
        baseURL: String,
        apiKey: String,
        model: String
    ) -> ASRCorrectionProvider? {
        if !baseURL.isEmpty || !apiKey.isEmpty || !model.isEmpty {
            return .customEndpoint
        }

        return nil
    }

    private static func nonEmptyString(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func smokeRefinePhaseValue(in arguments: [String]) -> SmokeRefinePhase {
        switch stringValue(after: "--smoke-refine-phase", in: arguments) {
        case "manual":
            .manual
        case "dirty-undo":
            .dirtyUndo
        default:
            .submit
        }
    }

    private static func smokeRefineTargetValue(in arguments: [String]) -> SmokeRefineTarget {
        switch stringValue(after: "--smoke-refine-target", in: arguments) {
        case "capture":
            .capture
        default:
            .compose
        }
    }

    private static func smokeHotPathPhaseValue(in arguments: [String]) -> SmokeHotPathPhase {
        switch stringValue(after: "--smoke-hot-path-phase", in: arguments) {
        case "undo-recent-submission":
            .undoRecentSubmission
        case "switch-target-undo-recent-submission":
            .switchTargetUndoRecentSubmission
        case "continue-after-observed-edit":
            .continueAfterObservedEdit
        case "capture-continue-after-observed-edit":
            .captureContinueAfterObservedEdit
        case "capture-undo-recent-submission":
            .captureUndoRecentSubmission
        default:
            .commit
        }
    }
}
