import AppKit
import Foundation

@MainActor
final class SmokeHotPathRunner {
    enum Mode: String {
        case commit
        case undoRecentSubmission
        case asrCorrectionCommit
        case continueAfterObservedEdit
        case captureContinueAfterObservedEdit
        case captureUndoRecentSubmission
        case refineSubmit
        case refineManual
        case refineDirtyUndo
        case termLearningSubmit
    }

    private let hotPathCoordinator: HotPathCoordinator
    private let mode: Mode
    private let text: String
    private let secondText: String
    private let delay: TimeInterval
    private let submitDelay: TimeInterval
    private let completionDelay: TimeInterval
    private let captureRootURL: URL?
    private let refineTarget: SpeakDockLaunchOptions.SmokeRefineTarget

    init(
        hotPathCoordinator: HotPathCoordinator,
        mode: Mode = .commit,
        text: String,
        secondText: String = "",
        delay: TimeInterval,
        submitDelay: TimeInterval = 0.8,
        completionDelay: TimeInterval = 0.8,
        captureRootURL: URL? = nil,
        refineTarget: SpeakDockLaunchOptions.SmokeRefineTarget = .compose
    ) {
        self.hotPathCoordinator = hotPathCoordinator
        self.mode = mode
        self.text = text
        self.secondText = secondText
        self.delay = delay
        self.submitDelay = submitDelay
        self.completionDelay = completionDelay
        self.captureRootURL = captureRootURL
        self.refineTarget = refineTarget
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

            case .undoRecentSubmission:
                self.hotPathCoordinator.runSmokeUndoRecentSubmission(text: self.text) {
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

            case .asrCorrectionCommit:
                self.hotPathCoordinator.runSmokeASRCorrectionCommit(text: self.text) {
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

            case .continueAfterObservedEdit:
                self.hotPathCoordinator.runSmokeContinueAfterObservedEdit(
                    initialText: self.text,
                    continuedText: self.secondText
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

            case .captureContinueAfterObservedEdit:
                guard let captureRootURL = self.captureRootURL else {
                    SpeakDockLog.capture.error("smoke capture continuation missing capture root")
                    SpeakDockLog.lifecycle.notice("smoke hot path finished")
                    NSApp.terminate(nil)
                    return
                }

                self.hotPathCoordinator.runSmokeCaptureContinueAfterObservedEdit(
                    initialText: self.text,
                    continuedText: self.secondText,
                    captureRootURL: captureRootURL
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

            case .captureUndoRecentSubmission:
                guard let captureRootURL = self.captureRootURL else {
                    SpeakDockLog.capture.error("smoke capture undo missing capture root")
                    SpeakDockLog.lifecycle.notice("smoke hot path finished")
                    NSApp.terminate(nil)
                    return
                }

                self.hotPathCoordinator.runSmokeCaptureUndoRecentSubmission(
                    text: self.text,
                    captureRootURL: captureRootURL
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

            case .refineManual:
                let runRefine = {
                    if self.refineTarget == .capture {
                        self.hotPathCoordinator.runSmokeCaptureManualRefine(text: self.text) {
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
                    } else {
                        self.hotPathCoordinator.runSmokeManualRefine(text: self.text) {
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
                runRefine()

            case .refineDirtyUndo:
                let runRefine = {
                    if self.refineTarget == .capture {
                        self.hotPathCoordinator.runSmokeCaptureDirtyUndoRefine(text: self.text) {
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
                    } else {
                        self.hotPathCoordinator.runSmokeDirtyUndoRefine(text: self.text) {
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
                runRefine()

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
