import AppKit

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    static var onDidFinishLaunching: (() -> Void)?
    private static var initialShowDockIcon = true
    private static var currentActivationPolicy: NSApplication.ActivationPolicy?

    static func configureInitialVisibility(showDockIcon: Bool) {
        initialShowDockIcon = showDockIcon
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        Self.updateActivationPolicy(
            showDockIcon: Self.initialShowDockIcon,
            activateWhenShowingDockIcon: false
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        SpeakDockLog.lifecycle.notice("application did finish launching")
        Self.onDidFinishLaunching?()
    }

    static func updateActivationPolicy(
        showDockIcon: Bool,
        activateWhenShowingDockIcon: Bool = true
    ) {
        let targetPolicy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        guard currentActivationPolicy != targetPolicy else {
            return
        }

        NSApp.setActivationPolicy(targetPolicy)
        currentActivationPolicy = targetPolicy

        if showDockIcon && activateWhenShowingDockIcon {
            NSApp.activate(ignoringOtherApps: false)
        }
    }
}
