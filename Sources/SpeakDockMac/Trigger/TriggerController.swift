import Foundation
import Observation
import SpeakDockCore

@MainActor
@Observable
final class TriggerController {
    var availability: TriggerAvailability = .unavailable(label: "Trigger Unavailable")
    var isPressed = false
    var lastAction: TriggerAction?

    var onAction: ((TriggerAction) -> Void)?
    var onPressStateChanged: ((Bool) -> Void)?

    private let settingsStore: SettingsStore
    private var adapter: (any TriggerAdapter)?
    private var stateMachine = TriggerStateMachine()

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        settingsStore.onSettingsChanged = { [weak self] _ in
            self?.reloadConfiguration()
        }
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

        let adapter = FnKeyTriggerAdapter(triggerKey: triggerKey)
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
