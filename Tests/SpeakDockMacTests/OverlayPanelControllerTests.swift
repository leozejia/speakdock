import XCTest
@testable import SpeakDockMac

@MainActor
final class OverlayPanelControllerTests: XCTestCase {
    func testInitDoesNotCreateAppKitOverlayEagerly() {
        _ = OverlayPanelController()
    }
}
