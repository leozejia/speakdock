import AppKit
import SwiftUI
import SpeakDockCore

struct MenuBarRoot: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var triggerController: TriggerController
    @Bindable var hotPathCoordinator: HotPathCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SpeakDock")
                .font(.headline)

            Text(triggerStatusTitle)
                .font(.caption)
                .foregroundStyle(triggerStatusColor)

            Picker("Language", selection: $settingsStore.settings.languageCode) {
                ForEach(LanguageOption.allCases, id: \.rawValue) { option in
                    Text(option.displayName).tag(option.rawValue)
                }
            }

            Toggle("Enable Refine", isOn: $settingsStore.settings.refineEnabled)

            Button(hotPathCoordinator.secondaryActionTitle) {
                hotPathCoordinator.performSecondaryAction()
            }
            .disabled(!hotPathCoordinator.secondaryActionEnabled)

            if triggerIsUnavailable {
                SettingsLink {
                    Text("Configure Trigger")
                }
            }

            Divider()

            SettingsLink {
                Text("Open Settings")
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 240)
    }

    private var triggerStatusColor: Color {
        switch triggerController.availability {
        case .available:
            .secondary
        case .unavailable:
            .red
        }
    }

    private var triggerStatusTitle: String {
        switch triggerController.availability {
        case let .available(label), let .unavailable(label):
            label
        }
    }

    private var triggerIsUnavailable: Bool {
        if case .unavailable = triggerController.availability {
            return true
        }
        return false
    }
}
