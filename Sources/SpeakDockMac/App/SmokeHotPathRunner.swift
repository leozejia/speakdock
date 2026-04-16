import AppKit
import Foundation

@MainActor
final class SmokeHotPathRunner {
    enum Mode: String {
        case commit
        case refineSubmit
        case termLearningSubmit
    }

    private let hotPathCoordinator: HotPathCoordinator
    private let mode: Mode
    private let text: String
    private let delay: TimeInterval
    private let submitDelay: TimeInterval
    private let completionDelay: TimeInterval

    init(
        hotPathCoordinator: HotPathCoordinator,
        mode: Mode = .commit,
        text: String,
        delay: TimeInterval,
        submitDelay: TimeInterval = 0.8,
        completionDelay: TimeInterval = 0.8
    ) {
        self.hotPathCoordinator = hotPathCoordinator
        self.mode = mode
        self.text = text
        self.delay = delay
        self.submitDelay = submitDelay
        self.completionDelay = completionDelay
    }

    func start() {
        SpeakDockLog.lifecycle.notice(
            "smoke hot path started: mode=\(self.mode.rawValue, privacy: .public), delay=\(self.delay, privacy: .public), textLength=\(self.text.count, privacy: .public)"
        )

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }

            switch self.mode {
            case .commit:
                self.hotPathCoordinator.runSmokeCommit(text: self.text)

                if self.completionDelay > 0 {
                    try? await Task.sleep(for: .seconds(self.completionDelay))
                }

                SpeakDockLog.lifecycle.notice("smoke hot path finished")
                NSApp.terminate(nil)

            case .refineSubmit:
                self.hotPathCoordinator.runSmokeRefineSubmit(
                    text: self.text,
                    submitDelay: self.submitDelay
                ) {
                    Task { @MainActor [weak self] in
                        guard let self else {
                            return
                        }

                        if self.completionDelay > 0 {
                            try? await Task.sleep(for: .seconds(self.completionDelay))
                        }

                        SpeakDockLog.lifecycle.notice("smoke hot path finished")
                        NSApp.terminate(nil)
                    }
                }

            case .termLearningSubmit:
                self.hotPathCoordinator.runSmokeTermLearningSubmit(
                    text: self.text,
                    submitDelay: self.submitDelay
                ) {
                    Task { @MainActor [weak self] in
                        guard let self else {
                            return
                        }

                        if self.completionDelay > 0 {
                            try? await Task.sleep(for: .seconds(self.completionDelay))
                        }

                        SpeakDockLog.lifecycle.notice("smoke hot path finished")
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }
}
