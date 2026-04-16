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

    func testManualCorrectionIgnoresSentenceLevelRewrite() {
        let extractor = TermDictionaryCandidateExtractor()

        let candidates = extractor.candidates(
            generatedText: "今天先讨论项目排期",
            correctedText: "我们今天先讨论一下项目排期"
        )

        XCTAssertEqual(candidates, [])
    }

    func testNormalizerCanReadCurrentDictionaryFromProviderWithoutRecreation() {
        var currentDictionary = TermDictionary.empty
        let normalizer = CleanNormalizer(
            termDictionaryProvider: { currentDictionary }
        )

        XCTAssertEqual(
            normalizer.normalize("project atlas 进入下一步"),
            "project atlas 进入下一步"
        )

        currentDictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "Project Atlas", aliases: ["project atlas"]),
        ])

        XCTAssertEqual(
            normalizer.normalize("project atlas 进入下一步"),
            "Project Atlas 进入下一步"
        )
    }

    func testConfirmedAliasesDoNotRewriteInsideLongerASCIIWords() {
        let dictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "Project Atlas", aliases: ["atlas"]),
        ])

        XCTAssertEqual(
            dictionary.applying(to: "atlassian atlas atlas2"),
            "atlassian Project Atlas atlas2"
        )
    }

    func testConfirmedAliasesMatchCaseInsensitively() {
        let dictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "Project Atlas", aliases: ["project atlas"]),
        ])

        XCTAssertEqual(
            dictionary.applying(to: "PROJECT ATLAS project atlas"),
            "Project Atlas Project Atlas"
        )
    }

    func testLongerAliasWinsAcrossDifferentDictionaryEntries() {
        let dictionary = TermDictionary(entries: [
            TermDictionaryEntry(canonicalTerm: "Atlas Tool", aliases: ["atlas"]),
            TermDictionaryEntry(canonicalTerm: "Project Atlas", aliases: ["project atlas"]),
        ])

        XCTAssertEqual(
            dictionary.applying(to: "project atlas"),
            "Project Atlas"
        )
    }
}
