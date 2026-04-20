import AppKit
import Foundation

@MainActor
final class ComposeProbeRunner {
    private let composeTarget: ClipboardComposeTarget
    private let duration: TimeInterval
    private let interval: TimeInterval
    private let resultFileURL: URL?
    private var startedAt: Date?
    private var tickCount = 0
    private var accumulatedVerdict: ComposeProbeVerdict?

    init(
        composeTarget: ClipboardComposeTarget,
        duration: TimeInterval,
        interval: TimeInterval = 1,
        resultFileURL: URL? = probeResultFileURL()
    ) {
        self.composeTarget = composeTarget
        self.duration = duration
        self.interval = interval
        self.resultFileURL = resultFileURL
    }

    nonisolated static func probeResultFileURL(arguments: [String] = CommandLine.arguments) -> URL? {
        guard let flagIndex = arguments.firstIndex(of: "--probe-compose-result-file") else {
            return nil
        }

        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex else {
            return nil
        }

        return URL(fileURLWithPath: arguments[valueIndex])
    }

    nonisolated static func probeResultContents(verdict: ComposeProbeVerdict) -> String {
        "\(verdict.rawValue)\n"
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
        let verdict = ClipboardComposeTarget.composeProbeVerdict(for: availability)
        accumulatedVerdict = ClipboardComposeTarget.accumulatedComposeProbeVerdict(
            accumulatedVerdict,
            next: verdict
        )
        SpeakDockLog.compose.notice(
            "compose probe result: tick=\(self.tickCount, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public), availability=\(Self.logValue(for: availability), privacy: .public), verdict=\(verdict.rawValue, privacy: .public)"
        )

        guard Date().timeIntervalSince(startedAt) < duration else {
            self.persistResult()
            SpeakDockLog.lifecycle.notice(
                "compose probe finished: verdict=\(self.finalVerdict().rawValue, privacy: .public)"
            )
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

    private func finalVerdict() -> ComposeProbeVerdict {
        accumulatedVerdict ?? .unavailable
    }

    private func persistResult() {
        guard let resultFileURL else {
            return
        }

        do {
            try Self.probeResultContents(verdict: finalVerdict()).write(
                to: resultFileURL,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            SpeakDockLog.compose.error(
                "compose probe failed to write result file: path=\(resultFileURL.path, privacy: .public)"
            )
        }
    }
}
