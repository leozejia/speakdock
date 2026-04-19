import AppKit
import SwiftUI

private enum SpeakDockTestHostField: String, CaseIterable {
    case primary
    case secondary

    var label: String {
        switch self {
        case .primary:
            "A"
        case .secondary:
            "B"
        }
    }

    var windowTitle: String {
        "SpeakDock Test Host \(label)"
    }

    var placeholder: String {
        switch self {
        case .primary:
            "SpeakDock smoke target A"
        case .secondary:
            "SpeakDock smoke target B"
        }
    }

    var accessibilityIdentifier: String {
        "speakdock-testhost-\(rawValue)"
    }
}

private struct SpeakDockTestHostLaunchOptions {
    let stateFileURL: URL?
    let readyFileURL: URL?
    let commandFileURL: URL?

    init(arguments: [String] = CommandLine.arguments) {
        stateFileURL = Self.urlValue(after: "--state-file", in: arguments)
        readyFileURL = Self.urlValue(after: "--ready-file", in: arguments)
        commandFileURL = Self.urlValue(after: "--command-file", in: arguments)
    }

    private static func urlValue(after flag: String, in arguments: [String]) -> URL? {
        guard let flagIndex = arguments.firstIndex(of: flag) else {
            return nil
        }

        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex else {
            return nil
        }

        return URL(fileURLWithPath: arguments[valueIndex])
    }
}

@MainActor
private final class SpeakDockTestHostModel: ObservableObject {
    @Published var primaryText = ""
    @Published var secondaryText = ""
    @Published var focusedField: SpeakDockTestHostField = .primary

    private let stateFileURL: URL?
    private let readyFileURL: URL?
    private let commandFileURL: URL?
    private var readyFields: Set<SpeakDockTestHostField> = []
    private var didMarkReady = false
    private var commandPollingTask: Task<Void, Never>?

    init(options: SpeakDockTestHostLaunchOptions) {
        self.stateFileURL = options.stateFileURL
        self.readyFileURL = options.readyFileURL
        self.commandFileURL = options.commandFileURL
        persistState()
    }

    func binding(for field: SpeakDockTestHostField) -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.text(for: field) ?? ""
            },
            set: { [weak self] newValue in
                self?.setText(newValue, for: field)
            }
        )
    }

    func markWindowReady(_ field: SpeakDockTestHostField) {
        readyFields.insert(field)
        guard !didMarkReady, readyFields.count == SpeakDockTestHostField.allCases.count else {
            return
        }

        didMarkReady = true
        markReady()
    }

    func persistState() {
        guard let stateFileURL else {
            return
        }

        try? FileManager.default.createDirectory(
            at: stateFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let serializedText = "\(primaryText)\n\(secondaryText)"
        try? serializedText.write(to: stateFileURL, atomically: true, encoding: .utf8)
    }

    func startCommandPolling() {
        guard commandPollingTask == nil, commandFileURL != nil else {
            return
        }

        commandPollingTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                self.applyPendingCommandIfNeeded()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    func stopCommandPolling() {
        commandPollingTask?.cancel()
        commandPollingTask = nil
    }

    func applyPendingCommandIfNeeded() {
        guard let commandFileURL else {
            return
        }

        guard FileManager.default.fileExists(atPath: commandFileURL.path) else {
            return
        }

        let commandText = (try? String(contentsOf: commandFileURL, encoding: .utf8)) ?? ""
        try? FileManager.default.removeItem(at: commandFileURL)
        apply(commandText: commandText)
    }

    private func text(for field: SpeakDockTestHostField) -> String {
        switch field {
        case .primary:
            primaryText
        case .secondary:
            secondaryText
        }
    }

    private func setText(_ text: String, for field: SpeakDockTestHostField) {
        switch field {
        case .primary:
            primaryText = text
        case .secondary:
            secondaryText = text
        }
        persistState()
    }

    private func markReady() {
        guard let readyFileURL else {
            return
        }

        try? FileManager.default.createDirectory(
            at: readyFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? "ready".write(to: readyFileURL, atomically: true, encoding: .utf8)
    }

    private func apply(commandText: String) {
        if let focusCommand = commandText.split(separator: "\n").first,
           focusCommand.hasPrefix("__focus__:"),
           let field = SpeakDockTestHostField(rawValue: String(focusCommand.dropFirst("__focus__:".count)))
        {
            focusedField = field
            persistState()
            return
        }

        setText(commandText, for: focusedField)
    }
}

private struct SpeakDockTestHostWindowObserver: NSViewRepresentable {
    let onResolve: @MainActor (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onResolve(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onResolve(nsView.window)
        }
    }
}

private struct SpeakDockTestHostWindowView: View {
    @ObservedObject var model: SpeakDockTestHostModel
    let field: SpeakDockTestHostField

    @Environment(\.openWindow) private var openWindow
    @FocusState private var isTextFieldFocused: Bool
    @State private var window: NSWindow?
    @State private var didRequestSecondaryWindow = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(field.windowTitle)
                .font(.system(size: 20, weight: .semibold))

            Text("This window provides a stable editable text field for automated Compose smoke tests.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            TextField(field.placeholder, text: model.binding(for: field))
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .accessibilityIdentifier(field.accessibilityIdentifier)
                .accessibilityLabel(field.accessibilityIdentifier)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 180)
        .background(
            SpeakDockTestHostWindowObserver { resolvedWindow in
                guard let resolvedWindow else {
                    return
                }

                if window !== resolvedWindow {
                    window = resolvedWindow
                }
                resolvedWindow.title = field.windowTitle
            }
        )
        .onAppear {
            if field == .primary, !didRequestSecondaryWindow {
                didRequestSecondaryWindow = true
                openWindow(id: SpeakDockTestHostField.secondary.rawValue)
                scheduleFocusRefresh()
            }
            model.markWindowReady(field)
            model.startCommandPolling()
            applyFocusIfNeeded(model.focusedField)
        }
        .onDisappear {
            model.stopCommandPolling()
        }
        .onChange(of: model.focusedField) { _, newValue in
            applyFocusIfNeeded(newValue)
        }
        .onChange(of: isTextFieldFocused) { _, isFocused in
            guard isFocused, model.focusedField != field else {
                return
            }

            model.focusedField = field
            model.persistState()
        }
    }

    private func applyFocusIfNeeded(_ focusedField: SpeakDockTestHostField) {
        guard focusedField == field else {
            return
        }

        focusWindowAndField(after: 0)
        focusWindowAndField(after: 0.08)
    }

    private func scheduleFocusRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            applyFocusIfNeeded(model.focusedField)
        }
    }

    private func focusWindowAndField(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            NSApp.activate(ignoringOtherApps: true)
            if let window {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
            isTextFieldFocused = true
        }
    }
}

struct SpeakDockTestHostApp: App {
    @StateObject private var model: SpeakDockTestHostModel

    init() {
        let options = SpeakDockTestHostLaunchOptions()
        _model = StateObject(
            wrappedValue: SpeakDockTestHostModel(options: options)
        )
    }

    var body: some Scene {
        Window(SpeakDockTestHostField.primary.windowTitle, id: SpeakDockTestHostField.primary.rawValue) {
            SpeakDockTestHostWindowView(model: model, field: .primary)
        }

        Window(SpeakDockTestHostField.secondary.windowTitle, id: SpeakDockTestHostField.secondary.rawValue) {
            SpeakDockTestHostWindowView(model: model, field: .secondary)
        }

        Settings {
            EmptyView()
        }
    }
}
