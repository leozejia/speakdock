import XCTest
import SpeakDockCore
@testable import SpeakDockMac

@MainActor
final class TriggerControllerLifecycleTests: XCTestCase {
    func testInitDoesNotStartAdapterUntilStartIsCalled() {
        let defaults = makeDefaults()
        let factory = TriggerAdapterFactorySpy()
        let store = SettingsStore(defaults: defaults, migrator: CaptureRootMigrator())

        let controller = TriggerController(
            settingsStore: store,
            adapterFactory: factory.makeAdapter
        )

        XCTAssertTrue(factory.adapters.isEmpty)
        XCTAssertEqual(controller.availability, .unavailable(label: "Trigger Not Started"))

        controller.start()

        XCTAssertEqual(factory.adapters.count, 1)
        XCTAssertEqual(factory.adapters[0].startCount, 1)
    }

    func testSettingsChangeAfterStartReloadsAdapter() {
        let defaults = makeDefaults()
        let factory = TriggerAdapterFactorySpy()
        let store = SettingsStore(defaults: defaults, migrator: CaptureRootMigrator())
        let controller = TriggerController(
            settingsStore: store,
            adapterFactory: factory.makeAdapter
        )

        controller.start()
        store.settings.triggerSelection = .alternative("right-option")

        XCTAssertEqual(factory.adapters.count, 2)
        XCTAssertEqual(factory.adapters[0].stopCount, 1)
        XCTAssertEqual(factory.adapters[1].startCount, 1)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "speakdock-trigger-lifecycle-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
private final class TriggerAdapterFactorySpy {
    private(set) var adapters: [TriggerAdapterSpy] = []

    func makeAdapter(triggerKey: ModifierTriggerKey) -> any TriggerAdapter {
        let adapter = TriggerAdapterSpy()
        adapters.append(adapter)
        return adapter
    }
}

private final class TriggerAdapterSpy: TriggerAdapter {
    var onInputEvent: ((TriggerInputEvent) -> Void)?
    var onPressStateChanged: ((Bool) -> Void)?
    var onAvailabilityChanged: ((TriggerAvailability) -> Void)?

    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() {
        startCount += 1
        onAvailabilityChanged?(.available(label: "Spy Ready"))
    }

    func stop() {
        stopCount += 1
    }
}
