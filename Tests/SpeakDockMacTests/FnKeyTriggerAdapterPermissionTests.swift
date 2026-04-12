import XCTest
import SpeakDockCore
@testable import SpeakDockMac

@MainActor
final class FnKeyTriggerAdapterPermissionTests: XCTestCase {
    func testRequestsListenEventAccessBeforeReportingUnavailable() {
        let permissionChecker = StubEventTapPermissionChecker(
            preflightResult: false,
            requestResult: false
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

        XCTAssertEqual(permissionChecker.requestCount, 1)
        XCTAssertEqual(
            reportedAvailability,
            .unavailable(label: "Fn Unavailable: Input Monitoring Required")
        )
    }
}

private final class StubEventTapPermissionChecker: EventTapPermissionChecking {
    let preflightResult: Bool
    let requestResult: Bool
    private(set) var requestCount = 0

    init(preflightResult: Bool, requestResult: Bool) {
        self.preflightResult = preflightResult
        self.requestResult = requestResult
    }

    func preflightListenEventAccess() -> Bool {
        preflightResult
    }

    func requestListenEventAccess() -> Bool {
        requestCount += 1
        return requestResult
    }
}
