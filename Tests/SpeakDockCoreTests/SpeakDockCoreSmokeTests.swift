import Testing
@testable import SpeakDockCore

@Test
func coreModuleIsLinkable() {
    #expect(String(describing: SpeakDockCoreModule.self) == "SpeakDockCoreModule")
}
