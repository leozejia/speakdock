import XCTest
import SpeakDockCore
@testable import SpeakDockMac

@MainActor
final class FnKeyTriggerAdapterPermissionTests: XCTestCase {
    func testRequestsAccessibilityBeforeReportingUnavailable() {
        let permissionChecker = StubEventTapPermissionChecker(
            trustedWithoutPrompt: false,
            trustedWithPrompt: false
        )
        let adapter = FnKeyTriggerAdapter(
            triggerKey: .fn,
            permissionChecker: permissionChecker
        )
        var reportedAvailability: TriggerAvailability?
        adapter.onAvailabilityChanged = { availability in
            reportedAvailability = availability
        }

        adapter.start()

        XCTAssertEqual(permissionChecker.promptCount, 1)
        XCTAssertEqual(
            reportedAvailability,
            .unavailable(label: "Fn Unavailable: Accessibility Required")
        )
    }
}

private final class StubEventTapPermissionChecker: EventTapPermissionChecking {
    let trustedWithoutPrompt: Bool
    let trustedWithPrompt: Bool
    private(set) var promptCount = 0

    init(trustedWithoutPrompt: Bool, trustedWithPrompt: Bool) {
        self.trustedWithoutPrompt = trustedWithoutPrompt
        self.trustedWithPrompt = trustedWithPrompt
    }

    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        if prompt {
            promptCount += 1
            return trustedWithPrompt
        }
        return trustedWithoutPrompt
    }
}
