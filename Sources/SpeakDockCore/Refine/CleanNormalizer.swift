import Foundation

public struct CleanNormalizer: Sendable {
    public init() {}

    public func normalize(_ text: String) -> String {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized = collapseWhitespace(in: normalized)
        normalized = removeLeadingFillers(in: normalized)
        normalized = collapseRepeatedPunctuation(in: normalized)
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func collapseWhitespace(in text: String) -> String {
        text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
    }

    private func removeLeadingFillers(in text: String) -> String {
        text.replacingOccurrences(
            of: #"^(嗯+|呃+|额+|啊+)[\s，,。.！!？?]*"#,
            with: "",
            options: .regularExpression
        )
    }

    private func collapseRepeatedPunctuation(in text: String) -> String {
        var normalized = text
        let replacements: [(String, String)] = [
            (#"，{2,}"#, "，"),
            (#",{2,}"#, ","),
            (#"。{2,}"#, "。"),
            (#"\.{2,}"#, "."),
            (#"！{2,}"#, "！"),
            (#"!{2,}"#, "!"),
            (#"？{2,}"#, "？"),
            (#"\?{2,}"#, "?"),
        ]

        for (pattern, replacement) in replacements {
            normalized = normalized.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }

        return normalized
    }
}
