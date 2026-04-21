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

    public static func makeUserPrompt(for text: String) -> String {
        let hintBlock = makeEngineeringHintBlock(for: text)
        let prefix = hintBlock.map { "\($0)\n\n" } ?? ""

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
}
