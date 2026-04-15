import XCTest
import SpeakDockCore
@testable import SpeakDockMac

@MainActor
final class SettingsStoreTests: XCTestCase {
    private let fileManager = FileManager.default

    func testDefaultsMatchArchitecture() {
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )

        XCTAssertEqual(store.settings.appLanguage, .followSystem)
        XCTAssertEqual(store.settings.inputLanguage, .simplifiedChinese)
        XCTAssertEqual(store.settings.triggerSelection, .fn)
        XCTAssertTrue(store.settings.showDockIcon)
        XCTAssertFalse(store.settings.refineEnabled)
        XCTAssertEqual(
            store.settings.captureRootPath,
            SettingsStore.defaultCaptureRootURL.path
        )
    }

    func testSettingsPersistAndReloadIncludingAlternativeTriggerAndEmptyAPIKey() throws {
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )

        store.settings.appLanguage = .english
        store.settings.inputLanguage = .english
        store.settings.triggerSelection = .alternative("right-command")
        store.settings.showDockIcon = false
        store.settings.refineEnabled = true
        store.settings.refineBaseURL = "https://example.com/v1"
        store.settings.refineAPIKey = "secret"
        store.settings.refineModel = "gpt-4.1-mini"
        try store.save()

        store.settings.refineAPIKey = ""
        try store.save()

        let reloadedStore = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )

        XCTAssertEqual(reloadedStore.settings.appLanguage, .english)
        XCTAssertEqual(reloadedStore.settings.inputLanguage, .english)
        XCTAssertEqual(reloadedStore.settings.triggerSelection, .alternative("right-command"))
        XCTAssertFalse(reloadedStore.settings.showDockIcon)
        XCTAssertTrue(reloadedStore.settings.refineEnabled)
        XCTAssertEqual(reloadedStore.settings.refineBaseURL, "https://example.com/v1")
        XCTAssertEqual(reloadedStore.settings.refineAPIKey, "")
        XCTAssertEqual(reloadedStore.settings.refineModel, "gpt-4.1-mini")
    }

    func testLegacyPersistedSettingsReloadIntoSplitLanguageModel() {
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyPayload = """
        {
          "languageCode": "ko-KR",
          "captureRootPath": "/tmp",
          "triggerSelection": {
            "kind": "fn"
          },
          "showDockIcon": true,
          "refineEnabled": false,
          "refineBaseURL": "",
          "refineAPIKey": "",
          "refineModel": ""
        }
        """.data(using: .utf8)!
        defaults.set(legacyPayload, forKey: "appSettings")

        let store = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )

        XCTAssertEqual(store.settings.appLanguage, .followSystem)
        XCTAssertEqual(store.settings.inputLanguage, .korean)
    }

    func testMultipleSettingsObserversReceiveChanges() {
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )

        var firstReceived: AppSettings?
        var secondReceived: AppSettings?

        _ = store.addSettingsObserver { settings in
            firstReceived = settings
        }
        _ = store.addSettingsObserver { settings in
            secondReceived = settings
        }

        store.settings.showDockIcon = false

        XCTAssertEqual(firstReceived?.showDockIcon, false)
        XCTAssertEqual(secondReceived?.showDockIcon, false)
    }

    func testCaptureRootMigrationMovesExistingFilesAndPersistsNewPath() throws {
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTemporaryDirectory(named: "capture-source")
        let destinationRoot = try makeTemporaryDirectory(named: "capture-destination")
        let sourceFile = sourceRoot.appendingPathComponent("note.md")
        try "hello".write(to: sourceFile, atomically: true, encoding: .utf8)

        let store = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )
        store.settings.captureRootPath = sourceRoot.path

        try store.updateCaptureRoot(to: destinationRoot)

        XCTAssertEqual(store.settings.captureRootPath, destinationRoot.path)
        XCTAssertTrue(fileManager.fileExists(atPath: destinationRoot.appendingPathComponent("note.md").path))
        XCTAssertFalse(fileManager.fileExists(atPath: sourceFile.path))

        let reloadedStore = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )
        XCTAssertEqual(reloadedStore.settings.captureRootPath, destinationRoot.path)
    }

    func testCaptureRootMigrationStopsOnDestinationConflict() throws {
        let suiteName = "speakdock-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTemporaryDirectory(named: "capture-source")
        let destinationRoot = try makeTemporaryDirectory(named: "capture-destination")

        let sourceFile = sourceRoot.appendingPathComponent("note.md")
        let conflictingFile = destinationRoot.appendingPathComponent("note.md")
        try "source".write(to: sourceFile, atomically: true, encoding: .utf8)
        try "destination".write(to: conflictingFile, atomically: true, encoding: .utf8)

        let store = SettingsStore(
            defaults: defaults,
            migrator: CaptureRootMigrator()
        )
        store.settings.captureRootPath = sourceRoot.path

        XCTAssertThrowsError(try store.updateCaptureRoot(to: destinationRoot)) { error in
            XCTAssertEqual(
                error as? CaptureRootMigrationError,
                .destinationConflict("note.md")
            )
        }

        XCTAssertEqual(store.settings.captureRootPath, sourceRoot.path)
        XCTAssertTrue(fileManager.fileExists(atPath: sourceFile.path))
        XCTAssertTrue(fileManager.fileExists(atPath: conflictingFile.path))
    }

    private func makeTemporaryDirectory(named prefix: String) throws -> URL {
        let url = fileManager.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
