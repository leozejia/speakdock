import AppKit

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    static var onDidFinishLaunching: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Self.onDidFinishLaunching?()
    }
}
