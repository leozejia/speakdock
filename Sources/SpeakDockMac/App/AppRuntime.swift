import AppKit

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    static var onDidFinishLaunching: (() -> Void)?
    private static var currentActivationPolicy: NSApplication.ActivationPolicy?
    private static var applicationResolver: @MainActor () -> NSApplication? = { NSApp }
    private static var activationPolicyApplier: @MainActor (NSApplication, NSApplication.ActivationPolicy) -> Void = { application, policy in
        application.setActivationPolicy(policy)
    }
    private static var applicationActivator: @MainActor (NSApplication) -> Void = { application in
        application.activate(ignoringOtherApps: false)
    }

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

        guard let application = applicationResolver() else {
            SpeakDockLog.lifecycle.error("activation policy update skipped because NSApp is unavailable")
            return
        }

        activationPolicyApplier(application, targetPolicy)
        currentActivationPolicy = targetPolicy

        if activateApp {
            applicationActivator(application)
        }
    }

    static func installTestingHooks(
        applicationResolver: @escaping @MainActor () -> NSApplication?,
        activationPolicyApplier: @escaping @MainActor (NSApplication, NSApplication.ActivationPolicy) -> Void,
        applicationActivator: @escaping @MainActor (NSApplication) -> Void
    ) {
        self.applicationResolver = applicationResolver
        self.activationPolicyApplier = activationPolicyApplier
        self.applicationActivator = applicationActivator
        currentActivationPolicy = nil
    }

    static func resetTestingHooks() {
        applicationResolver = { NSApp }
        activationPolicyApplier = { application, policy in
            application.setActivationPolicy(policy)
        }
        applicationActivator = { application in
            application.activate(ignoringOtherApps: false)
        }
        currentActivationPolicy = nil
    }
}
