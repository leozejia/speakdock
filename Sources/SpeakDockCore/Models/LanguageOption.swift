public enum LanguageOption: String, CaseIterable, Codable, Sendable {
    case english = "en-US"
    case simplifiedChinese = "zh-CN"
    case traditionalChinese = "zh-TW"
    case japanese = "ja-JP"
    case korean = "ko-KR"

    public static let defaultOption: LanguageOption = .simplifiedChinese

    public var displayName: String {
        switch self {
        case .english:
            "English"
        case .simplifiedChinese:
            "简中"
        case .traditionalChinese:
            "繁中"
        case .japanese:
            "日本語"
        case .korean:
            "한국어"
        }
    }
}
