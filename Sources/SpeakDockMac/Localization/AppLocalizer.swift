import Foundation
import SpeakDockCore

enum AppLocalizedStringKey: String {
    case appLanguageFollowSystem = "app_language.follow_system"
    case appLanguageEnglish = "app_language.english"
    case appLanguageSimplifiedChinese = "app_language.simplified_chinese"
    case inputLanguageEnglish = "input_language.english"
    case inputLanguageSimplifiedChinese = "input_language.simplified_chinese"
    case inputLanguageTraditionalChinese = "input_language.traditional_chinese"
    case inputLanguageJapanese = "input_language.japanese"
    case inputLanguageKorean = "input_language.korean"
    case modifierTriggerRightControl = "modifier_trigger.right_control"
    case modifierTriggerRightOption = "modifier_trigger.right_option"
    case modifierTriggerRightCommand = "modifier_trigger.right_command"
    case modifierTriggerRightShift = "modifier_trigger.right_shift"
    case settingsInputTitle = "settings.input.title"
    case settingsInputSubtitle = "settings.input.subtitle"
    case settingsPaneGeneralTitle = "settings.pane.general.title"
    case settingsPaneGeneralSubtitle = "settings.pane.general.subtitle"
    case settingsPaneDictionaryTitle = "settings.pane.dictionary.title"
    case settingsPaneDictionarySubtitle = "settings.pane.dictionary.subtitle"
    case settingsPaneRefineTitle = "settings.pane.refine.title"
    case settingsPaneRefineSubtitle = "settings.pane.refine.subtitle"
    case settingsAppLanguageLabel = "settings.app_language.label"
    case settingsInputLanguageLabel = "settings.input_language.label"
    case settingsTriggerLabel = "settings.trigger.label"
    case settingsTriggerFn = "settings.trigger.fn"
    case settingsTriggerAlternative = "settings.trigger.alternative"
    case settingsAlternativeKeyLabel = "settings.alternative_key.label"
    case settingsFnWarning = "settings.fn.warning"
    case settingsCaptureTitle = "settings.capture.title"
    case settingsCaptureSubtitle = "settings.capture.subtitle"
    case settingsCaptureRootLabel = "settings.capture_root.label"
    case settingsChooseAndMigrate = "settings.capture_root.choose_and_migrate"
    case settingsCaptureRootMigrated = "settings.capture_root.migrated"
    case settingsTermDictionaryTitle = "settings.term_dictionary.title"
    case settingsTermDictionarySubtitle = "settings.term_dictionary.subtitle"
    case settingsTermDictionaryAddEntry = "settings.term_dictionary.add_entry"
    case settingsTermDictionaryCanonicalPlaceholder = "settings.term_dictionary.canonical_placeholder"
    case settingsTermDictionaryAliasesPlaceholder = "settings.term_dictionary.aliases_placeholder"
    case settingsTermDictionaryAddButton = "settings.term_dictionary.add_button"
    case settingsTermDictionarySavedLocalOnly = "settings.term_dictionary.saved_local_only"
    case settingsTermDictionaryConfirmedTerms = "settings.term_dictionary.confirmed_terms"
    case settingsTermDictionarySavedCount = "settings.term_dictionary.saved_count"
    case settingsTermDictionaryNoConfirmed = "settings.term_dictionary.no_confirmed"
    case settingsTermDictionaryPendingCandidates = "settings.term_dictionary.pending_candidates"
    case settingsTermDictionaryPendingCount = "settings.term_dictionary.pending_count"
    case settingsTermDictionaryNoPending = "settings.term_dictionary.no_pending"
    case settingsRefineTitle = "settings.refine.title"
    case settingsRefineSubtitle = "settings.refine.subtitle"
    case settingsRefineSidebarSummary = "settings.refine.sidebar_summary"
    case settingsRefineConfigurationTitle = "settings.refine_configuration.title"
    case settingsRefineConfigurationSubtitle = "settings.refine_configuration.subtitle"
    case settingsEnableRefineTitle = "settings.enable_refine.title"
    case settingsEnableRefineSubtitle = "settings.enable_refine.subtitle"
    case settingsBaseURLLabel = "settings.base_url.label"
    case settingsBaseURLPlaceholder = "settings.base_url.placeholder"
    case settingsAPIKeyLabel = "settings.api_key.label"
    case settingsAPIKeyPlaceholder = "settings.api_key.placeholder"
    case settingsModelLabel = "settings.model.label"
    case settingsModelPlaceholder = "settings.model.placeholder"
    case settingsTestConnection = "settings.test_connection"
    case settingsTestingConnection = "settings.testing_connection"
    case settingsConnectionTitle = "settings.connection.title"
    case settingsConnectionSubtitle = "settings.connection.subtitle"
    case settingsOverviewTitle = "settings.overview.title"
    case settingsOverviewSubtitle = "settings.overview.subtitle"
    case settingsRefineWorkflowTitle = "settings.refine_workflow.title"
    case settingsRefineWorkflowSubtitle = "settings.refine_workflow.subtitle"
    case settingsRefineWorkflowStepCaptureTitle = "settings.refine_workflow.step_capture.title"
    case settingsRefineWorkflowStepCaptureBody = "settings.refine_workflow.step_capture.body"
    case settingsRefineWorkflowStepModelTitle = "settings.refine_workflow.step_model.title"
    case settingsRefineWorkflowStepModelBody = "settings.refine_workflow.step_model.body"
    case settingsRefineWorkflowStepFallbackTitle = "settings.refine_workflow.step_fallback.title"
    case settingsRefineWorkflowStepFallbackBody = "settings.refine_workflow.step_fallback.body"
    case settingsRefineBehaviorDirect = "settings.refine_behavior.direct"
    case settingsRefineBehaviorIncomplete = "settings.refine_behavior.incomplete"
    case settingsRefineBehaviorReady = "settings.refine_behavior.ready"
    case settingsHeaderTagline = "settings.header.tagline"
    case settingsRefineOn = "settings.refine.on"
    case settingsRefineOff = "settings.refine.off"
    case settingsOpenPanelMigrate = "settings.open_panel.migrate"
    case settingsOpenPanelMessage = "settings.open_panel.message"
    case settingsTermEntrySaved = "settings.term_dictionary.entry_saved"
    case settingsTermEntryRemoved = "settings.term_dictionary.entry_removed"
    case settingsTermCandidatePromoted = "settings.term_dictionary.candidate_promoted"
    case settingsTermCandidateDismissed = "settings.term_dictionary.candidate_dismissed"
    case settingsTestPassed = "settings.test_passed"
    case settingsRemove = "settings.remove"
    case settingsAliasLabel = "settings.alias.label"
    case settingsSourceLabel = "settings.source.label"
    case settingsConfirm = "settings.confirm"
    case settingsDismiss = "settings.dismiss"
    case settingsManualCorrection = "settings.manual_correction"
    case menuQuickControlsTitle = "menu.quick_controls.title"
    case menuQuickControlsSubtitle = "menu.quick_controls.subtitle"
    case menuRefineTitle = "menu.refine.title"
    case menuRefineSubtitle = "menu.refine.subtitle"
    case menuActionsTitle = "menu.actions.title"
    case menuActionsUnavailableSubtitle = "menu.actions.unavailable_subtitle"
    case menuActionsReadySubtitle = "menu.actions.ready_subtitle"
    case menuSettings = "menu.settings"
    case menuConfigureTrigger = "menu.configure_trigger"
    case menuVoiceInputForMac = "menu.voice_input_for_mac"
    case menuQuit = "menu.quit"
    case menuHeaderTagline = "menu.header.tagline"
    case overlayListeningTitle = "overlay.listening.title"
    case overlayThinkingTitle = "overlay.thinking.title"
    case overlayRefiningTitle = "overlay.refining.title"
    case overlayUnavailableTitle = "overlay.unavailable.title"
    case overlayListeningTranscript = "overlay.listening.transcript"
    case overlayProcessingTranscript = "overlay.processing.transcript"
    case overlayRefiningTranscript = "overlay.refining.transcript"
    case overlayMicrophoneUnavailable = "overlay.microphone_unavailable"
    case hotPathSecondaryActionRefine = "hot_path.secondary_action.refine"
    case hotPathSecondaryActionUndoRefine = "hot_path.secondary_action.undo_refine"
    case hotPathSecondaryActionConfirmUndoRefine = "hot_path.secondary_action.confirm_undo_refine"
    case hotPathSecondaryActionUndoSubmit = "hot_path.secondary_action.undo_submit"
    case hotPathUndoDirtyConfirmation = "hot_path.undo_dirty_confirmation"
    case hotPathComposeUnavailable = "hot_path.compose_unavailable"
    case hotPathSpeechTimedOut = "hot_path.speech_timed_out"
    case triggerNotStarted = "trigger.not_started"
    case triggerUnsupported = "trigger.unsupported"
    case triggerReadyFormat = "trigger.ready_format"
    case triggerUnavailableFormat = "trigger.unavailable_format"
    case triggerAccessibilityRequired = "trigger.accessibility_required"
    case triggerEventTapUnavailable = "trigger.event_tap_unavailable"
    case speechRecognitionUnavailable = "speech.unavailable"
    case refineInvalidBaseURL = "refine.invalid_base_url"
    case refineInvalidResponse = "refine.invalid_response"
    case refineRequestFailedFormat = "refine.request_failed_format"
    case refineConnectionIncomplete = "refine.connection.incomplete"
    case refineConnectionSampleText = "refine.connection.sample_text"
    case captureRootConflict = "capture_root.conflict"
    case captureRootSourceNotDirectory = "capture_root.source_not_directory"
    case captureRootDestinationNotDirectory = "capture_root.destination_not_directory"
    case termDictionaryCanonicalRequired = "term_dictionary.canonical_required"
    case termDictionaryMissingAlias = "term_dictionary.missing_alias"
}

