import AppKit
import SpeakDockCore
import SwiftUI

struct SettingsView: View {
    @Bindable var settingsStore: SettingsStore
    @State private var captureRootMessage: String?
    @State private var refineTestMessage: String?
    @State private var saveMessage: String?
    @State private var isTestingRefine = false

    private let refineTester: any RefineConnectionTesting

    init(
        settingsStore: SettingsStore,
        refineTester: any RefineConnectionTesting = RefineConnectionTester()
    ) {
        self.settingsStore = settingsStore
        self.refineTester = refineTester
    }

    var body: some View {
        Form {
            Section("General") {
                Picker("Language", selection: $settingsStore.settings.languageCode) {
                    Text("简体中文").tag("zh-CN")
                    Text("English").tag("en-US")
                    Text("繁體中文").tag("zh-TW")
                    Text("日本語").tag("ja-JP")
                    Text("한국어").tag("ko-KR")
                }

                triggerSelectionView

                VStack(alignment: .leading, spacing: 8) {
                    Text("Capture Root")

                    HStack(alignment: .top, spacing: 12) {
                        TextField(
                            "Capture Root",
                            text: .constant(settingsStore.settings.captureRootPath)
                        )
                        .disabled(true)

                        Button("Choose & Migrate…") {
                            chooseCaptureRoot()
                        }
                    }

                    if let captureRootMessage {
                        statusText(captureRootMessage)
                    }
                }
            }

            Section("Refine") {
                Toggle("Enable Refine", isOn: $settingsStore.settings.refineEnabled)
                TextField("Base URL", text: $settingsStore.settings.refineBaseURL)
                TextField("API Key", text: $settingsStore.settings.refineAPIKey)
                TextField("Model", text: $settingsStore.settings.refineModel)
            }

            Section("Actions") {
                HStack(spacing: 12) {
                    Button(isTestingRefine ? "Testing..." : "Test") {
                        runRefineConnectionTest()
                    }
                    .disabled(isTestingRefine)

                    Button("Save") {
                        saveSettings()
                    }
                }

                if let refineTestMessage {
                    statusText(refineTestMessage)
                }

                if let saveMessage {
                    statusText(saveMessage)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, minHeight: 320)
        .padding()
    }

    @ViewBuilder
    private var triggerSelectionView: some View {
        switch settingsStore.settings.triggerSelection {
        case .fn:
            Picker("Trigger", selection: fnTriggerBinding) {
                Text("Fn").tag("fn")
                Text("Alternative").tag("alternative")
            }
        case let .alternative(identifier):
            VStack(alignment: .leading, spacing: 8) {
                Picker("Trigger", selection: alternativeTriggerModeBinding) {
                    Text("Fn").tag("fn")
                    Text("Alternative").tag("alternative")
                }

                TextField(
                    "Alternative Trigger Identifier",
                    text: Binding(
                        get: { identifier },
                        set: { settingsStore.settings.triggerSelection = .alternative($0) }
                    )
                )
            }
        }
    }

    private var fnTriggerBinding: Binding<String> {
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
                settingsStore.settings.triggerSelection = newValue == "fn"
                    ? .fn
                    : .alternative("")
            }
        )
    }

    private var alternativeTriggerModeBinding: Binding<String> {
        fnTriggerBinding
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

    private func runRefineConnectionTest() {
        isTestingRefine = true
        refineTestMessage = "Testing..."

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

    @ViewBuilder
    private func statusText(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
    }
}
