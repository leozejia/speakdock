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

    private struct ReplacementRule {
        let alias: String
        let canonicalTerm: String
        let requiresStandaloneBoundary: Bool
    }

    private static let asciiTermBoundaryScalars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    private static let matchingOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    public init(entries: [TermDictionaryEntry]) {
        self.entries = entries
    }

    public func applying(to text: String) -> String {
        let replacements = entries.flatMap { entry in
            replacementRules(for: entry)
        }
        .sorted { lhs, rhs in
            if lhs.alias.count != rhs.alias.count {
                return lhs.alias.count > rhs.alias.count
            }

            return lhs.canonicalTerm.localizedCaseInsensitiveCompare(rhs.canonicalTerm) == .orderedAscending
        }

        guard !replacements.isEmpty else {
            return text
        }

        var rewritten = String()
        var index = text.startIndex

        while index < text.endIndex {
            if let replacement = firstReplacementMatch(
                at: index,
                in: text,
                replacements: replacements
            ) {
                rewritten.append(replacement.canonicalTerm)
                index = replacement.range.upperBound
                continue
            }

            rewritten.append(text[index])
            text.formIndex(after: &index)
        }

        return rewritten
    }

    private func replacementRules(for entry: TermDictionaryEntry) -> [ReplacementRule] {
        let canonicalTerm = entry.canonicalTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !canonicalTerm.isEmpty else {
            return []
        }

        return entry.aliases
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != canonicalTerm }
            .map { alias in
                ReplacementRule(
                    alias: alias,
                    canonicalTerm: canonicalTerm,
                    requiresStandaloneBoundary: alias.rangeOfCharacter(from: Self.asciiTermBoundaryScalars) != nil
                )
            }
    }

    private func firstReplacementMatch(
        at index: String.Index,
        in text: String,
        replacements: [ReplacementRule]
    ) -> (range: Range<String.Index>, canonicalTerm: String)? {
        for replacement in replacements {
            guard let range = text.range(
                of: replacement.alias,
                options: Self.matchingOptions,
                range: index..<text.endIndex,
                locale: .current
              ),
              range.lowerBound == index
            else {
                continue
            }

            if replacement.requiresStandaloneBoundary && !isStandaloneMatch(range, in: text) {
                continue
            }

            return (range: range, canonicalTerm: replacement.canonicalTerm)
        }

        return nil
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
