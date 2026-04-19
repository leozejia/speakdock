import XCTest
@testable import SpeakDockMac

final class ComposeTargetIdentifierTests: XCTestCase {
    func testComposeTargetIdentifierIncludesExplicitAccessibilityIdentity() {
        let primary = ClipboardComposeTarget.composeTargetIdentifier(
            processIdentifier: 42,
            role: "AXTextField",
            identifier: "primary",
            description: "primary",
            windowTitle: "SpeakDock Test Host A",
            title: "",
            structuralPath: "0.1.0"
        )
        let secondary = ClipboardComposeTarget.composeTargetIdentifier(
            processIdentifier: 42,
            role: "AXTextField",
            identifier: "secondary",
            description: "secondary",
            windowTitle: "SpeakDock Test Host B",
            title: "",
            structuralPath: "0.1.1"
        )

        XCTAssertNotEqual(primary, secondary)
        XCTAssertEqual(primary, "42:AXTextField:primary:primary:SpeakDock Test Host A::0.1.0")
        XCTAssertEqual(secondary, "42:AXTextField:secondary:secondary:SpeakDock Test Host B::0.1.1")
    }
}
