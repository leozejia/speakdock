import AppKit

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    static var onDidFinishLaunching: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        SpeakDockLog.lifecycle.notice("application did finish launching")
        NSApp.setActivationPolicy(.accessory)
        Self.onDidFinishLaunching?()
    }
}
