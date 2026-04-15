import Foundation
import Observation
import SpeakDockCore

@MainActor
@Observable
final class SettingsStore {
    static let defaultCaptureRootURL: URL = {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop", isDirectory: true)
    }()

    private enum Keys {
        static let appSettings = "appSettings"
    }

    var settings: AppSettings {
        didSet {
            guard isReady else {
                return
            }

            try? save()
            notifySettingsObservers()
        }
    }

    private let defaults: UserDefaults
    private let migrator: CaptureRootMigrating
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var isReady = false
    private var settingsObservers: [UUID: @MainActor (AppSettings) -> Void] = [:]

    init(
        defaults: UserDefaults = .standard,
        migrator: CaptureRootMigrating = CaptureRootMigrator()
    ) {
        self.defaults = defaults
        self.migrator = migrator
        self.settings = Self.loadSettings(
            from: defaults,
            using: JSONDecoder(),
            defaultCaptureRootURL: Self.defaultCaptureRootURL
        )
        self.isReady = true
    }

    func save() throws {
        let data = try encoder.encode(settings)
        defaults.set(data, forKey: Keys.appSettings)
    }

    func reload() {
        settings = Self.loadSettings(
            from: defaults,
            using: decoder,
            defaultCaptureRootURL: Self.defaultCaptureRootURL
        )
    }

    @discardableResult
    func addSettingsObserver(_ observer: @escaping @MainActor (AppSettings) -> Void) -> UUID {
        let identifier = UUID()
        settingsObservers[identifier] = observer
        return identifier
    }

    func removeSettingsObserver(_ identifier: UUID) {
        settingsObservers.removeValue(forKey: identifier)
    }

    func updateCaptureRoot(to newRootURL: URL) throws {
        let currentRootURL = URL(fileURLWithPath: settings.captureRootPath, isDirectory: true)
        try migrator.migrate(from: currentRootURL, to: newRootURL)
        settings.captureRootPath = newRootURL.path
        try save()
    }

    private static func loadSettings(
        from defaults: UserDefaults,
        using decoder: JSONDecoder,
        defaultCaptureRootURL: URL
    ) -> AppSettings {
        guard
            let data = defaults.data(forKey: Keys.appSettings),
            let settings = try? decoder.decode(AppSettings.self, from: data)
        else {
            return AppSettings(
                languageCode: LanguageOption.defaultOption.rawValue,
                captureRootPath: defaultCaptureRootURL.path,
                triggerSelection: .fn,
                showDockIcon: true,
                refineEnabled: false,
                refineBaseURL: "",
                refineAPIKey: "",
                refineModel: ""
            )
        }

        return settings
    }

    private func notifySettingsObservers() {
        for observer in settingsObservers.values {
            observer(settings)
        }
    }
}
