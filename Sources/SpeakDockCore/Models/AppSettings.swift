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
    public var languageCode: String
    public var captureRootPath: String
    public var triggerSelection: TriggerSelection
    public var refineEnabled: Bool
    public var refineBaseURL: String
    public var refineAPIKey: String
    public var refineModel: String

    public init(
        languageCode: String,
        captureRootPath: String,
        triggerSelection: TriggerSelection,
        refineEnabled: Bool,
        refineBaseURL: String,
        refineAPIKey: String,
        refineModel: String
    ) {
        self.languageCode = languageCode
        self.captureRootPath = captureRootPath
        self.triggerSelection = triggerSelection
        self.refineEnabled = refineEnabled
        self.refineBaseURL = refineBaseURL
        self.refineAPIKey = refineAPIKey
        self.refineModel = refineModel
    }
}
