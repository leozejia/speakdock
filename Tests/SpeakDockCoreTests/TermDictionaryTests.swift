import XCTest
@testable import SpeakDockCore

final class TermDictionaryTests: XCTestCase {
    func testConfirmedAliasesAreAppliedBeforeFinalCleanTextIsSubmitted() {
        let dictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "Project Atlas", aliases: ["project atlas", "项目 atlas"]),
            TermDictionaryEntry(canonicalTerm: "SpeakDock", aliases: ["speak dock"]),
        ])
        let normalizer = CleanNormalizer(termDictionary: dictionary)

        XCTAssertEqual(
            normalizer.normalize("嗯  project atlas 里面的 speak dock，，不错"),
            "Project Atlas 里面的 SpeakDock，不错"
        )
    }
}
