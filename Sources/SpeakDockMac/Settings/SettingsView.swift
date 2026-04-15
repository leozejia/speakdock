import AppKit
import SpeakDockCore
import SwiftUI

struct SettingsView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var termDictionaryStore: TermDictionaryStore
    @State private var captureRootMessage: String?
    @State private var refineTestMessage: String?
    @State private var saveMessage: String?
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                SpeakDockPanel(
                    title: "Input",
                    subtitle: "Language and trigger should feel predictable."
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        LabeledContent("Language") {
                            Picker("Language", selection: $settingsStore.settings.languageCode) {
                                Text("简体中文").tag("zh-CN")
                                Text("English").tag("en-US")
                                Text("繁體中文").tag("zh-TW")
                                Text("日本語").tag("ja-JP")
                                Text("한국어").tag("ko-KR")
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 150)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Trigger")
                                    .font(.system(size: 13, weight: .medium))

                                Spacer()

                                Picker("Trigger", selection: triggerModeBinding) {
                                    Text("Fn").tag("fn")
                                    Text("Alternative").tag("alternative")
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 220)
                            }

                            if isAlternativeTriggerSelected {
                                LabeledContent("Alternative Key") {
                                    Picker("Alternative Key", selection: alternativeTriggerBinding) {
                                        ForEach(alternativeTriggerOptions, id: \.rawValue) { option in
                                            Text(option.displayName).tag(option.rawValue)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(width: 170)
                                }
                            }

                            Text("If Fn becomes unavailable, SpeakDock warns in the menu bar and only switches when you choose an alternative here.")
                                .font(.system(size: 11.5))
                                .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()

                        Toggle(isOn: $settingsStore.settings.showDockIcon) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Dock Icon")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Keep a visible app icon in the Dock when the menu bar gets crowded.")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }

                SpeakDockPanel(
                    title: "Capture",
                    subtitle: "Markdown files stay local and migrate with the folder."
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Capture Root")
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

                            Button("Choose & Migrate…") {
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
                    title: "Term Dictionary",
                    subtitle: "Keep names and jargon stable with local-only replacements."
                ) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add Entry")
                                .font(.system(size: 13, weight: .medium))

                            TextField("Canonical term", text: $termCanonicalTerm)
                                .textFieldStyle(.roundedBorder)

                            TextField("Aliases, separated by commas", text: $termAliasesText)
                                .textFieldStyle(.roundedBorder)

                            HStack(alignment: .center, spacing: 12) {
                                Button("Add Entry") {
                                    addTermEntry()
                                }
                                .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))
                                .disabled(!canAddTermEntry)

                                Text("Saved only on this Mac. Not committed to Git.")
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
                                Text("Confirmed Terms")
                                    .font(.system(size: 13, weight: .medium))

                                Spacer()

                                SpeakDockStatusBadge(
                                    title: "\(termDictionaryStore.confirmedDictionary.entries.count) Saved",
                                    tone: termDictionaryStore.confirmedDictionary.entries.isEmpty ? .neutral : .success
                                )
                            }

                            if termDictionaryStore.confirmedDictionary.entries.isEmpty {
                                emptyStateView("No confirmed terms yet.")
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
                                Text("Pending Candidates")
                                    .font(.system(size: 13, weight: .medium))

                                Spacer()

                                SpeakDockStatusBadge(
                                    title: "\(termDictionaryStore.pendingCandidates.count) Pending",
                                    tone: termDictionaryStore.pendingCandidates.isEmpty ? .neutral : .warning
                                )
                            }

                            if termDictionaryStore.pendingCandidates.isEmpty {
                                emptyStateView(
                                    "No pending candidates yet. Manual correction capture is not wired into the app flow yet."
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
                    title: "Refine",
                    subtitle: "Optional cleanup path. Keep it off unless you need it."
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $settingsStore.settings.refineEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Refine")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Use the configured model after deterministic cleanup.")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                            }
                        }
                        .toggleStyle(.switch)

                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Base URL") {
                                TextField("https://example.com/v1", text: $settingsStore.settings.refineBaseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 280)
                            }

                            LabeledContent("API Key") {
                                SecureField("sk-...", text: $settingsStore.settings.refineAPIKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 280)
                            }

                            LabeledContent("Model") {
                                TextField("gpt-5.4", text: $settingsStore.settings.refineModel)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                            }
                        }
                        .disabled(!settingsStore.settings.refineEnabled)
                    }
                }

                SpeakDockPanel(
                    title: "Actions",
                    subtitle: "Validate the refine connection before trusting the output."
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            Button(isTestingRefine ? "Testing…" : "Test Connection") {
                                runRefineConnectionTest()
                            }
                            .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))
                            .disabled(isTestingRefine)

                            Button("Save") {
                                saveSettings()
                            }
                            .buttonStyle(SpeakDockActionButtonStyle(kind: .secondary))
                        }

                        if let refineTestMessage {
                            messageView(
                                refineTestMessage,
                                tone: refineTestMessage.hasPrefix("Test Passed") ? .success : .neutral
                            )
                        }

                        if let saveMessage {
                            messageView(
                                saveMessage,
                                tone: saveMessage == "Saved" ? .success : .neutral
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
        HStack(alignment: .center, spacing: 16) {
            SpeakDockBrandGlyph(size: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text("SpeakDock")
                    .font(.system(size: 24, weight: .semibold))
                    .tracking(-0.3)

                Text("AI voice input for macOS. Fast capture, careful cleanup, local-first memory.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SpeakDockStatusBadge(
                    title: settingsStore.settings.refineEnabled ? "Refine On" : "Refine Off",
                    tone: settingsStore.settings.refineEnabled ? .accent : .neutral
                )
                SpeakDockStatusBadge(
                    title: settingsStore.settings.showDockIcon ? "Dock On" : "Dock Off",
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
        panel.prompt = "Migrate"
        panel.message = "Choose a new Capture root. SpeakDock will migrate existing files."
        panel.directoryURL = URL(
            fileURLWithPath: settingsStore.settings.captureRootPath,
            isDirectory: true
        )

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try settingsStore.updateCaptureRoot(to: url)
            captureRootMessage = "Capture Root Migrated"
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
            setTermDictionaryMessage("Term entry saved.", tone: .success)
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func removeTermEntry(_ entry: TermDictionaryEntry) {
        do {
            try termDictionaryStore.removeEntry(canonicalTerm: entry.canonicalTerm)
            setTermDictionaryMessage("Removed \(entry.canonicalTerm).", tone: .success)
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func confirmTermCandidate(_ candidate: TermDictionaryCandidate) {
        do {
            try termDictionaryStore.confirm(candidate)
            setTermDictionaryMessage("Candidate promoted to confirmed terms.", tone: .success)
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func dismissTermCandidate(_ candidate: TermDictionaryCandidate) {
        do {
            try termDictionaryStore.dismiss(candidate)
            setTermDictionaryMessage("Candidate dismissed.", tone: .neutral)
        } catch {
            setTermDictionaryMessage(userFacingMessage(for: error), tone: .critical)
        }
    }

    private func runRefineConnectionTest() {
        isTestingRefine = true
        refineTestMessage = "Testing…"

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
                    refineTestMessage = "Test Passed: \(response)"
                    isTestingRefine = false
                }
            } catch {
                await MainActor.run {
                    refineTestMessage = userFacingMessage(for: error)
                    isTestingRefine = false
                }
            }
        }
    }

    private func saveSettings() {
        do {
            try settingsStore.save()
            saveMessage = "Saved"
        } catch {
            saveMessage = userFacingMessage(for: error)
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

            Button("Remove") {
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

                Text("Alias: \(candidate.alias)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                    .textSelection(.enabled)

                Text("Source: \(candidateSourceLabel(candidate.source))")
                    .font(.system(size: 11))
                    .foregroundStyle(SpeakDockVisualStyle.tertiaryText)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Button("Confirm") {
                    confirmTermCandidate(candidate)
                }
                .buttonStyle(SpeakDockActionButtonStyle(kind: .primary))

                Button("Dismiss") {
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
            "Manual correction"
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
