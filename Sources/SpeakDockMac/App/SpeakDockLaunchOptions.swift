import Foundation

struct SpeakDockLaunchOptions: Equatable {
    enum Mode: Equatable {
        case normal
        case composeProbe
    }

    static let defaultComposeProbeDuration: TimeInterval = 30
    static let minimumComposeProbeDuration: TimeInterval = 5
    static let maximumComposeProbeDuration: TimeInterval = 300

    let mode: Mode
    let composeProbeDuration: TimeInterval

    init(arguments: [String] = CommandLine.arguments) {
        mode = arguments.contains("--probe-compose") ? .composeProbe : .normal

        let requestedDuration = Self.durationValue(
            after: "--probe-compose-duration",
            in: arguments
        ) ?? Self.defaultComposeProbeDuration
        composeProbeDuration = min(
            max(requestedDuration, Self.minimumComposeProbeDuration),
            Self.maximumComposeProbeDuration
        )
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
}