enum AppLocalizer {
    private static let tableName = "Localizable"
    private static let fallbackLanguageCode = "en"
    private static let sharedState = AppLocalizerState()

    static func setCurrentAppLanguage(_ appLanguage: AppLanguageOption) {
        sharedState.set(appLanguage)
    }

    static func string(
        _ key: AppLocalizedStringKey,
        appLanguage: AppLanguageOption? = nil,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        let effectiveAppLanguage = appLanguage ?? sharedState.get()
        let resolvedLanguageCode = resolvedLanguageCode(
            for: effectiveAppLanguage,
            preferredLanguages: preferredLanguages
        )

        if let localized = localizedString(
            for: key,
            languageCode: resolvedLanguageCode
        ) {
            return localized
        }

        if resolvedLanguageCode != fallbackLanguageCode,
           let fallback = localizedString(for: key, languageCode: fallbackLanguageCode) {
            return fallback
        }

        return key.rawValue
    }

    static func formatted(
        _ key: AppLocalizedStringKey,
        appLanguage: AppLanguageOption? = nil,
        preferredLanguages: [String] = Locale.preferredLanguages,
        _ arguments: [CVarArg]
    ) -> String {
        let format = string(
            key,
            appLanguage: appLanguage,
            preferredLanguages: preferredLanguages
        )
        let localeIdentifier = resolvedLanguageCode(
            for: appLanguage ?? sharedState.get(),
            preferredLanguages: preferredLanguages
        )
        return String(
            format: format,
            locale: Locale(identifier: localeIdentifier),
            arguments: arguments
        )
    }

