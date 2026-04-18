import AppKit
import XCTest
@testable import SpeakDockMac

@MainActor
final class AppRuntimeTests: XCTestCase {
    private final class RunningApplicationSpy {
        var activated = false
        let processIdentifier: pid_t

        init(processIdentifier: pid_t) {
            self.processIdentifier = processIdentifier
        }

        func activate() {
            activated = true
        }
    }

    func testConfigureInitialVisibilitySkipsPolicyUpdateWhenApplicationUnavailable() {
        defer { AppRuntime.resetTestingHooks() }

        var appliedPolicy = false
        var activated = false

        AppRuntime.installTestingHooks(
            applicationIconLoader: { nil },
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
            applicationIconLoader: { nil },
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

    func testEnsureSingleInstanceForNormalModeActivatesExistingInstanceAndRejectsDuplicateLaunch() {
        defer { AppRuntime.resetTestingHooks() }

        let currentProcessID = ProcessInfo.processInfo.processIdentifier
        let existingInstance = RunningApplicationSpy(processIdentifier: 42)
        let duplicateInstance = RunningApplicationSpy(processIdentifier: currentProcessID)
        var terminateCalled = false

        AppRuntime.installSingleInstanceTestingHooks(
            currentProcessIdentifier: { currentProcessID },
            runningApplicationsResolver: { _ in
                [
                    AppRuntime.RunningApplicationRecord(
                        processIdentifier: existingInstance.processIdentifier,
                        activate: { existingInstance.activate() }
                    ),
                    AppRuntime.RunningApplicationRecord(
                        processIdentifier: duplicateInstance.processIdentifier,
                        activate: { duplicateInstance.activate() }
                    ),
                ]
            },
            duplicateTerminator: {
                terminateCalled = true
            }
        )

        let shouldContinue = AppRuntime.ensureSingleInstance(mode: .normal)

        XCTAssertFalse(shouldContinue)
        XCTAssertTrue(existingInstance.activated)
        XCTAssertFalse(duplicateInstance.activated)
        XCTAssertTrue(terminateCalled)
    }

    func testEnsureSingleInstanceAllowsMultipleProcessesForSmokeAndProbeModes() {
        defer { AppRuntime.resetTestingHooks() }

        let currentProcessID = ProcessInfo.processInfo.processIdentifier
        let existingInstance = RunningApplicationSpy(processIdentifier: 42)
        let duplicateInstance = RunningApplicationSpy(processIdentifier: currentProcessID)
        var terminateCalled = false

        AppRuntime.installSingleInstanceTestingHooks(
            currentProcessIdentifier: { currentProcessID },
            runningApplicationsResolver: { _ in
                [
                    AppRuntime.RunningApplicationRecord(
                        processIdentifier: existingInstance.processIdentifier,
                        activate: { existingInstance.activate() }
                    ),
                    AppRuntime.RunningApplicationRecord(
                        processIdentifier: duplicateInstance.processIdentifier,
                        activate: { duplicateInstance.activate() }
                    ),
                ]
            },
            duplicateTerminator: {
                terminateCalled = true
            }
        )

        XCTAssertTrue(AppRuntime.ensureSingleInstance(mode: .composeProbe))
        XCTAssertTrue(AppRuntime.ensureSingleInstance(mode: .smokeHotPath))
        XCTAssertTrue(AppRuntime.ensureSingleInstance(mode: .smokeASRCorrection))
        XCTAssertTrue(AppRuntime.ensureSingleInstance(mode: .smokeRefine))
        XCTAssertTrue(AppRuntime.ensureSingleInstance(mode: .smokeTermLearning))
        XCTAssertFalse(existingInstance.activated)
        XCTAssertFalse(terminateCalled)
    }
}
