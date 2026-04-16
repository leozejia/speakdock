import AppKit
import SpeakDockCore
import SwiftUI

struct SpeakDockApp: App {
    @NSApplicationDelegateAdaptor(AppRuntime.self) private var appRuntime
    @State private var settingsStore: SettingsStore
    @State private var termDictionaryStore: TermDictionaryStore
    @State private var triggerController: TriggerController
    @State private var audioCaptureEngine: AudioCaptureEngine
    @State private var composeTarget: ClipboardComposeTarget
    @State private var captureTarget: CaptureFileTarget
    @State private var speechController: SpeechController
    @State private var overlayPanelController: OverlayPanelController
    @State private var hotPathCoordinator: HotPathCoordinator

    init() {
        let launchOptions = SpeakDockLaunchOptions()
        let settingsStore = SettingsStore()
        let termDictionaryStore = TermDictionaryStore()
        AppLocalizer.setCurrentAppLanguage(settingsStore.settings.appLanguage)
        _ = settingsStore.addSettingsObserver { settings in
            AppLocalizer.setCurrentAppLanguage(settings.appLanguage)
        }
        let triggerController = TriggerController(settingsStore: settingsStore)
        let audioCaptureEngine = AudioCaptureEngine()
        let composeTarget = ClipboardComposeTarget()
        let captureTarget = CaptureFileTarget()
        let speechController = SpeechController(settingsStore: settingsStore)
        let overlayPanelController = OverlayPanelController()
        let hotPathCoordinator = HotPathCoordinator(
            settingsStore: settingsStore,
            triggerController: triggerController,
            audioCaptureEngine: audioCaptureEngine,
            composeTarget: composeTarget,
            captureTarget: captureTarget,
            speechController: speechController,
            overlayPanelController: overlayPanelController,
            termDictionaryStore: termDictionaryStore,
            cleanNormalizer: CleanNormalizer(
                termDictionaryProvider: {
                    termDictionaryStore.confirmedDictionary
                }
            )
        )
        switch launchOptions.mode {
        case .normal:
            AppRuntime.onDidFinishLaunching = {
                AppRuntime.updateActivationPolicy()
                triggerController.start()
            }
        case .composeProbe:
            let composeProbeRunner = ComposeProbeRunner(
                composeTarget: composeTarget,
                duration: launchOptions.composeProbeDuration
            )
            AppRuntime.onDidFinishLaunching = {
                AppRuntime.updateActivationPolicy()
                composeProbeRunner.start()
            }
        }

        _settingsStore = State(initialValue: settingsStore)
        _termDictionaryStore = State(initialValue: termDictionaryStore)
        _triggerController = State(initialValue: triggerController)
        _audioCaptureEngine = State(initialValue: audioCaptureEngine)
        _composeTarget = State(initialValue: composeTarget)
        _captureTarget = State(initialValue: captureTarget)
        _speechController = State(initialValue: speechController)
        _overlayPanelController = State(initialValue: overlayPanelController)
        _hotPathCoordinator = State(initialValue: hotPathCoordinator)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRoot(
                settingsStore: settingsStore,
                triggerController: triggerController,
                hotPathCoordinator: hotPathCoordinator
            )
        } label: {
            SpeakDockMenuBarIcon(availability: triggerController.availability)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                settingsStore: settingsStore,
                termDictionaryStore: termDictionaryStore
            )
        }
    }
}
