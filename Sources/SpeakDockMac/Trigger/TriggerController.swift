import Foundation
import Observation
import SpeakDockCore

@MainActor
@Observable
final class TriggerController {
    var availability: TriggerAvailability = .unavailable(label: "Trigger Not Started")
    var isPressed = false
    var lastAction: TriggerAction?

    var onAction: ((TriggerAction) -> Void)?
    var onPressStateChanged: ((Bool) -> Void)?

    private let settingsStore: SettingsStore
    private let adapterFactory: (ModifierTriggerKey) -> any TriggerAdapter
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
        settingsStore.onSettingsChanged = { [weak self] _ in
            guard self?.isStarted == true else {
                return
            }

            self?.reloadConfiguration()
        }
    }

    func start() {
        guard !isStarted else {
            return
        }

        isStarted = true
        reloadConfiguration()
    }

    func reloadConfiguration() {
        adapter?.stop()
        adapter = nil
        isPressed = false
        stateMachine = TriggerStateMachine()

        guard let triggerKey = ModifierTriggerKey(selection: settingsStore.settings.triggerSelection) else {
            availability = .unavailable(label: "Unsupported Trigger")
            return
        }

        let adapter = adapterFactory(triggerKey)
        adapter.onAvailabilityChanged = { [weak self] availability in
            self?.availability = availability
        }
        adapter.onPressStateChanged = { [weak self] isPressed in
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
            lastAction = action
            onAction?(action)
        }
    }
}
