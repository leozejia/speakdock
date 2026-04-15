import AppKit
import SpeakDockCore
import SwiftUI

struct MenuBarRoot: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var triggerController: TriggerController
    @Bindable var hotPathCoordinator: HotPathCoordinator

    var body: some View {
        let appLanguage = settingsStore.settings.appLanguage

        VStack(alignment: .leading, spacing: 16) {
            header

            SpeakDockPanel(
                title: localized(.menuQuickControlsTitle),
                subtitle: localized(.menuQuickControlsSubtitle)
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledContent(localized(.settingsInputLanguageLabel)) {
                        Picker(localized(.settingsInputLanguageLabel), selection: $settingsStore.settings.inputLanguage) {
                            ForEach(InputLanguageOption.allCases, id: \.rawValue) { option in
                                Text(option.displayName(appLanguage: appLanguage)).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 128)
                    }

                    Divider()

                    Toggle(isOn: $settingsStore.settings.refineEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localized(.menuRefineTitle))
                                .font(.system(size: 12.5, weight: .medium))
                            Text(localized(.menuRefineSubtitle))
                                .font(.system(size: 11.5))
                                .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                        }
                    }
                    .toggleStyle(.switch)
                }
            }

            SpeakDockPanel(
                title: localized(.menuActionsTitle),
                subtitle: triggerIsUnavailable
                    ? localized(.menuActionsUnavailableSubtitle)
                    : localized(.menuActionsReadySubtitle)
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Button(hotPathCoordinator.secondaryActionTitle) {
                            hotPathCoordinator.performSecondaryAction()
                        }
                        .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))
                        .disabled(!hotPathCoordinator.secondaryActionEnabled)

                        SettingsLink {
                            Text(localized(.menuSettings))
                        }
                        .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))
                    }

                    if triggerIsUnavailable {
                        SettingsLink {
                            Text(localized(.menuConfigureTrigger))
                        }
                        .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))
                    }
                }
            }

            HStack {
                Text(localized(.menuVoiceInputForMac))
                    .font(.system(size: 11.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)

                Spacer()

                Button(localized(.menuQuit)) {
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

                Text(localized(.menuHeaderTagline))
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

    private func localized(_ key: AppLocalizedStringKey) -> String {
        AppLocalizer.string(key, appLanguage: settingsStore.settings.appLanguage)
    }
}
