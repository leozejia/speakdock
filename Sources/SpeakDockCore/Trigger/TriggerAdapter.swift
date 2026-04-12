public enum TriggerAvailability: Equatable, Sendable {
    case available(label: String)
    case unavailable(label: String)
}

@MainActor
public protocol TriggerAdapter: AnyObject {
    var onInputEvent: ((TriggerInputEvent) -> Void)? { get set }
    var onPressStateChanged: ((Bool) -> Void)? { get set }
    var onAvailabilityChanged: ((TriggerAvailability) -> Void)? { get set }

    func start()
    func stop()
}
