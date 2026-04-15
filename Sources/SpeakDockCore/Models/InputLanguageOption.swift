public enum InputLanguageOption: String, CaseIterable, Codable, Sendable {
    case english = "en-US"
    case simplifiedChinese = "zh-CN"
    case traditionalChinese = "zh-TW"
    case japanese = "ja-JP"
    case korean = "ko-KR"

    public static let defaultOption: InputLanguageOption = .simplifiedChinese
}
