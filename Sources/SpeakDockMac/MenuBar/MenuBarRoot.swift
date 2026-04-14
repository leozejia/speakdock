import AppKit
import SpeakDockCore
import SwiftUI

struct MenuBarRoot: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var triggerController: TriggerController
    @Bindable var hotPathCoordinator: HotPathCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            SpeakDockPanel(
                title: "Quick Controls",
                subtitle: "Keep the hot path simple and ready."
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledContent("Language") {
                        Picker("Language", selection: $settingsStore.settings.languageCode) {
                            ForEach(LanguageOption.allCases, id: \.rawValue) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 128)
                    }

                    Divider()

                    Toggle(isOn: $settingsStore.settings.refineEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Refine")
                                .font(.system(size: 12.5, weight: .medium))
                            Text("Optional cleanup after transcription.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                        }
                    }
                    .toggleStyle(.switch)
                }
            }

            SpeakDockPanel(
                title: "Actions",
                subtitle: triggerIsUnavailable
                    ? "Fn is unavailable. Switch trigger in Settings."
                    : "Open settings or run the secondary action."
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Button(hotPathCoordinator.secondaryActionTitle) {
                            hotPathCoordinator.performSecondaryAction()
                        }
                        .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))
                        .disabled(!hotPathCoordinator.secondaryActionEnabled)

                        SettingsLink {
                            Text("Settings")
                        }
                        .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))
                    }

                    if triggerIsUnavailable {
                        SettingsLink {
                            Text("Configure Trigger")
                        }
                        .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))
                    }
                }
            }

            HStack {
                Text("Voice input for Mac")
                    .font(.system(size: 11.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(SpeakDockActionButtonStyle(kind: .subtle))
                .keyboardShortcut("q")
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(
            LinearGradient(
                colors: [
                    SpeakDockVisualStyle.canvas,
                    SpeakDockVisualStyle.panelInset.opacity(0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            SpeakDockBrandGlyph(size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text("SpeakDock")
                    .font(.system(size: 16, weight: .semibold))

                Text("AI voice input, tuned for the Mac.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
            }

            Spacer(minLength: 8)

            SpeakDockStatusBadge(
                title: triggerStatusTitle,
                tone: triggerStatusTone
            )
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

    private var triggerStatusTone: SpeakDockBadgeTone {
        switch triggerController.availability {
        case .available:
            .success
        case .unavailable:
            .critical
        }
    }
}
