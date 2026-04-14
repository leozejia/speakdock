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

    func testManualCorrectionCreatesCandidateWithoutMutatingConfirmedDictionary() {
        let dictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "SpeakDock", aliases: ["speak dock"]),
        ])
        let extractor = TermDictionaryCandidateExtractor()

        let candidates = extractor.candidates(
            generatedText: "我们继续做 project adults 的输入体验",
            correctedText: "我们继续做 Project Atlas 的输入体验"
        )

        XCTAssertEqual(
            candidates,
            [
                TermDictionaryCandidate(
                    canonicalTerm: "Project Atlas",
                    alias: "project adults",
                    source: .manualCorrection
                ),
            ]
        )
        XCTAssertEqual(
            dictionary,
            TermDictionary(entries: [
                TermDictionaryEntry(canonicalTerm: "SpeakDock", aliases: ["speak dock"]),
            ])
        )
    }
}
