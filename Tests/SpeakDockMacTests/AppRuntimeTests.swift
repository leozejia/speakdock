import AppKit
import XCTest
@testable import SpeakDockMac

@MainActor
final class AppRuntimeTests: XCTestCase {
    func testConfigureInitialVisibilitySkipsPolicyUpdateWhenApplicationUnavailable() {
        defer { AppRuntime.resetTestingHooks() }

        var appliedPolicy = false
        var activated = false

        AppRuntime.installTestingHooks(
            applicationResolver: { nil },
            activationPolicyApplier: { _, _ in
                appliedPolicy = true
            },
            applicationActivator: { _ in
                activated = true
            }
        )

        AppRuntime.configureInitialVisibility()

        XCTAssertFalse(appliedPolicy)
        XCTAssertFalse(activated)
    }

    func testConfigureInitialVisibilityAppliesRegularPolicyWithoutActivation() {
        defer { AppRuntime.resetTestingHooks() }

        let application = NSApplication.shared
        var appliedPolicy: NSApplication.ActivationPolicy?
        var activated = false

        AppRuntime.installTestingHooks(
            applicationResolver: { application },
            activationPolicyApplier: { _, policy in
                appliedPolicy = policy
            },
            applicationActivator: { _ in
                activated = true
            }
        )

        AppRuntime.configureInitialVisibility()

        XCTAssertEqual(appliedPolicy, .regular)
        XCTAssertFalse(activated)
    }
}
