import XCTest
@testable import SpeakDockMac

final class ComposeTargetIdentifierTests: XCTestCase {
    func testComposeTargetIdentifierUsesStableAccessibilityIdentity() {
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
        XCTAssertEqual(primary, "42:AXTextField:primary:SpeakDock Test Host A:0.1.0")
        XCTAssertEqual(secondary, "42:AXTextField:secondary:SpeakDock Test Host B:0.1.1")
    }

    func testComposeTargetIdentifierIgnoresMutableDescriptionAndTitle() {
        let original = ClipboardComposeTarget.composeTargetIdentifier(
            processIdentifier: 42,
            role: "AXTextField",
            identifier: "",
            description: "before edit",
            windowTitle: "SpeakDock Test Host A",
            title: "before edit",
            structuralPath: "0.1.0"
        )
        let afterEdit = ClipboardComposeTarget.composeTargetIdentifier(
            processIdentifier: 42,
            role: "AXTextField",
            identifier: "",
            description: "after edit",
            windowTitle: "SpeakDock Test Host A",
            title: "after edit",
            structuralPath: "0.1.0"
        )

        XCTAssertEqual(original, afterEdit)
    }
}
