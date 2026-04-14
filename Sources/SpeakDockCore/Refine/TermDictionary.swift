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
                rewritten = rewritten.replacingOccurrences(of: alias, with: canonicalTerm)
            }
        }

        return rewritten
    }
}
