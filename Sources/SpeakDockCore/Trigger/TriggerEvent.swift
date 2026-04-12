import Foundation

public enum TriggerInputEvent: Equatable, Sendable {
    case press(timestamp: TimeInterval)
    case release(timestamp: TimeInterval)
}

public enum TriggerAction: Equatable, Sendable {
    case recording(startTimestamp: TimeInterval, endTimestamp: TimeInterval)
    case submit
}

public struct TriggerStateMachine: Sendable {
    private enum State: Sendable {
        case idle
        case pressing(startTimestamp: TimeInterval, isSecondTap: Bool)
        case pendingTap(releaseTimestamp: TimeInterval)
    }

    public let quickTapThreshold: TimeInterval
    public let doubleClickWindow: TimeInterval

    private var state: State = .idle

    public init(
        quickTapThreshold: TimeInterval = 0.18,
        doubleClickWindow: TimeInterval = 0.30
    ) {
        self.quickTapThreshold = quickTapThreshold
        self.doubleClickWindow = doubleClickWindow
    }

    public mutating func handle(_ event: TriggerInputEvent) -> [TriggerAction] {
        switch (state, event) {
        case let (.idle, .press(timestamp)):
            state = .pressing(startTimestamp: timestamp, isSecondTap: false)
            return []

        case (.idle, .release):
            return []

        case let (.pressing(startTimestamp, isSecondTap), .release(timestamp)):
            let pressDuration = timestamp - startTimestamp

            if isSecondTap, pressDuration <= quickTapThreshold {
                state = .idle
                return [.submit]
            }

            if pressDuration <= quickTapThreshold {
                state = .pendingTap(releaseTimestamp: timestamp)
                return []
            }

            state = .idle
            return [.recording(startTimestamp: startTimestamp, endTimestamp: timestamp)]

        case (.pressing, .press):
            return []

        case let (.pendingTap(firstReleaseTimestamp), .press(timestamp)):
            if timestamp - firstReleaseTimestamp <= doubleClickWindow {
                state = .pressing(startTimestamp: timestamp, isSecondTap: true)
            } else {
                state = .pressing(startTimestamp: timestamp, isSecondTap: false)
            }
            return []

        case (.pendingTap, .release):
            return []
        }
    }
}
