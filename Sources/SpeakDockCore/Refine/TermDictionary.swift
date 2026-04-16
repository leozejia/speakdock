import Foundation

public struct TermDictionaryEntry: Equatable, Codable, Sendable {
    public var canonicalTerm: String
    public var aliases: [String]

    public init(canonicalTerm: String, aliases: [String]) {
        self.canonicalTerm = canonicalTerm
        self.aliases = aliases
    }
}

public struct TermDictionary: Equatable, Codable, Sendable {
    public static let empty = TermDictionary(entries: [])

    public var entries: [TermDictionaryEntry]

    private static let asciiTermBoundaryScalars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")

    public init(entries: [TermDictionaryEntry]) {
        self.entries = entries
    }

    public func applying(to text: String) -> String {
        var rewritten = text

        for entry in entries {
            let canonicalTerm = entry.canonicalTerm.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !canonicalTerm.isEmpty else {
                continue
            }

            let aliases = entry.aliases
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != canonicalTerm }
                .sorted { $0.count > $1.count }

            for alias in aliases {
                rewritten = replaceStandaloneOccurrences(
                    of: alias,
                    with: canonicalTerm,
                    in: rewritten
                )
            }
        }

        return rewritten
    }

    private func replaceStandaloneOccurrences(
        of alias: String,
        with canonicalTerm: String,
        in text: String
    ) -> String {
        guard alias.rangeOfCharacter(from: Self.asciiTermBoundaryScalars) != nil else {
            return text.replacingOccurrences(of: alias, with: canonicalTerm)
        }

        var result = String()
        var searchStart = text.startIndex

        while searchStart < text.endIndex,
              let range = text.range(of: alias, range: searchStart..<text.endIndex) {
            result.append(contentsOf: text[searchStart..<range.lowerBound])

            if isStandaloneMatch(range, in: text) {
                result.append(canonicalTerm)
            } else {
                result.append(contentsOf: text[range])
            }

            searchStart = range.upperBound
        }

        result.append(contentsOf: text[searchStart...])
        return result
    }

    private func isStandaloneMatch(
        _ range: Range<String.Index>,
        in text: String
    ) -> Bool {
        let hasLeadingBoundary: Bool
        if range.lowerBound == text.startIndex {
            hasLeadingBoundary = true
        } else {
            let previousIndex = text.index(before: range.lowerBound)
            hasLeadingBoundary = !isASCIITermContinuation(text[previousIndex])
        }

        let hasTrailingBoundary: Bool
        if range.upperBound == text.endIndex {
            hasTrailingBoundary = true
        } else {
            hasTrailingBoundary = !isASCIITermContinuation(text[range.upperBound])
        }

        return hasLeadingBoundary && hasTrailingBoundary
    }

    private func isASCIITermContinuation(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            Self.asciiTermBoundaryScalars.contains(scalar)
        }
    }
}
