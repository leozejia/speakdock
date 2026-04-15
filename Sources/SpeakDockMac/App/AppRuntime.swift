import AppKit

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    static var onDidFinishLaunching: (() -> Void)?
    private static var currentActivationPolicy: NSApplication.ActivationPolicy?

    static func configureInitialVisibility() {
        updateActivationPolicy(activateApp: false)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        Self.configureInitialVisibility()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        SpeakDockLog.lifecycle.notice("application did finish launching")
        Self.onDidFinishLaunching?()
    }

    static func updateActivationPolicy(activateApp: Bool = true) {
        let targetPolicy: NSApplication.ActivationPolicy = .regular
        guard currentActivationPolicy != targetPolicy else {
            return
        }

        NSApp.setActivationPolicy(targetPolicy)
        currentActivationPolicy = targetPolicy

        if activateApp {
            NSApp.activate(ignoringOtherApps: false)
        }
    }
}
