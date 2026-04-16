import Foundation

public enum TermDictionaryCandidateSource: String, Codable, Sendable {
    case manualCorrection
}

public struct TermDictionaryCandidate: Equatable, Codable, Sendable {
    public var canonicalTerm: String
    public var alias: String
    public var source: TermDictionaryCandidateSource

    public init(
        canonicalTerm: String,
        alias: String,
        source: TermDictionaryCandidateSource
    ) {
        self.canonicalTerm = canonicalTerm
        self.alias = alias
        self.source = source
    }
}

public struct TermDictionaryCandidateExtractor: Sendable {
    private let maximumCandidateCharacters: Int
    private let maximumWhitespaceSeparatedWords: Int
    private let maximumUnspacedCJKCharacters: Int

    public init(
        maximumCandidateCharacters: Int = 40,
        maximumWhitespaceSeparatedWords: Int = 4,
        maximumUnspacedCJKCharacters: Int = 8
    ) {
        self.maximumCandidateCharacters = maximumCandidateCharacters
        self.maximumWhitespaceSeparatedWords = maximumWhitespaceSeparatedWords
        self.maximumUnspacedCJKCharacters = maximumUnspacedCJKCharacters
    }

    public func candidates(
        generatedText: String,
        correctedText: String
    ) -> [TermDictionaryCandidate] {
        let generated = generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let corrected = correctedText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard generated != corrected else {
            return []
        }

        let changed = changedSegment(generatedText: generated, correctedText: corrected)
        let alias = normalizeCandidateText(changed.alias)
        let canonicalTerm = normalizeCandidateText(changed.canonicalTerm)

        guard isValidCandidate(alias: alias, canonicalTerm: canonicalTerm) else {
            return []
        }

        return [
            TermDictionaryCandidate(
                canonicalTerm: canonicalTerm,
                alias: alias,
                source: .manualCorrection
            ),
        ]
    }

    private func changedSegment(
        generatedText: String,
        correctedText: String
    ) -> (alias: String, canonicalTerm: String) {
        var generatedPrefix = generatedText.startIndex
        var correctedPrefix = correctedText.startIndex

        while generatedPrefix < generatedText.endIndex,
              correctedPrefix < correctedText.endIndex,
              generatedText[generatedPrefix] == correctedText[correctedPrefix] {
            generatedText.formIndex(after: &generatedPrefix)
            correctedText.formIndex(after: &correctedPrefix)
        }

        var generatedSuffix = generatedText.endIndex
        var correctedSuffix = correctedText.endIndex

        while generatedSuffix > generatedPrefix,
              correctedSuffix > correctedPrefix {
            let previousGenerated = generatedText.index(before: generatedSuffix)
            let previousCorrected = correctedText.index(before: correctedSuffix)

            guard generatedText[previousGenerated] == correctedText[previousCorrected] else {
                break
            }

            generatedSuffix = previousGenerated
            correctedSuffix = previousCorrected
        }

        let expandedBounds = expandedTermBounds(
            generatedText: generatedText,
            correctedText: correctedText,
            generatedStart: generatedPrefix,
            generatedEnd: generatedSuffix,
            correctedStart: correctedPrefix,
            correctedEnd: correctedSuffix
        )

        return (
            alias: String(generatedText[expandedBounds.generatedStart..<expandedBounds.generatedEnd]),
            canonicalTerm: String(correctedText[expandedBounds.correctedStart..<expandedBounds.correctedEnd])
        )
    }

    private func normalizeCandidateText(_ text: String) -> String {
        text.trimmingCharacters(in: boundaryTrimCharacters)
    }

    private func isValidCandidate(alias: String, canonicalTerm: String) -> Bool {
        guard !alias.isEmpty,
              !canonicalTerm.isEmpty,
              alias != canonicalTerm,
              alias.count <= maximumCandidateCharacters,
              canonicalTerm.count <= maximumCandidateCharacters,
              !alias.contains(where: \.isNewline),
              !canonicalTerm.contains(where: \.isNewline),
              isShortPhrase(alias),
              isShortPhrase(canonicalTerm),
              containsMeaningfulCharacter(alias),
              containsMeaningfulCharacter(canonicalTerm) else {
            return false
        }

        return true
    }

    private func isShortPhrase(_ text: String) -> Bool {
        let wordCount = text.split(whereSeparator: \.isWhitespace).count
        if wordCount > 1 {
            return wordCount <= maximumWhitespaceSeparatedWords
        }

        guard containsCJKCharacter(text) else {
            return true
        }

        return text.count <= maximumUnspacedCJKCharacters
    }

    private func containsMeaningfulCharacter(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar)
        }
    }

    private func containsCJKCharacter(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x3400...0x4DBF).contains(scalar.value)
                || (0x4E00...0x9FFF).contains(scalar.value)
                || (0xF900...0xFAFF).contains(scalar.value)
        }
    }

    private func expandedTermBounds(
        generatedText: String,
        correctedText: String,
        generatedStart: String.Index,
        generatedEnd: String.Index,
        correctedStart: String.Index,
        correctedEnd: String.Index
    ) -> (
        generatedStart: String.Index,
        generatedEnd: String.Index,
        correctedStart: String.Index,
        correctedEnd: String.Index
    ) {
        var generatedStart = generatedStart
        var generatedEnd = generatedEnd
        var correctedStart = correctedStart
        var correctedEnd = correctedEnd

        while generatedStart > generatedText.startIndex,
              correctedStart > correctedText.startIndex {
            let previousGenerated = generatedText.index(before: generatedStart)
            let previousCorrected = correctedText.index(before: correctedStart)

            guard isTermContinuation(generatedText[previousGenerated]),
                  isTermContinuation(correctedText[previousCorrected]) else {
                break
            }

            generatedStart = previousGenerated
            correctedStart = previousCorrected
        }

        while generatedEnd < generatedText.endIndex,
              correctedEnd < correctedText.endIndex,
              isTermContinuation(generatedText[generatedEnd]),
              isTermContinuation(correctedText[correctedEnd]) {
            generatedText.formIndex(after: &generatedEnd)
            correctedText.formIndex(after: &correctedEnd)
        }

        return (
            generatedStart: generatedStart,
            generatedEnd: generatedEnd,
            correctedStart: correctedStart,
            correctedEnd: correctedEnd
        )
    }

    private func isTermContinuation(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar)
                || scalar == "-"
                || scalar == "_"
                || scalar == "."
        }
    }

    private var boundaryTrimCharacters: CharacterSet {
        CharacterSet.whitespacesAndNewlines.union(
            CharacterSet(charactersIn: "，,。.!！？?\"'“”‘’`")
        )
    }
}
