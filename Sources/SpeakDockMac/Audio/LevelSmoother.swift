struct LevelSmoother: Sendable {
    let attack: Float
    let release: Float

    private(set) var value: Float

    init(
        attack: Float = 0.4,
        release: Float = 0.15,
        initialValue: Float = 0
    ) {
        self.attack = attack
        self.release = release
        self.value = min(max(initialValue, 0), 1)
    }

    mutating func ingest(_ rmsLevel: Float) -> Float {
        let clampedLevel = min(max(rmsLevel, 0), 1)
        let factor = clampedLevel > value ? attack : release
        value += (clampedLevel - value) * factor
        return value
    }
}
