import AppKit
import SpeakDockCore
import SwiftUI

struct SettingsView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var termDictionaryStore: TermDictionaryStore
    @State private var captureRootMessage: String?
    @State private var refineTestMessage: String?
    @State private var refineTestMessageTone: SpeakDockBadgeTone = .neutral
    @State private var saveMessage: String?
    @State private var saveMessageTone: SpeakDockBadgeTone = .neutral
    @State private var termCanonicalTerm = ""
    @State private var termAliasesText = ""
    @State private var termDictionaryMessage: String?
    @State private var termDictionaryMessageTone: SpeakDockBadgeTone = .neutral
    @State private var isTestingRefine = false

    private let refineTester: any RefineConnectionTesting

    init(
        settingsStore: SettingsStore,
        termDictionaryStore: TermDictionaryStore,
        refineTester: any RefineConnectionTesting = RefineConnectionTester()
    ) {
        self.settingsStore = settingsStore
        self.termDictionaryStore = termDictionaryStore
        self.refineTester = refineTester
    }

    var body: some View {
        let appLanguage = settingsStore.settings.appLanguage

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                SpeakDockPanel(
                    title: localized(.settingsInputTitle),
                    subtitle: localized(.settingsInputSubtitle)
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        LabeledContent(localized(.settingsAppLanguageLabel)) {
                            Picker(localized(.settingsAppLanguageLabel), selection: $settingsStore.settings.appLanguage) {
                                ForEach(AppLanguageOption.allCases, id: \.rawValue) { option in
                                    Text(option.displayName(appLanguage: appLanguage)).tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 170)
                        }

                        LabeledContent(localized(.settingsInputLanguageLabel)) {
                            Picker(localized(.settingsInputLanguageLabel), selection: $settingsStore.settings.inputLanguage) {
                                ForEach(InputLanguageOption.allCases, id: \.rawValue) { option in
                                    Text(option.displayName(appLanguage: appLanguage)).tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 150)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(localized(.settingsTriggerLabel))
                                    .font(.system(size: 13, weight: .medium))

                                Spacer()

                                Picker(localized(.settingsTriggerLabel), selection: triggerModeBinding) {
                                    Text(localized(.settingsTriggerFn)).tag("fn")
                                    Text(localized(.settingsTriggerAlternative)).tag("alternative")
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 220)
                            }

                            if isAlternativeTriggerSelected {
                                LabeledContent(localized(.settingsAlternativeKeyLabel)) {
                                    Picker(localized(.settingsAlternativeKeyLabel), selection: alternativeTriggerBinding) {
                                        ForEach(alternativeTriggerOptions, id: \.rawValue) { option in
                                            Text(option.displayName(appLanguage: appLanguage)).tag(option.rawValue)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(width: 170)
                                }
                            }

                            Text(localized(.settingsFnWarning))
                                .font(.system(size: 11.5))
                                .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()

                        Toggle(isOn: $settingsStore.settings.showDockIcon) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localized(.settingsShowDockIconTitle))
                                    .font(.system(size: 13, weight: .medium))
                                Text(localized(.settingsShowDockIconSubtitle))
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }

                SpeakDockPanel(
                    title: localized(.settingsCaptureTitle),
                    subtitle: localized(.settingsCaptureSubtitle)
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localized(.settingsCaptureRootLabel))
                            .font(.system(size: 13, weight: .medium))

                        HStack(spacing: 12) {
                            Text(settingsStore.settings.captureRootPath)
                                .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.primary.opacity(0.82))
                                .lineLimit(2)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(SpeakDockVisualStyle.panelInset)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(SpeakDockVisualStyle.line, lineWidth: 1)
                                )

                            Button(localized(.settingsChooseAndMigrate)) {
                                chooseCaptureRoot()
                            }
                            .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))
                        }

                        if let captureRootMessage {
                            messageView(captureRootMessage, tone: .neutral)
                        }
                    }
                }

                SpeakDockPanel(
                    title: localized(.settingsTermDictionaryTitle),
                    subtitle: localized(.settingsTermDictionarySubtitle)
                ) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localized(.settingsTermDictionaryAddEntry))
                                .font(.system(size: 13, weight: .medium))

                            TextField(localized(.settingsTermDictionaryCanonicalPlaceholder), text: $termCanonicalTerm)
                                .textFieldStyle(.roundedBorder)

                            TextField(localized(.settingsTermDictionaryAliasesPlaceholder), text: $termAliasesText)
                                .textFieldStyle(.roundedBorder)

                            HStack(alignment: .center, spacing: 12) {
                                Button(localized(.settingsTermDictionaryAddButton)) {
                                    addTermEntry()
                                }
                                .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))
                                .disabled(!canAddTermEntry)

                                Text(localized(.settingsTermDictionarySavedLocalOnly))
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                            }
                        }

                        if let termDictionaryMessage {
                            messageView(termDictionaryMessage, tone: termDictionaryMessageTone)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(localized(.settingsTermDictionaryConfirmedTerms))
                                    .font(.system(size: 13, weight: .medium))

                                Spacer()

                                SpeakDockStatusBadge(
                                    title: localizedFormat(
                                        .settingsTermDictionarySavedCount,
                                        termDictionaryStore.confirmedDictionary.entries.count
                                    ),
                                    tone: termDictionaryStore.confirmedDictionary.entries.isEmpty ? .neutral : .success
                                )
                            }

                            if termDictionaryStore.confirmedDictionary.entries.isEmpty {
                                emptyStateView(localized(.settingsTermDictionaryNoConfirmed))
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(
                                        Array(termDictionaryStore.confirmedDictionary.entries.enumerated()),
                                        id: \.offset
                                    ) { _, entry in
                                        confirmedEntryRow(entry)
                                    }
                                }
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(localized(.settingsTermDictionaryPendingCandidates))
                                    .font(.system(size: 13, weight: .medium))

                                Spacer()

                                SpeakDockStatusBadge(
                                    title: localizedFormat(
                                        .settingsTermDictionaryPendingCount,
                                        termDictionaryStore.pendingCandidates.count
                                    ),
                                    tone: termDictionaryStore.pendingCandidates.isEmpty ? .neutral : .warning
                                )
                            }

                            if termDictionaryStore.pendingCandidates.isEmpty {
                                emptyStateView(
                                    localized(.settingsTermDictionaryNoPending)
                                )
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(
                                        Array(termDictionaryStore.pendingCandidates.enumerated()),
                                        id: \.offset
                                    ) { _, candidate in
                                        pendingCandidateRow(candidate)
                                    }
                                }
                            }
                        }
                    }
                }

                SpeakDockPanel(
                    title: localized(.settingsRefineTitle),
                    subtitle: localized(.settingsRefineSubtitle)
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $settingsStore.settings.refineEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localized(.settingsEnableRefineTitle))
                                    .font(.system(size: 13, weight: .medium))
                                Text(localized(.settingsEnableRefineSubtitle))
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                            }
                        }
                        .toggleStyle(.switch)

                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent(localized(.settingsBaseURLLabel)) {
                                TextField("https://example.com/v1", text: $settingsStore.settings.refineBaseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 280)
                            }

                            LabeledContent(localized(.settingsAPIKeyLabel)) {
                                SecureField("sk-...", text: $settingsStore.settings.refineAPIKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 280)
                            }

                            LabeledContent(localized(.settingsModelLabel)) {
                                TextField("gpt-5.4", text: $settingsStore.settings.refineModel)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                            }
                        }
                        .disabled(!settingsStore.settings.refineEnabled)
                    }
                }

                SpeakDockPanel(
                    title: localized(.settingsActionsTitle),
                    subtitle: localized(.settingsActionsSubtitle)
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            Button(isTestingRefine ? localized(.settingsTestingConnection) : localized(.settingsTestConnection)) {
                                runRefineConnectionTest()
                            }
                            .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))
                            .disabled(isTestingRefine)

                            Button(localized(.settingsSave)) {
                                saveSettings()
                            }
                            .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))
                        }

                        if let refineTestMessage {
                            messageView(
                                refineTestMessage,
                                tone: refineTestMessageTone
                            )
                        }

                        if let saveMessage {
                            messageView(
                                saveMessage,
                                tone: saveMessageTone
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(settingsBackground.ignoresSafeArea())
        .frame(minWidth: 720, minHeight: 760)
    }

    private var header: some View {
        return HStack(alignment: .center, spacing: 16) {
            SpeakDockBrandGlyph(size: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text("SpeakDock")
                    .font(.system(size: 24, weight: .semibold))
                    .tracking(-0.3)

                Text(localized(.settingsHeaderTagline))
                    .font(.system(size: 12.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SpeakDockStatusBadge(
                    title: settingsStore.settings.refineEnabled
                        ? localized(.settingsRefineOn)
                        : localized(.settingsRefineOff),
                    tone: settingsStore.settings.refineEnabled ? .accent : .neutral
                )
                SpeakDockStatusBadge(
                    title: settingsStore.settings.showDockIcon
                        ? localized(.settingsDockOn)
                        : localized(.settingsDockOff),
                    tone: settingsStore.settings.showDockIcon ? .success : .neutral
                )
            }
        }
        .padding(4)
    }

    private var settingsBackground: some View {
        LinearGradient(
            colors: [
                SpeakDockVisualStyle.canvas,
                SpeakDockVisualStyle.panelInset.opacity(0.9),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var isAlternativeTriggerSelected: Bool {
        if case .alternative = settingsStore.settings.triggerSelection {
            return true
        }
        return false
    }

    private var alternativeTriggerOptions: [ModifierTriggerKey] {
        ModifierTriggerKey.allCases.filter { $0 != .fn }
    }

    private var canAddTermEntry: Bool {
        let canonical = termCanonicalTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        return !canonical.isEmpty && !parsedAliases(from: termAliasesText).isEmpty
    }

    private var triggerModeBinding: Binding<String> {
        Binding(
            get: {
                switch settingsStore.settings.triggerSelection {
                case .fn:
                    "fn"
                case .alternative:
                    "alternative"
                }
            },
            set: { newValue in
                if newValue == "fn" {
                    settingsStore.settings.triggerSelection = .fn
                } else {
                    settingsStore.settings.triggerSelection = .alternative(alternativeTriggerBinding.wrappedValue)
                }
            }
        )
    }

    private var alternativeTriggerBinding: Binding<String> {
        Binding(
            get: {
                switch settingsStore.settings.triggerSelection {
                case let .alternative(identifier) where ModifierTriggerKey(rawValue: identifier) != nil:
                    identifier
                case .alternative, .fn:
                    ModifierTriggerKey.rightOption.rawValue
                }
            },
            set: { newValue in
                settingsStore.settings.triggerSelection = .alternative(newValue)
            }
        )
    }

    private func chooseCaptureRoot() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = localized(.settingsOpenPanelMigrate)
        panel.message = localized(.settingsOpenPanelMessage)
        panel.directoryURL = URL(
            fileURLWithPath: settingsStore.settings.captureRootPath,
            isDirectory: true
        )

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try settingsStore.updateCaptureRoot(to: url)
            captureRootMessage = localized(.settingsCaptureRootMigrated)
        } catch {
            captureRootMessage = userFacingMessage(for: error)
        }
    }

    private func addTermEntry() {
        do {
            try termDictionaryStore.addEntry(
                canonicalTerm: termCanonicalTerm,
                aliases: parsedAliases(from: termAliasesText)
            )
            termCanonicalTerm = ""
            termAliasesText = ""
            setTermDictionaryMessage(localized(.settingsTermEntrySaved), tone: .success)
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func removeTermEntry(_ entry: TermDictionaryEntry) {
        do {
            try termDictionaryStore.removeEntry(canonicalTerm: entry.canonicalTerm)
            setTermDictionaryMessage(
                localizedFormat(.settingsTermEntryRemoved, entry.canonicalTerm),
                tone: .success
            )
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func confirmTermCandidate(_ candidate: TermDictionaryCandidate) {
        do {
            try termDictionaryStore.confirm(candidate)
            setTermDictionaryMessage(localized(.settingsTermCandidatePromoted), tone: .success)
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func dismissTermCandidate(_ candidate: TermDictionaryCandidate) {
        do {
            try termDictionaryStore.dismiss(candidate)
            setTermDictionaryMessage(localized(.settingsTermCandidateDismissed), tone: .neutral)
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func runRefineConnectionTest() {
        isTestingRefine = true
        refineTestMessage = localized(.settingsTestingConnection)
        refineTestMessageTone = .neutral

        let configuration = RefineConfiguration(
            enabled: true,
            baseURL: settingsStore.settings.refineBaseURL,
            apiKey: settingsStore.settings.refineAPIKey,
            model: settingsStore.settings.refineModel
        )

        Task {
            do {
                let response = try await refineTester.test(configuration: configuration)
                await MainActor.run {
                    refineTestMessage = localizedFormat(.settingsTestPassed, response)
                    refineTestMessageTone = .success
                    isTestingRefine = false
                }
            } catch {
                await MainActor.run {
                    refineTestMessage = userFacingMessage(for: error)
                    refineTestMessageTone = .critical
                    isTestingRefine = false
                }
            }
        }
    }

    private func saveSettings() {
        do {
            try settingsStore.save()
            saveMessage = localized(.settingsSaved)
            saveMessageTone = .success
        } catch {
            saveMessage = userFacingMessage(for: error)
            saveMessageTone = .critical
        }
    }

    private func userFacingMessage(for error: Error) -> String {
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? String(describing: error) : description
    }

    private func parsedAliases(from text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ",，\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func setTermDictionaryMessage(_ message: String, tone: SpeakDockBadgeTone) {
        termDictionaryMessage = message
        termDictionaryMessageTone = tone
    }

    private func localized(_ key: AppLocalizedStringKey) -> String {
        AppLocalizer.string(key, appLanguage: settingsStore.settings.appLanguage)
    }

    private func localizedFormat(_ key: AppLocalizedStringKey, _ arguments: CVarArg...) -> String {
        AppLocalizer.formatted(
            key,
            appLanguage: settingsStore.settings.appLanguage,
            arguments
        )
    }

    @ViewBuilder
    private func confirmedEntryRow(_ entry: TermDictionaryEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.canonicalTerm)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.9))

                Text(entry.aliases.joined(separator: ", "))
                    .font(.system(size: 11.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button(localized(.settingsRemove)) {
                removeTermEntry(entry)
            }
            .buttonStyle(SpeakDockActionButtonStyle(kind: .subtle))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SpeakDockVisualStyle.panelInset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SpeakDockVisualStyle.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func pendingCandidateRow(_ candidate: TermDictionaryCandidate) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(candidate.canonicalTerm)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.9))

                Text("\(localized(.settingsAliasLabel)): \(candidate.alias)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .textSelection(.enabled)

                Text("\(localized(.settingsSourceLabel)): \(candidateSourceLabel(candidate.source))")
                    .font(.system(size: 11))
                    .foregroundStyle(SpeakDockVisualStyle.tertiaryText)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Button(localized(.settingsConfirm)) {
                    confirmTermCandidate(candidate)
                }
                .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))

                Button(localized(.settingsDismiss)) {
                    dismissTermCandidate(candidate)
                }
                .buttonStyle(SpeakDockActionButtonStyle(kind: .subtle))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SpeakDockVisualStyle.panelInset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SpeakDockVisualStyle.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func emptyStateView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 11.5))
            .foregroundStyle(SpeakDockVisualStyle.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SpeakDockVisualStyle.panelInset)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SpeakDockVisualStyle.line, lineWidth: 1)
            )
    }

    private func candidateSourceLabel(_ source: TermDictionaryCandidateSource) -> String {
        switch source {
        case .manualCorrection:
            localized(.settingsManualCorrection)
        }
    }

    @ViewBuilder
    private func messageView(_ message: String, tone: SpeakDockBadgeTone) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(tone.textColor)
                .frame(width: 7, height: 7)

            Text(message)
                .font(.system(size: 11.5))
                .foregroundStyle(Color.primary.opacity(0.8))
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tone.fillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tone.strokeColor, lineWidth: 1)
        )
    }
}
