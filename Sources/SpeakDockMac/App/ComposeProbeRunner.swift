import AppKit
import Foundation

@MainActor
final class ComposeProbeRunner {
    private let composeTarget: ClipboardComposeTarget
    private let duration: TimeInterval
    private let interval: TimeInterval
    private var startedAt: Date?
    private var tickCount = 0

    init(
        composeTarget: ClipboardComposeTarget,
        duration: TimeInterval,
        interval: TimeInterval = 1
    ) {
        self.composeTarget = composeTarget
        self.duration = duration
        self.interval = interval
    }

    func start() {
        startedAt = Date()
        SpeakDockLog.lifecycle.notice(
            "compose probe started: duration=\(self.duration, privacy: .public), interval=\(self.interval, privacy: .public)"
        )
        tick()
    }

    private func tick() {
        guard let startedAt else {
            return
        }

        tickCount += 1
        let frontmostBundleIdentifier = composeTarget.frontmostApplicationBundleIdentifier() ?? "unknown"
        let availability = composeTarget.captureCurrentTarget()
        SpeakDockLog.compose.notice(
            "compose probe result: tick=\(self.tickCount, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public), availability=\(Self.logValue(for: availability), privacy: .public)"
        )

        guard Date().timeIntervalSince(startedAt) < duration else {
            SpeakDockLog.lifecycle.notice("compose probe finished")
            NSApp.terminate(nil)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.tick()
        }
    }

    private static func logValue(for availability: ComposeTargetAvailability) -> String {
        switch availability {
        case .available:
            return "available"
        case .noTarget:
            return "noTarget"
        case .unavailable:
            return "unavailable"
        }
    }
}