    static func resolvedLanguageCode(
        for appLanguage: AppLanguageOption,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        switch appLanguage {
        case .english:
            return fallbackLanguageCode

        case .simplifiedChinese:
            return "zh-hans"

        case .followSystem:
            for preferredLanguage in preferredLanguages {
                let normalized = preferredLanguage.lowercased()
                if normalized.hasPrefix("zh") {
                    return "zh-hans"
                }
                if normalized.hasPrefix("en") {
                    return fallbackLanguageCode
                }
            }

            return fallbackLanguageCode
        }
    }

    private static func localizedString(
        for key: AppLocalizedStringKey,
        languageCode: String
    ) -> String? {
        guard
            let bundlePath = Bundle.module.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: bundlePath)
        else {
            return nil
        }

        let value = bundle.localizedString(forKey: key.rawValue, value: nil, table: tableName)
        return value == key.rawValue ? nil : value
    }
}

private final class AppLocalizerState: @unchecked Sendable {
    private let lock = NSLock()
    private var appLanguage: AppLanguageOption = .followSystem

    func set(_ appLanguage: AppLanguageOption) {
        lock.lock()
        self.appLanguage = appLanguage
        lock.unlock()
    }

    func get() -> AppLanguageOption {
        lock.lock()
        let value = appLanguage
        lock.unlock()
        return value
    }
}
