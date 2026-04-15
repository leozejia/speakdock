import SpeakDockCore

enum SettingsPane: String, CaseIterable, Sendable {
    case general
    case dictionary
    case refine

    static let defaultPane: SettingsPane = .general

    func title(appLanguage: AppLanguageOption? = nil) -> String {
        AppLocalizer.string(titleKey, appLanguage: appLanguage)
    }

    func subtitle(appLanguage: AppLanguageOption? = nil) -> String {
        AppLocalizer.string(subtitleKey, appLanguage: appLanguage)
    }

    var symbolName: String {
        switch self {
        case .general:
            "slider.horizontal.3"
        case .dictionary:
            "text.badge.star"
        case .refine:
            "sparkles"
        }
    }

    private var titleKey: AppLocalizedStringKey {
        switch self {
        case .general:
            .settingsPaneGeneralTitle
        case .dictionary:
            .settingsPaneDictionaryTitle
        case .refine:
            .settingsPaneRefineTitle
        }
    }

    private var subtitleKey: AppLocalizedStringKey {
        switch self {
        case .general:
            .settingsPaneGeneralSubtitle
        case .dictionary:
            .settingsPaneDictionarySubtitle
        case .refine:
            .settingsPaneRefineSubtitle
        }
    }
}
