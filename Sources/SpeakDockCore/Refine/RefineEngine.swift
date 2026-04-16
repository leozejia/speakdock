public enum RefineExecutionMode: Equatable, Sendable {
    case cleanOnly
    case workspaceRefine
}

public struct RefineConfiguration: Equatable, Sendable {
    public var enabled: Bool
    public var baseURL: String
    public var apiKey: String
    public var model: String

    public init(
        enabled: Bool,
        baseURL: String,
        apiKey: String,
        model: String
    ) {
        self.enabled = enabled
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
    }

    public var isConfigured: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var executionMode: RefineExecutionMode {
        enabled && isConfigured ? .workspaceRefine : .cleanOnly
    }
}

public struct RefineRequest: Equatable, Sendable {
    public var text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol RefineEngine: Sendable {
    func refine(
        _ request: RefineRequest,
        configuration: RefineConfiguration
    ) async throws -> String
}
