import Foundation

struct HotPathInteractionTrace {
    enum Kind: String, Equatable {
        case recording
        case submit
    }

    enum Origin: String, Equatable {
        case live
        case smoke
    }

    enum Route: String, Equatable {
        case compose
        case capture
    }

    enum Result: String, Equatable {
        case composeCommitted
        case captureCommitted
        case composeUnavailable
        case composeTargetLost
        case composeCommitFailed
        case captureCommitFailed
        case emptyTranscript
        case speechTimedOut
        case speechUnavailable
        case microphoneUnavailable
        case submitSucceeded
        case submitFailed
    }

    let id: UUID
    let kind: Kind
    let origin: Origin
    let startedAt: TimeInterval

    private(set) var pressEndedAt: TimeInterval?
    private(set) var recognitionFinalAt: TimeInterval?
    private(set) var commitStartedAt: TimeInterval?
    private(set) var route: Route?

    init(
        id: UUID = UUID(),
        kind: Kind,
        origin: Origin,
        startedAt: TimeInterval
    ) {
        self.id = id
        self.kind = kind
        self.origin = origin
        self.startedAt = startedAt
    }

    mutating func markPressEnded(at time: TimeInterval) {
        pressEndedAt = time
    }

    mutating func markRecognitionFinal(at time: TimeInterval) {
        recognitionFinalAt = time
    }

    mutating func markCommitStarted(route: Route, at time: TimeInterval) {
        self.route = route
        commitStartedAt = time
    }

    func finish(result: Result, at time: TimeInterval) -> HotPathInteractionSummary {
        HotPathInteractionSummary(
            interactionID: id.uuidString,
            kind: kind,
            origin: origin,
            route: route,
            result: result,
            totalDuration: max(0, time - startedAt),
            pressDuration: pressEndedAt.map { max(0, $0 - startedAt) },
            recognitionDuration: {
                guard let pressEndedAt, let recognitionFinalAt else {
                    return nil
                }

                return max(0, recognitionFinalAt - pressEndedAt)
            }(),
            commitDuration: {
                guard let commitStartedAt else {
                    return nil
                }

                return max(0, time - commitStartedAt)
            }()
        )
    }
}

struct HotPathInteractionSummary: Equatable {
    let interactionID: String
    let kind: HotPathInteractionTrace.Kind
    let origin: HotPathInteractionTrace.Origin
    let route: HotPathInteractionTrace.Route?
    let result: HotPathInteractionTrace.Result
    let totalDuration: TimeInterval
    let pressDuration: TimeInterval?
    let recognitionDuration: TimeInterval?
    let commitDuration: TimeInterval?
}

extension HotPathInteractionTrace {
    var startLogMessage: String {
        [
            "trace.start",
            "interaction=\(id.uuidString)",
            "kind=\(kind.rawValue)",
            "origin=\(origin.rawValue)",
        ].joined(separator: " ")
    }

    func stageLogMessage(
        _ stage: String,
        at time: TimeInterval,
        extras: [String] = []
    ) -> String {
        var components = [
            "trace.stage",
            "interaction=\(id.uuidString)",
            "stage=\(stage)",
            "elapsed=\(formatDuration(max(0, time - startedAt)))",
        ]
        components.append(contentsOf: extras)
        return components.joined(separator: " ")
    }
}

extension HotPathInteractionSummary {
    var logMessage: String {
        var components = [
            "trace.finish",
            "interaction=\(interactionID)",
            "kind=\(kind.rawValue)",
            "origin=\(origin.rawValue)",
            "result=\(result.rawValue)",
            "total=\(formatDuration(totalDuration))",
        ]

        if let route {
            components.append("route=\(route.rawValue)")
        }

        if let pressDuration {
            components.append("press=\(formatDuration(pressDuration))")
        }

        if let recognitionDuration {
            components.append("recognition=\(formatDuration(recognitionDuration))")
        }

        if let commitDuration {
            components.append("commit=\(formatDuration(commitDuration))")
        }

        return components.joined(separator: " ")
    }
}

private func formatDuration(_ duration: TimeInterval) -> String {
    String(format: "%.3f", duration)
}
