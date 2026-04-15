import AppKit

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    static var onDidFinishLaunching: (() -> Void)?
    private static var currentActivationPolicy: NSApplication.ActivationPolicy?

    func applicationDidFinishLaunching(_ notification: Notification) {
        SpeakDockLog.lifecycle.notice("application did finish launching")
        Self.onDidFinishLaunching?()
    }

    static func updateActivationPolicy(showDockIcon: Bool) {
        let targetPolicy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        guard currentActivationPolicy != targetPolicy else {
            return
        }

        NSApp.setActivationPolicy(targetPolicy)
        currentActivationPolicy = targetPolicy

        if showDockIcon {
            NSApp.activate(ignoringOtherApps: false)
        }
    }
}
