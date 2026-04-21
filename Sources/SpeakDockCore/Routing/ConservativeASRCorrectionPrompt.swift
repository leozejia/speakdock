public enum ConservativeASRCorrectionPrompt {
    public static let systemPrompt = """
你是一个保守的语音转写纠错器。
你的任务是只修复明显识别错误。
只允许修正术语、人名、中英混输、同音误识别和极少量缺失标点。
如果原文已经正确，就原样返回。
不要润色，不要改写，不要删减，不要扩写。
不要改变结构、语气、顺序或信息密度。
输出时只返回修正后的正文，不要解释，不要加引号，不要加标题。
"""

    private static let engineeringFragmentHints: [(spoken: String, canonical: String)] = [
        ("should change", "should_change"),
        ("mlx community", "mlx-community"),
        ("make asr sample report", "make asr-sample-report"),
        ("qwen three point five", "Qwen3.5"),
        ("qwen slash qwen", "Qwen/Qwen"),
        ("zero point eight b", "0.8B"),
        ("two b", "2B"),
        ("opt iq", "OptiQ"),
        ("four bit", "4bit"),
        ("gemma three one b it four bit", "Gemma 3 1B it 4bit"),
        ("base url", "baseURL"),
        ("api key", "apiKey"),
        ("dev internal", "dev/internal"),
        ("codex cli", "Codex CLI"),
        ("open ai compatible", "OpenAI-compatible"),
    ]

    private static let productTermHints: [(spoken: String, canonical: String)] = [
        ("gemma free", "Gemma 3"),
        ("queen three asr", "Qwen3-ASR"),
        ("qwen three asr", "Qwen3-ASR"),
        ("claude code cli", "Claude Code CLI"),
        ("apple speech", "Apple Speech"),
        ("swift ui", "SwiftUI"),
    ]

    private static let homophoneHints: [(spoken: String, canonical: String)] = [
        ("图表组", "对照组"),
        ("邮化", "优化"),
        ("增只", "增值"),
        ("观册", "观测"),
        ("扩善", "扩散"),
    ]

    private static let wholeIdentifierHints: [(spoken: String, canonical: String)] = [
        ("mlx community qwen three point five zero point eight b opt iq four bit", "mlx-community/Qwen3.5-0.8B-OptiQ-4bit"),
        ("qwen slash qwen three point five zero point eight b", "Qwen/Qwen3.5-0.8B"),
        ("qwen three point five zero point eight b four bit", "Qwen3.5-0.8B-4bit"),
        ("qwen three point five zero point eight b", "Qwen3.5-0.8B"),
    ]

    public static func makeUserPrompt(for text: String) -> String {
        let hintBlocks = [
            makeProductTermHintBlock(for: text),
            makeWholeIdentifierHintBlock(for: text),
            makeEngineeringHintBlock(for: text),
            makeHomophoneHintBlock(for: text),
        ].compactMap { $0 }
        let prefix = hintBlocks.isEmpty ? "" : "\(hintBlocks.joined(separator: "\n\n"))\n\n"

        return """
\(prefix)请只修正下面转写文本里的明显识别错误；如果没有明显错误，就原样返回：

输入：\(text)
输出：
"""
    }

    private static func makeEngineeringHintBlock(for text: String) -> String? {
        let normalizedText = text.lowercased()
        var seenCanonicals = Set<String>()
        var lines: [String] = []

        for hint in engineeringFragmentHints where normalizedText.contains(hint.spoken) {
            if seenCanonicals.insert(hint.canonical).inserted {
                lines.append("- \(hint.spoken) -> \(hint.canonical)")
            }
        }

        guard !lines.isEmpty else {
            return nil
        }

        return """
以下工程片段如果明显是在指向固定写法，优先恢复成右侧格式：
\(lines.joined(separator: "\n"))
不要把右侧写法改成自然语言、空格写法或别的大小写形式。
"""
    }

    private static func makeProductTermHintBlock(for text: String) -> String? {
        let normalizedText = text.lowercased()
        var seenCanonicals = Set<String>()
        var lines: [String] = []

        for hint in productTermHints where normalizedText.contains(hint.spoken) {
            if seenCanonicals.insert(hint.canonical).inserted {
                lines.append("- \(hint.spoken) -> \(hint.canonical)")
            }
        }

        guard !lines.isEmpty else {
            return nil
        }

        return """
以下术语如果明显是在指向固定产品或技术名，优先恢复成右侧写法：
\(lines.joined(separator: "\n"))
不要把右侧术语拆成自然语言或空格写法。
"""
    }

    private static func makeHomophoneHintBlock(for text: String) -> String? {
        var seenCanonicals = Set<String>()
        var lines: [String] = []

        for hint in homophoneHints where text.contains(hint.spoken) {
            if seenCanonicals.insert(hint.canonical).inserted {
                lines.append("- \(hint.spoken) -> \(hint.canonical)")
            }
        }

        guard !lines.isEmpty else {
            return nil
        }

        return """
以下词如果明显是同音误识别，优先恢复成右侧写法：
\(lines.joined(separator: "\n"))
"""
    }

    private static func makeWholeIdentifierHintBlock(for text: String) -> String? {
        let normalizedText = text.lowercased()
        var seenCanonicals = Set<String>()
        var lines: [String] = []

        for hint in wholeIdentifierHints where normalizedText.contains(hint.spoken) {
            if seenCanonicals.insert(hint.canonical).inserted {
                lines.append("- \(hint.spoken) -> \(hint.canonical)")
            }
        }

        guard !lines.isEmpty else {
            return nil
        }

        return """
完整模型或仓库 ID 如果已经能确定，优先恢复成右侧整串写法：
\(lines.joined(separator: "\n"))
不要把整串写法拆成多个空格片段。
"""
    }
}
