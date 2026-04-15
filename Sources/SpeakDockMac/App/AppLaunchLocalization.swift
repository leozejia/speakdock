import Foundation
import SpeakDockCore

enum AppLaunchLocalization {
    static let appSettingsDefaultsKey = "appSettings"
    static let appleLanguagesDefaultsKey = "AppleLanguages"

    static func bootstrap(defaults: UserDefaults = .standard) {
        let appLanguage = storedAppLanguage(defaults: defaults)

        switch appLanguage {
        case .followSystem:
            defaults.removeObject(forKey: appleLanguagesDefaultsKey)

        case .english, .simplifiedChinese:
            defaults.set([appLanguage.rawValue], forKey: appleLanguagesDefaultsKey)
        }
    }

    static func storedAppLanguage(defaults: UserDefaults = .standard) -> AppLanguageOption {
        guard
            let data = defaults.data(forKey: appSettingsDefaultsKey),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .followSystem
        }

        return settings.appLanguage
    }
}
