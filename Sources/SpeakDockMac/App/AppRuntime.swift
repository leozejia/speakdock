import AppKit

@MainActor
final class AppRuntime: NSObject, NSApplicationDelegate {
    struct RunningApplicationRecord {
        let processIdentifier: pid_t
        let activate: @MainActor () -> Void
    }

    static var onDidFinishLaunching: (() -> Void)?
    static var launchMode: SpeakDockLaunchOptions.Mode = .normal
    private static var currentActivationPolicy: NSApplication.ActivationPolicy?
    private static var applicationIconLoader: @MainActor () -> NSImage? = { SpeakDockBrandAssets.applicationIcon }
    private static var applicationResolver: @MainActor () -> NSApplication? = { NSApp }
    private static var activationPolicyApplier: @MainActor (NSApplication, NSApplication.ActivationPolicy) -> Void = { application, policy in
        application.setActivationPolicy(policy)
    }
    private static var applicationActivator: @MainActor (NSApplication) -> Void = { application in
        application.activate(ignoringOtherApps: false)
    }
    private static var currentProcessIdentifierResolver: @MainActor () -> pid_t = {
        ProcessInfo.processInfo.processIdentifier
    }
    private static var bundleIdentifierResolver: @MainActor () -> String? = {
        Bundle.main.bundleIdentifier
    }
    private static var runningApplicationsResolver: @MainActor (String) -> [RunningApplicationRecord] = { bundleIdentifier in
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).map { application in
            RunningApplicationRecord(
                processIdentifier: application.processIdentifier,
                activate: {
                    _ = application.activate(options: [])
                }
            )
        }
    }
    private static var duplicateTerminator: @MainActor () -> Void = {
        NSApp.terminate(nil)
    }

    static func configureInitialVisibility() {
        updateActivationPolicy(activateApp: false)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        Self.configureInitialVisibility()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard Self.ensureSingleInstance(mode: Self.launchMode) else {
            return
        }

        if let application = Self.applicationResolver(),
           let applicationIcon = Self.applicationIconLoader() {
            application.applicationIconImage = applicationIcon
        }
        SpeakDockLog.lifecycle.notice("application did finish launching")
        Self.onDidFinishLaunching?()
    }

    static func ensureSingleInstance(mode: SpeakDockLaunchOptions.Mode) -> Bool {
        guard mode == .normal else {
            return true
        }

        guard let bundleIdentifier = bundleIdentifierResolver() else {
            return true
        }

        let currentProcessIdentifier = currentProcessIdentifierResolver()
        let existingInstance = runningApplicationsResolver(bundleIdentifier).first {
            $0.processIdentifier != currentProcessIdentifier
        }

        guard let existingInstance else {
            return true
        }

        SpeakDockLog.lifecycle.notice("duplicate normal-mode launch detected; activating existing instance")
        existingInstance.activate()
        duplicateTerminator()
        return false
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
        applicationIconLoader: @escaping @MainActor () -> NSImage?,
        applicationResolver: @escaping @MainActor () -> NSApplication?,
        activationPolicyApplier: @escaping @MainActor (NSApplication, NSApplication.ActivationPolicy) -> Void,
        applicationActivator: @escaping @MainActor (NSApplication) -> Void
    ) {
        self.applicationIconLoader = applicationIconLoader
        self.applicationResolver = applicationResolver
        self.activationPolicyApplier = activationPolicyApplier
        self.applicationActivator = applicationActivator
        currentActivationPolicy = nil
    }

    static func installSingleInstanceTestingHooks(
        currentProcessIdentifier: @escaping @MainActor () -> pid_t,
        bundleIdentifier: @escaping @MainActor () -> String? = { Bundle.main.bundleIdentifier },
        runningApplicationsResolver: @escaping @MainActor (String) -> [RunningApplicationRecord],
        duplicateTerminator: @escaping @MainActor () -> Void
    ) {
        self.currentProcessIdentifierResolver = currentProcessIdentifier
        self.bundleIdentifierResolver = bundleIdentifier
        self.runningApplicationsResolver = runningApplicationsResolver
        self.duplicateTerminator = duplicateTerminator
    }

    static func resetTestingHooks() {
        launchMode = .normal
        applicationIconLoader = { SpeakDockBrandAssets.applicationIcon }
        applicationResolver = { NSApp }
        activationPolicyApplier = { application, policy in
            application.setActivationPolicy(policy)
        }
        applicationActivator = { application in
            application.activate(ignoringOtherApps: false)
        }
        currentProcessIdentifierResolver = {
            ProcessInfo.processInfo.processIdentifier
        }
        bundleIdentifierResolver = {
            Bundle.main.bundleIdentifier
        }
        runningApplicationsResolver = { bundleIdentifier in
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).map { application in
                RunningApplicationRecord(
                    processIdentifier: application.processIdentifier,
                    activate: {
                        _ = application.activate(options: [])
                    }
                )
            }
        }
        duplicateTerminator = {
            NSApp.terminate(nil)
        }
        currentActivationPolicy = nil
    }
}
