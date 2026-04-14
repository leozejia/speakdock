struct ComposeTargetSession {
    private var capturedTargetID: String?

    var hasCapturedTarget: Bool {
        capturedTargetID != nil
    }

    mutating func begin(availability: ComposeTargetAvailability) {
        guard case let .available(targetID) = availability else {
            capturedTargetID = nil
            return
        }

        capturedTargetID = targetID
    }

    mutating func end() {
        capturedTargetID = nil
    }

    func resolvedAvailability(current: ComposeTargetAvailability) -> ComposeTargetAvailability {
        if let capturedTargetID {
            return .available(targetID: capturedTargetID)
        }

        return current
    }
}
