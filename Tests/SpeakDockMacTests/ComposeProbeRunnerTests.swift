import XCTest
@testable import SpeakDockMac

final class ComposeProbeRunnerTests: XCTestCase {
    func testComposeProbeVerdictMapsAXAvailabilityStatesToStableTokens() {
        XCTAssertEqual(
            ClipboardComposeTarget.composeProbeVerdict(for: .available(targetID: "target")),
            .available
        )
        XCTAssertEqual(
            ClipboardComposeTarget.composeProbeVerdict(for: .noTarget),
            .noTarget
        )
        XCTAssertEqual(
            ClipboardComposeTarget.composeProbeVerdict(for: .unavailable(reason: "missing")),
            .unavailable
        )
    }

    func testComposeProbeVerdictAccumulationPrefersObservedAXSuccessOverUnavailableTicks() {
        let unavailable = ClipboardComposeTarget.accumulatedComposeProbeVerdict(
            nil,
            availability: .unavailable(reason: "missing")
        )
        let noTarget = ClipboardComposeTarget.accumulatedComposeProbeVerdict(
            unavailable,
            availability: .noTarget
        )
        let available = ClipboardComposeTarget.accumulatedComposeProbeVerdict(
            noTarget,
            availability: .available(targetID: "target")
        )

        XCTAssertEqual(unavailable, .unavailable)
        XCTAssertEqual(noTarget, .noTarget)
        XCTAssertEqual(available, .available)
    }

    func testComposeProbeRunnerParsesExplicitResultFileArgument() {
        let url = ComposeProbeRunner.probeResultFileURL(
            arguments: ["SpeakDock", "--probe-compose-result-file", "/tmp/probe-result.txt"]
        )

        XCTAssertEqual(url?.path, "/tmp/probe-result.txt")
    }

    func testComposeProbeRunnerBuildsMinimalResultContents() {
        XCTAssertEqual(
            ComposeProbeRunner.probeResultContents(verdict: .noTarget),
            "no-target\n"
        )
    }
}
