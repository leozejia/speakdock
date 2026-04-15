import Foundation
import Observation
import OSLog
import SpeakDockCore

@MainActor
@Observable
final class TriggerController {
    var availability: TriggerAvailability = .unavailable(label: AppLocalizer.string(.triggerNotStarted))
    var isPressed = false
    var lastAction: TriggerAction?

    var onAction: ((TriggerAction) -> Void)?
    var onPressStateChanged: ((Bool) -> Void)?

    private let settingsStore: SettingsStore
    private let adapterFactory: (ModifierTriggerKey) -> any TriggerAdapter
    private var settingsObserverID: UUID?
    private var adapter: (any TriggerAdapter)?
    private var stateMachine = TriggerStateMachine()
    private var isStarted = false

    init(
        settingsStore: SettingsStore,
        adapterFactory: @escaping (ModifierTriggerKey) -> any TriggerAdapter = { triggerKey in
            FnKeyTriggerAdapter(triggerKey: triggerKey)
        }
    ) {
        self.settingsStore = settingsStore
        self.adapterFactory = adapterFactory
        self.settingsObserverID = settingsStore.addSettingsObserver { [weak self] _ in
            guard self?.isStarted == true else {
                return
            }

            self?.reloadConfiguration()
        }
    }

    func start() {
        guard !isStarted else {
            SpeakDockLog.trigger.debug("trigger controller start ignored because it is already started")
            return
        }

        SpeakDockLog.trigger.notice("starting trigger controller")
        isStarted = true
        reloadConfiguration()
    }

    func reloadConfiguration() {
        adapter?.stop()
        adapter = nil
        isPressed = false
        stateMachine = TriggerStateMachine()

        guard let triggerKey = ModifierTriggerKey(selection: settingsStore.settings.triggerSelection) else {
            SpeakDockLog.trigger.error("unsupported trigger selection")
            availability = .unavailable(label: AppLocalizer.string(.triggerUnsupported))
            return
        }

        SpeakDockLog.trigger.notice("reloading trigger adapter: \(triggerKey.rawValue, privacy: .public)")
        let adapter = adapterFactory(triggerKey)
        adapter.onAvailabilityChanged = { [weak self] availability in
            SpeakDockLog.trigger.notice("trigger availability changed: \(availability.logLabel, privacy: .public)")
            self?.availability = availability
        }
        adapter.onPressStateChanged = { [weak self] isPressed in
            SpeakDockLog.trigger.debug("trigger press state changed: \(isPressed, privacy: .public)")
            self?.isPressed = isPressed
            self?.onPressStateChanged?(isPressed)
        }
        adapter.onInputEvent = { [weak self] inputEvent in
            self?.handle(inputEvent)
        }
        self.adapter = adapter
        adapter.start()
    }

    private func handle(_ inputEvent: TriggerInputEvent) {
        for action in stateMachine.handle(inputEvent) {
            SpeakDockLog.trigger.notice("trigger action: \(action.logName, privacy: .public)")
            lastAction = action
            onAction?(action)
        }
    }
}

private extension TriggerAvailability {
    var logLabel: String {
        switch self {
        case let .available(label), let .unavailable(label):
            label
        }
    }
}

private extension TriggerAction {
    var logName: String {
        switch self {
        case .recording:
            "recording"
        case .submit:
            "submit"
        }
    }
}
