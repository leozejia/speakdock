import Foundation

struct SpeakDockLaunchOptions: Equatable {
    enum Mode: Equatable {
        case normal
        case composeProbe
        case smokeHotPath
        case smokeRefine
    }

    static let defaultComposeProbeDuration: TimeInterval = 30
    static let minimumComposeProbeDuration: TimeInterval = 5
    static let maximumComposeProbeDuration: TimeInterval = 300
    static let defaultSmokeDelay: TimeInterval = 1.5
    static let minimumSmokeDelay: TimeInterval = 0.5
    static let maximumSmokeDelay: TimeInterval = 8
    static let defaultSmokeText = "SpeakDock smoke"

    let mode: Mode
    let composeProbeDuration: TimeInterval
    let smokeText: String
    let smokeDelay: TimeInterval
    let smokeRefineBaseURL: String
    let smokeRefineAPIKey: String
    let smokeRefineModel: String

    init(arguments: [String] = CommandLine.arguments) {
        if arguments.contains("--probe-compose") {
            mode = .composeProbe
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
        smokeText = Self.stringValue(
            after: "--smoke-text",
            in: arguments
        ) ?? Self.defaultSmokeText
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
}
