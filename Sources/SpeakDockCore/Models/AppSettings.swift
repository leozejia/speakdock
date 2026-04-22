import Foundation

public enum TriggerSelection: Equatable, Codable, Sendable {
    case fn
    case alternative(String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case value
    }

    private enum Kind: String, Codable {
        case fn
        case alternative
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .fn:
            self = .fn
        case .alternative:
            self = .alternative(try container.decode(String.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .fn:
            try container.encode(Kind.fn, forKey: .kind)
        case let .alternative(identifier):
            try container.encode(Kind.alternative, forKey: .kind)
            try container.encode(identifier, forKey: .value)
        }
    }
}

public struct AppSettings: Equatable, Codable, Sendable {
    public var appLanguage: AppLanguageOption
    public var inputLanguage: InputLanguageOption
    public var captureRootPath: String
    public var triggerSelection: TriggerSelection
    public var asrCorrectionProvider: ASRCorrectionProvider
    public var asrCorrectionBaseURL: String
    public var asrCorrectionAPIKey: String
    public var asrCorrectionModel: String
    public var refineEnabled: Bool
    public var refineBaseURL: String
    public var refineAPIKey: String
    public var refineModel: String

    private enum CodingKeys: String, CodingKey {
        case appLanguage
        case inputLanguage
        case languageCode
        case captureRootPath
        case triggerSelection
        case asrCorrectionProvider
        case asrCorrectionBaseURL
        case asrCorrectionAPIKey
        case asrCorrectionModel
        case refineEnabled
        case refineBaseURL
        case refineAPIKey
        case refineModel
    }

    public init(
        appLanguage: AppLanguageOption,
        inputLanguage: InputLanguageOption,
        captureRootPath: String,
        triggerSelection: TriggerSelection,
        asrCorrectionProvider: ASRCorrectionProvider,
        asrCorrectionBaseURL: String,
        asrCorrectionAPIKey: String,
        asrCorrectionModel: String,
        refineEnabled: Bool,
        refineBaseURL: String,
        refineAPIKey: String,
        refineModel: String
    ) {
        self.appLanguage = appLanguage
        self.inputLanguage = inputLanguage
        self.captureRootPath = captureRootPath
        self.triggerSelection = triggerSelection
        self.asrCorrectionProvider = asrCorrectionProvider
        self.asrCorrectionBaseURL = asrCorrectionBaseURL
        self.asrCorrectionAPIKey = asrCorrectionAPIKey
        self.asrCorrectionModel = asrCorrectionModel
        self.refineEnabled = refineEnabled
        self.refineBaseURL = refineBaseURL
        self.refineAPIKey = refineAPIKey
        self.refineModel = refineModel
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appLanguage = try container.decodeIfPresent(AppLanguageOption.self, forKey: .appLanguage) ?? .followSystem
        inputLanguage =
            try container.decodeIfPresent(InputLanguageOption.self, forKey: .inputLanguage)
            ?? container.decodeIfPresent(InputLanguageOption.self, forKey: .languageCode)
            ?? .defaultOption
        captureRootPath = try container.decode(String.self, forKey: .captureRootPath)
        triggerSelection = try container.decode(TriggerSelection.self, forKey: .triggerSelection)
        asrCorrectionProvider = try container.decodeIfPresent(ASRCorrectionProvider.self, forKey: .asrCorrectionProvider) ?? .disabled
        asrCorrectionBaseURL = try container.decodeIfPresent(String.self, forKey: .asrCorrectionBaseURL) ?? ""
        asrCorrectionAPIKey = try container.decodeIfPresent(String.self, forKey: .asrCorrectionAPIKey) ?? ""
        asrCorrectionModel = try container.decodeIfPresent(String.self, forKey: .asrCorrectionModel) ?? ""
        refineEnabled = try container.decode(Bool.self, forKey: .refineEnabled)
        refineBaseURL = try container.decode(String.self, forKey: .refineBaseURL)
        refineAPIKey = try container.decode(String.self, forKey: .refineAPIKey)
        refineModel = try container.decode(String.self, forKey: .refineModel)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appLanguage, forKey: .appLanguage)
        try container.encode(inputLanguage, forKey: .inputLanguage)
        try container.encode(captureRootPath, forKey: .captureRootPath)
        try container.encode(triggerSelection, forKey: .triggerSelection)
        try container.encode(asrCorrectionProvider, forKey: .asrCorrectionProvider)
        try container.encode(asrCorrectionBaseURL, forKey: .asrCorrectionBaseURL)
        try container.encode(asrCorrectionAPIKey, forKey: .asrCorrectionAPIKey)
        try container.encode(asrCorrectionModel, forKey: .asrCorrectionModel)
        try container.encode(refineEnabled, forKey: .refineEnabled)
        try container.encode(refineBaseURL, forKey: .refineBaseURL)
        try container.encode(refineAPIKey, forKey: .refineAPIKey)
        try container.encode(refineModel, forKey: .refineModel)
    }
}
