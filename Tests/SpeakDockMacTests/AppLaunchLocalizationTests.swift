import XCTest
import SpeakDockCore
@testable import SpeakDockMac

final class AppLaunchLocalizationTests: XCTestCase {
    func testBootstrapOverridesAppleLanguagesForSimplifiedChinese() throws {
        let suiteName = "speakdock-launch-localization-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(
            try makeSettingsData(appLanguage: .simplifiedChinese),
            forKey: AppLaunchLocalization.appSettingsDefaultsKey
        )

        AppLaunchLocalization.bootstrap(defaults: defaults)

        XCTAssertEqual(
            defaults.stringArray(forKey: AppLaunchLocalization.appleLanguagesDefaultsKey),
            ["zh-Hans"]
        )
    }

    func testBootstrapOverridesAppleLanguagesForEnglish() throws {
        let suiteName = "speakdock-launch-localization-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(
            try makeSettingsData(appLanguage: .english),
            forKey: AppLaunchLocalization.appSettingsDefaultsKey
        )

        AppLaunchLocalization.bootstrap(defaults: defaults)

        XCTAssertEqual(
            defaults.stringArray(forKey: AppLaunchLocalization.appleLanguagesDefaultsKey),
            ["en"]
        )
    }

    func testBootstrapClearsAppleLanguagesOverrideWhenFollowingSystem() throws {
        let suiteName = "speakdock-launch-localization-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(["zh-Hans"], forKey: AppLaunchLocalization.appleLanguagesDefaultsKey)
        defaults.set(
            try makeSettingsData(appLanguage: .followSystem),
            forKey: AppLaunchLocalization.appSettingsDefaultsKey
        )

        AppLaunchLocalization.bootstrap(defaults: defaults)

        let persistentDomain = defaults.persistentDomain(forName: suiteName)
        XCTAssertNil(persistentDomain?[AppLaunchLocalization.appleLanguagesDefaultsKey])
    }

    private func makeSettingsData(appLanguage: AppLanguageOption) throws -> Data {
        try JSONEncoder().encode(
            AppSettings(
                appLanguage: appLanguage,
                inputLanguage: .simplifiedChinese,
                captureRootPath: "/tmp",
                triggerSelection: .fn,
                refineEnabled: false,
                refineBaseURL: "",
                refineAPIKey: "",
                refineModel: ""
            )
        )
    }
}
