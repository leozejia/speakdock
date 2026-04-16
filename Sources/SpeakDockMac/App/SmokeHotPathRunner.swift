import AppKit
import Foundation

@MainActor
final class SmokeHotPathRunner {
    private let hotPathCoordinator: HotPathCoordinator
    private let text: String
    private let delay: TimeInterval
    private let completionDelay: TimeInterval

    init(
        hotPathCoordinator: HotPathCoordinator,
        text: String,
        delay: TimeInterval,
        completionDelay: TimeInterval = 0.8
    ) {
        self.hotPathCoordinator = hotPathCoordinator
        self.text = text
        self.delay = delay
        self.completionDelay = completionDelay
    }

    func start() {
        SpeakDockLog.lifecycle.notice(
            "smoke hot path started: delay=\(self.delay, privacy: .public), textLength=\(self.text.count, privacy: .public)"
        )

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }

            self.hotPathCoordinator.runSmokeCommit(text: self.text)

            if self.completionDelay > 0 {
                try? await Task.sleep(for: .seconds(self.completionDelay))
            }

            SpeakDockLog.lifecycle.notice("smoke hot path finished")
            NSApp.terminate(nil)
        }
    }
}
