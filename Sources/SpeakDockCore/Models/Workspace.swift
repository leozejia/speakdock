import Foundation

public struct Workspace: Equatable, Sendable {
    public let id: UUID
    public var mode: Mode
    public var targetID: String
    public var startLocation: Int
    public var endLocation: Int
    public var rawContext: String
    public var visibleText: String
    public var hasSpoken: Bool
    public var dirty: Bool
    public var isRefined: Bool

    public init(
        id: UUID = UUID(),
        mode: Mode,
        targetID: String,
        startLocation: Int,
        endLocation: Int? = nil,
        rawContext: String = "",
        visibleText: String = "",
        hasSpoken: Bool = false,
        dirty: Bool = false,
        isRefined: Bool = false
    ) {
        self.id = id
        self.mode = mode
        self.targetID = targetID
        self.startLocation = startLocation
        self.endLocation = endLocation ?? startLocation
        self.rawContext = rawContext
        self.visibleText = visibleText
        self.hasSpoken = hasSpoken
        self.dirty = dirty
        self.isRefined = isRefined
    }
}
