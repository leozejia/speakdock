import AppKit
import SwiftUI

private struct SpeakDockTestHostLaunchOptions {
    let stateFileURL: URL?
    let readyFileURL: URL?

    init(arguments: [String] = CommandLine.arguments) {
        stateFileURL = Self.urlValue(after: "--state-file", in: arguments)
        readyFileURL = Self.urlValue(after: "--ready-file", in: arguments)
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
    @Published var text = ""

    private let stateFileURL: URL?
    private let readyFileURL: URL?

    init(options: SpeakDockTestHostLaunchOptions) {
        self.stateFileURL = options.stateFileURL
        self.readyFileURL = options.readyFileURL
        persistState()
    }

    func persistState() {
        guard let stateFileURL else {
            return
        }

        try? FileManager.default.createDirectory(
            at: stateFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? text.write(to: stateFileURL, atomically: true, encoding: .utf8)
    }

    func markReady() {
        guard let readyFileURL else {
            return
        }

        try? FileManager.default.createDirectory(
            at: readyFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? "ready".write(to: readyFileURL, atomically: true, encoding: .utf8)
    }
}

private struct SpeakDockTestHostView: View {
    @ObservedObject var model: SpeakDockTestHostModel
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SpeakDock Test Host")
                .font(.system(size: 20, weight: .semibold))

            Text("This window provides a stable editable text field for automated Compose smoke tests.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            TextField("SpeakDock smoke target", text: $model.text)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 220)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                inputFocused = true
                model.markReady()
            }
        }
        .onChange(of: model.text) { _, _ in
            model.persistState()
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
        WindowGroup {
            SpeakDockTestHostView(model: model)
        }
    }
}
