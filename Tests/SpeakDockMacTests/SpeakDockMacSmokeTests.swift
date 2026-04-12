import Testing
@testable import SpeakDockMac

@Test
func appModuleIsLinkable() {
    #expect(String(describing: SpeakDockApp.self) == "SpeakDockApp")
}
