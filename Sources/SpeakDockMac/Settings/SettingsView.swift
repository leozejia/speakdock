import AppKit
import SpeakDockCore
import SwiftUI

struct SettingsView: View {
    private enum Layout {
        static let windowWidth: CGFloat = 1040
        static let windowHeight: CGFloat = 780
        static let sidebarWidth: CGFloat = 270
        static let secondaryColumnWidth: CGFloat = 300
        static let outerPadding: CGFloat = 16
        static let detailPadding: CGFloat = 34
        static let paneSpacing: CGFloat = 24
        static let sectionSpacing: CGFloat = 20
    }

    @Bindable var settingsStore: SettingsStore
    @Bindable var termDictionaryStore: TermDictionaryStore
    @State private var captureRootMessage: String?
    @State private var refineTestMessage: String?
    @State private var refineTestMessageTone: SpeakDockBadgeTone = .neutral
    @State private var termCanonicalTerm = ""
    @State private var termAliasesText = ""
    @State private var termDictionaryMessage: String?
    @State private var termDictionaryMessageTone: SpeakDockBadgeTone = .neutral
    @State private var isTestingRefine = false
    @State private var selectedPane: SettingsPane = .defaultPane

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

        HStack(spacing: 0) {
            sidebar(appLanguage: appLanguage)

            Rectangle()
                .fill(SpeakDockVisualStyle.settingsLine)
                .frame(width: 1)

            detailPane(appLanguage: appLanguage)
        }
        .background(settingsBackground.ignoresSafeArea())
        .frame(
            minWidth: Layout.windowWidth,
            idealWidth: Layout.windowWidth,
            maxWidth: Layout.windowWidth,
            minHeight: Layout.windowHeight,
            idealHeight: Layout.windowHeight
        )
    }

    private var settingsBackground: some View {
        LinearGradient(
            colors: [
                SpeakDockVisualStyle.settingsBackdropTop,
                SpeakDockVisualStyle.settingsBackdropBottom,
            ],
            startPoint: .topLeading,
            endPoint: .bottom
        )
    }

    private func sidebar(appLanguage: AppLanguageOption) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            sidebarHeader

            VStack(alignment: .leading, spacing: 8) {
                ForEach(SettingsPane.allCases, id: \.rawValue) { pane in
                    sidebarItem(for: pane, appLanguage: appLanguage)
                }
            }

            Spacer(minLength: 0)

            Rectangle()
                .fill(SpeakDockVisualStyle.settingsLine)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 8) {
                Text(localized(.settingsCaptureRootLabel))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpeakDockVisualStyle.tertiaryText)
                    .textCase(.uppercase)

                Text(settingsStore.settings.captureRootPath)
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.primary.opacity(0.7))
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .frame(width: Layout.sidebarWidth)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(
            ZStack(alignment: .topLeading) {
                SpeakDockVisualStyle.settingsSidebar

                LinearGradient(
                    colors: [
                        SpeakDockVisualStyle.highlightWash,
                        .clear,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
            }
        )
    }

    private var sidebarHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            SpeakDockBrandGlyph(size: 46)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("SpeakDock")
                    .font(.system(size: 24, weight: .semibold))
                    .tracking(-0.5)

                Text(localized(.settingsHeaderTagline))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func sidebarItem(for pane: SettingsPane, appLanguage: AppLanguageOption) -> some View {
        Button {
            selectedPane = pane
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: pane.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selectedPane == pane ? SpeakDockVisualStyle.accent : Color.primary.opacity(0.72))
                    .frame(width: 18, height: 18)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 5) {
                    Text(pane.title(appLanguage: appLanguage))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.9))

                    Text(sidebarSummary(for: pane, appLanguage: appLanguage))
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        selectedPane == pane
                            ? SpeakDockVisualStyle.settingsSelectionFill
                            : .clear
                    )
            )
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        selectedPane == pane
                            ? SpeakDockVisualStyle.settingsSelectionLine
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailPane(appLanguage: AppLanguageOption) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            paneHeader(appLanguage: appLanguage)

            Rectangle()
                .fill(SpeakDockVisualStyle.settingsLine)
                .frame(height: 1)

            ScrollView {
                paneContent(appLanguage: appLanguage)
                    .padding(Layout.detailPadding)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SpeakDockVisualStyle.settingsContent)
    }

    private func paneHeader(appLanguage: AppLanguageOption) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedPane.title(appLanguage: appLanguage))
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(Color.primary.opacity(0.92))

            Text(selectedPane.subtitle(appLanguage: appLanguage))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let summary = paneSummaryLine(appLanguage: appLanguage) {
                Text(summary)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(SpeakDockVisualStyle.tertiaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Layout.detailPadding)
        .padding(.top, 28)
        .padding(.bottom, 22)
    }

    @ViewBuilder
    private func paneContent(appLanguage: AppLanguageOption) -> some View {
        switch selectedPane {
        case .general:
            generalPane(appLanguage: appLanguage)
        case .dictionary:
            dictionaryPane
        case .refine:
            refinePane
        }
    }

    private func generalPane(appLanguage: AppLanguageOption) -> some View {
        paneColumns {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                SettingsShellSection(
                    title: localized(.settingsInputTitle),
                    subtitle: localized(.settingsInputSubtitle),
                    style: .plain
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            SettingsFieldBlock(title: localized(.settingsAppLanguageLabel)) {
                                Picker(localized(.settingsAppLanguageLabel), selection: $settingsStore.settings.appLanguage) {
                                    ForEach(AppLanguageOption.allCases, id: \.rawValue) { option in
                                        Text(option.displayName(appLanguage: appLanguage)).tag(option)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            SettingsFieldBlock(title: localized(.settingsInputLanguageLabel)) {
                                Picker(localized(.settingsInputLanguageLabel), selection: $settingsStore.settings.inputLanguage) {
                                    ForEach(InputLanguageOption.allCases, id: \.rawValue) { option in
                                        Text(option.displayName(appLanguage: appLanguage)).tag(option)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        dividerLine

                        SettingsFieldBlock(
                            title: localized(.settingsTriggerLabel),
                            footnote: localized(.settingsFnWarning)
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                Picker(localized(.settingsTriggerLabel), selection: triggerModeBinding) {
                                    Text(localized(.settingsTriggerFn)).tag("fn")
                                    Text(localized(.settingsTriggerAlternative)).tag("alternative")
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 236)

                                if isAlternativeTriggerSelected {
                                    SettingsFieldBlock(title: localized(.settingsAlternativeKeyLabel)) {
                                        Picker(localized(.settingsAlternativeKeyLabel), selection: alternativeTriggerBinding) {
                                            ForEach(alternativeTriggerOptions, id: \.rawValue) { option in
                                                Text(option.displayName(appLanguage: appLanguage)).tag(option.rawValue)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } secondary: {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                SettingsShellSection(
                    title: localized(.settingsCaptureTitle),
                    subtitle: localized(.settingsCaptureSubtitle),
                    style: .panel
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        SettingsFieldBlock(title: localized(.settingsCaptureRootLabel)) {
                            Text(settingsStore.settings.captureRootPath)
                                .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.primary.opacity(0.82))
                                .lineLimit(3)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(SpeakDockVisualStyle.settingsCardStrong)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(SpeakDockVisualStyle.settingsLine, lineWidth: 1)
                                )
                        }

                        Button(localized(.settingsChooseAndMigrate)) {
                            chooseCaptureRoot()
                        }
                        .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))

                        if let captureRootMessage {
                            messageView(captureRootMessage, tone: .neutral)
                        }
                    }
                }
            }
        }
    }

    private var dictionaryPane: some View {
        paneColumns {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                SettingsShellSection(
                    title: localized(.settingsTermDictionaryAddEntry),
                    subtitle: localized(.settingsTermDictionarySavedLocalOnly),
                    style: .plain
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        SettingsFieldBlock(title: localized(.settingsTermDictionaryCanonicalPlaceholder)) {
                            TextField(localized(.settingsTermDictionaryCanonicalPlaceholder), text: $termCanonicalTerm)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingsFieldBlock(title: localized(.settingsTermDictionaryAliasesPlaceholder)) {
                            TextField(localized(.settingsTermDictionaryAliasesPlaceholder), text: $termAliasesText)
                                .textFieldStyle(.roundedBorder)
                        }

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

                        if let termDictionaryMessage {
                            messageView(termDictionaryMessage, tone: termDictionaryMessageTone)
                        }
                    }
                }

                SettingsShellSection(
                    title: localized(.settingsTermDictionaryConfirmedTerms),
                    subtitle: localizedFormat(
                        .settingsTermDictionarySavedCount,
                        termDictionaryStore.confirmedDictionary.entries.count
                    ),
                    style: .plain
                ) {
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
            }
        } secondary: {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                SettingsShellSection(
                    title: localized(.settingsTermDictionaryLearningTitle),
                    subtitle: localizedFormat(
                        .settingsTermDictionaryObservedCount,
                        termDictionaryStore.observedCorrections.count
                    ),
                    style: .panel
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        learningSummaryRow(localized(.settingsTermDictionaryLearningSingleEdit))
                        learningSummaryRow(localized(.settingsTermDictionaryLearningPromotion))
                        learningSummaryRow(localized(.settingsTermDictionaryLearningConflict))
                    }
                }

                if !termDictionaryStore.pendingCandidates.isEmpty {
                    SettingsShellSection(
                        title: localized(.settingsTermDictionaryPendingCandidates),
                        subtitle: localizedFormat(
                            .settingsTermDictionaryPendingCount,
                            termDictionaryStore.pendingCandidates.count
                        ),
                        style: .panel
                    ) {
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
    }

    private var refinePane: some View {
        paneColumns {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                SettingsShellSection(
                    title: localized(.settingsRefineConfigurationTitle),
                    subtitle: localized(.settingsRefineConfigurationSubtitle),
                    style: .plain
                ) {
                    VStack(alignment: .leading, spacing: 18) {
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

                        dividerLine

                        VStack(alignment: .leading, spacing: 12) {
                            SettingsFieldBlock(title: localized(.settingsBaseURLLabel)) {
                                TextField(localized(.settingsBaseURLPlaceholder), text: $settingsStore.settings.refineBaseURL)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsFieldBlock(title: localized(.settingsAPIKeyLabel)) {
                                SecureField(localized(.settingsAPIKeyPlaceholder), text: $settingsStore.settings.refineAPIKey)
                                    .textFieldStyle(.roundedBorder)
                            }

                            SettingsFieldBlock(title: localized(.settingsModelLabel)) {
                                TextField(localized(.settingsModelPlaceholder), text: $settingsStore.settings.refineModel)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .disabled(!settingsStore.settings.refineEnabled)

                        dividerLine

                        SettingsFieldBlock(
                            title: localized(.settingsConnectionTitle),
                            footnote: localized(.settingsConnectionSubtitle)
                        ) {
                            Button(isTestingRefine ? localized(.settingsTestingConnection) : localized(.settingsTestConnection)) {
                                runRefineConnectionTest()
                            }
                            .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))
                            .disabled(isTestingRefine)
                        }

                        if let refineTestMessage {
                            messageView(refineTestMessage, tone: refineTestMessageTone)
                        }
                    }
                }
            }
        } secondary: {
            SettingsShellSection(
                title: localized(.settingsRefineWorkflowTitle),
                subtitle: localized(.settingsRefineWorkflowSubtitle),
                style: .panel
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    SettingsWorkflowStep(
                        index: "1",
                        title: localized(.settingsRefineWorkflowStepCaptureTitle),
                        detail: localized(.settingsRefineWorkflowStepCaptureBody)
                    )

                    dividerLine

                    SettingsWorkflowStep(
                        index: "2",
                        title: localized(.settingsRefineWorkflowStepModelTitle),
                        detail: localized(.settingsRefineWorkflowStepModelBody)
                    )

                    dividerLine

                    SettingsWorkflowStep(
                        index: "3",
                        title: localized(.settingsRefineWorkflowStepFallbackTitle),
                        detail: localized(.settingsRefineWorkflowStepFallbackBody)
                    )

                    dividerLine

                    messageView(refineBehaviorSummary, tone: refineBehaviorTone)
                }
            }
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(SpeakDockVisualStyle.settingsLine)
            .frame(height: 1)
    }

    private func sidebarSummary(for pane: SettingsPane, appLanguage: AppLanguageOption) -> String {
        switch pane {
        case .general:
            return "\(settingsStore.settings.appLanguage.displayName(appLanguage: appLanguage)) · \(settingsStore.settings.inputLanguage.displayName(appLanguage: appLanguage))"
        case .dictionary:
            return "\(localizedFormat(.settingsTermDictionarySavedCount, termDictionaryStore.confirmedDictionary.entries.count)) · \(localizedFormat(.settingsTermDictionaryPendingCount, termDictionaryStore.pendingCandidates.count))"
        case .refine:
            return localized(.settingsRefineSidebarSummary)
        }
    }

    private func paneSummaryLine(appLanguage: AppLanguageOption) -> String? {
        switch selectedPane {
        case .general:
            return [
                "\(localized(.settingsAppLanguageLabel)): \(settingsStore.settings.appLanguage.displayName(appLanguage: appLanguage))",
                "\(localized(.settingsInputLanguageLabel)): \(settingsStore.settings.inputLanguage.displayName(appLanguage: appLanguage))",
                "\(localized(.settingsTriggerLabel)): \(triggerSelectionSummary(appLanguage: appLanguage))",
            ].joined(separator: "  ·  ")
        case .dictionary:
            return [
                localizedFormat(.settingsTermDictionarySavedCount, termDictionaryStore.confirmedDictionary.entries.count),
                localizedFormat(.settingsTermDictionaryPendingCount, termDictionaryStore.pendingCandidates.count),
            ].joined(separator: "  ·  ")
        case .refine:
            return nil
        }
    }

    private func triggerSelectionSummary(appLanguage: AppLanguageOption) -> String {
        switch settingsStore.settings.triggerSelection {
        case .fn:
            localized(.settingsTriggerFn)
        case let .alternative(identifier):
            ModifierTriggerKey(rawValue: identifier)?.displayName(appLanguage: appLanguage)
                ?? localized(.settingsTriggerAlternative)
        }
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

    private var isRefineConfigurationComplete: Bool {
        !settingsStore.settings.refineBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !settingsStore.settings.refineAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !settingsStore.settings.refineModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var refineBehaviorSummary: String {
        if !settingsStore.settings.refineEnabled {
            return localized(.settingsRefineBehaviorDirect)
        }

        guard isRefineConfigurationComplete else {
            return localized(.settingsRefineBehaviorIncomplete)
        }

        return localizedFormat(.settingsRefineBehaviorReady, settingsStore.settings.refineModel)
    }

    private var refineBehaviorTone: SpeakDockBadgeTone {
        if !settingsStore.settings.refineEnabled {
            return .neutral
        }

        return isRefineConfigurationComplete ? .accent : .warning
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
        VStack(alignment: .leading, spacing: 10) {
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

            HStack {
                Button(localized(.settingsRemove)) {
                    removeTermEntry(entry)
                }
                .buttonStyle(SpeakDockActionButtonStyle(kind: .subtle))

                Spacer(minLength: 0)
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
    private func pendingCandidateRow(_ candidate: TermDictionaryCandidate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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

            HStack(spacing: 8) {
                Button(localized(.settingsConfirm)) {
                    confirmTermCandidate(candidate)
                }
                .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))

                Button(localized(.settingsDismiss)) {
                    dismissTermCandidate(candidate)
                }
                .buttonStyle(SpeakDockActionButtonStyle(kind: .subtle))

                Spacer(minLength: 0)
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
    private func learningSummaryRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(SpeakDockVisualStyle.accent)
                .frame(width: 5, height: 5)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
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

private extension SettingsView {
    func paneColumns<Primary: View, Secondary: View>(
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) -> some View {
        HStack(alignment: .top, spacing: Layout.paneSpacing) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                primary()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                secondary()
            }
            .frame(width: Layout.secondaryColumnWidth, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private enum SettingsShellSectionStyle {
    case plain
    case panel
}

private struct SettingsShellSection<Content: View>: View {
    let title: String
    let subtitle: String
    let style: SettingsShellSectionStyle
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        style: SettingsShellSectionStyle = .panel,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.92))

                Text(subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(SettingsSectionSurface(style: style))
    }
}

private struct SettingsFieldBlock<Content: View>: View {
    let title: String
    var footnote: String?
    @ViewBuilder let content: Content

    init(
        title: String,
        footnote: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footnote = footnote
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(SpeakDockVisualStyle.secondaryText)

            content

            if let footnote {
                Text(footnote)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsSectionSurface: ViewModifier {
    let style: SettingsShellSectionStyle

    func body(content: Content) -> some View {
        switch style {
        case .plain:
            content
                .padding(.vertical, 4)
        case .panel:
            content
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpeakDockVisualStyle.settingsCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            SpeakDockVisualStyle.highlightWash.opacity(0.55),
                                            .clear,
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpeakDockVisualStyle.settingsLine, lineWidth: 1)
                )
        }
    }
}

private struct SettingsWorkflowStep: View {
    let index: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(index)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(SpeakDockVisualStyle.accent)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(SpeakDockVisualStyle.accent.opacity(0.10))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.9))

                Text(detail)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
