import Foundation
import Observation
import OSLog
import SpeakDockCore

@MainActor
@Observable
final class HotPathCoordinator {
    var secondaryActionTitle = AppLocalizer.string(.hotPathSecondaryActionRefine)
    var secondaryActionEnabled = false

    private let settingsStore: SettingsStore
    private let triggerController: TriggerController
    private let audioCaptureEngine: AudioCaptureEngine
    private let composeTarget: ClipboardComposeTarget
    private let captureTarget: CaptureFileTarget
    private let speechController: SpeechController
    private let overlayPanelController: OverlayPanelController
    private let cleanNormalizer: CleanNormalizer
    private let recognitionCommitPreparer: RecognitionCommitPreparer
    private let recognitionCommitProcessor: RecognitionCommitProcessor
    private let workspaceRefinePreparer: WorkspaceRefinePreparer
    private let refineEngine: any RefineEngine
    private let runtimeRefineConfigurationOverride: RefineConfiguration?
    private let runtimeCaptureRootURLOverride: URL?
    private let wordCorrectionObservationRecorder: WordCorrectionObservationRecorder
    private let clock: () -> TimeInterval

    private var workspaceState = WorkspaceState()
    private var undoFlowState = UndoFlowState()
    private var composeTargetSession = ComposeTargetSession()
    private var activeInteractionTrace: HotPathInteractionTrace?
    private var activeRefineTask: Task<Void, Never>?
    private var activeRecognitionCommitTask: Task<Void, Never>?
    private var pendingRecognitionTimeoutTask: Task<Void, Never>?
    private var renderedSegmentsByWorkspaceID: [UUID: [String]] = [:]

    init(
        settingsStore: SettingsStore,
        triggerController: TriggerController,
        audioCaptureEngine: AudioCaptureEngine,
        composeTarget: ClipboardComposeTarget,
        captureTarget: CaptureFileTarget,
        speechController: SpeechController,
        overlayPanelController: OverlayPanelController,
        termDictionaryStore: TermDictionaryStore,
        cleanNormalizer: CleanNormalizer = CleanNormalizer(),
        recognitionCommitProcessor: RecognitionCommitProcessor = RecognitionCommitProcessor(),
        refineEngine: any RefineEngine = OpenAICompatibleRefineEngine(),
        runtimeRefineConfigurationOverride: RefineConfiguration? = nil,
        runtimeCaptureRootURLOverride: URL? = nil,
        clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.settingsStore = settingsStore
        self.triggerController = triggerController
        self.audioCaptureEngine = audioCaptureEngine
        self.composeTarget = composeTarget
        self.captureTarget = captureTarget
        self.speechController = speechController
        self.overlayPanelController = overlayPanelController
        self.cleanNormalizer = cleanNormalizer
        self.recognitionCommitPreparer = RecognitionCommitPreparer(cleanNormalizer: cleanNormalizer)
        self.recognitionCommitProcessor = recognitionCommitProcessor
        self.workspaceRefinePreparer = WorkspaceRefinePreparer(cleanNormalizer: cleanNormalizer)
        self.refineEngine = refineEngine
        self.runtimeRefineConfigurationOverride = runtimeRefineConfigurationOverride
        self.runtimeCaptureRootURLOverride = runtimeCaptureRootURLOverride
        self.wordCorrectionObservationRecorder = WordCorrectionObservationRecorder(
            termDictionaryStore: termDictionaryStore,
            observeComposeText: { targetID in
                composeTarget.observedWorkspaceText(expectedTargetID: targetID)
            },
            observeCaptureText: { targetID in
                captureTarget.observedWorkspaceText(expectedTargetID: targetID)
            }
        )
        self.clock = clock

        wireDependencies()
        refreshSecondaryAction()
    }

    func performSecondaryAction() {
        synchronizeObservedWorkspaceTextIfNeeded()

        let action = undoFlowState.handleSecondaryAction(
            for: workspaceState.activeWorkspace,
            now: clock()
        )

        switch action {
        case .none:
            break

        case .refine:
            refineCurrentWorkspace()

        case .requestUndoRefineConfirmation:
            overlayPanelController.updateTranscript(AppLocalizer.string(.hotPathUndoDirtyConfirmation))
            refreshSecondaryAction()

        case .undoRefine:
            undoRefine()

        case let .undoRecentSubmission(recentSubmission):
            undoRecentSubmission(recentSubmission)
        }
    }

    func runSmokeCommit(text: String) {
        startInteractionTrace(kind: .recording, origin: .smoke)
        let composeAvailabilityAtStart = composeTarget.captureCurrentTarget()
        composeTargetSession.begin(availability: composeAvailabilityAtStart)
        logInteractionStage(
            "smokeStarted",
            extras: ["capturedTarget=\(composeTargetSession.hasCapturedTarget)"]
        )

        let cleanedText = cleanNormalizer.normalize(text)
        guard !cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            finishInteractionTrace(result: .emptyTranscript)
            return
        }

        mutateInteractionTrace {
            $0.markRecognitionFinal(at: clock())
        }
        logInteractionStage("recognitionFinal", extras: ["synthetic=true"])
        overlayPanelController.updateTranscript(cleanedText)
        commitRecognizedText(cleanedText)
    }

    func runSmokeRefineSubmit(
        text: String,
        submitDelay: TimeInterval = 0.8,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeSubmit(
            text: text,
            submitDelay: submitDelay,
            recordWordCorrectionEvidence: false,
            onFinished: onFinished
        )
    }

    func runSmokeManualRefine(
        text: String,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeCommit(text: text)
        runSmokeRefineSecondaryAction(onFinished: onFinished)
    }

    func runSmokeCaptureManualRefine(
        text: String,
        onFinished: @escaping @MainActor () -> Void
    ) {
        guard let captureRootURL = runtimeCaptureRootURLOverride else {
            SpeakDockLog.capture.error("smoke capture manual refine missing capture root")
            onFinished()
            return
        }

        runSmokeCaptureCommit(text: text, captureRootURL: captureRootURL)
        runSmokeRefineSecondaryAction(onFinished: onFinished)
    }

    private func runSmokeRefineSecondaryAction(
        onFinished: @escaping @MainActor () -> Void
    ) {
        undoFlowState.clearRecentSubmission()
        refreshSecondaryAction()
        performSecondaryAction()

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            for _ in 0..<100 {
                if self.activeRefineTask == nil,
                   self.workspaceState.activeWorkspace?.isRefined == true
                {
                    break
                }

                try? await Task.sleep(for: .milliseconds(50))
            }

            onFinished()
        }
    }

    func runSmokeDirtyUndoRefine(
        text: String,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeCommit(text: text)
        runSmokeDirtyUndoRefineSecondaryAction(onFinished: onFinished)
    }

    func runSmokeCaptureDirtyUndoRefine(
        text: String,
        onFinished: @escaping @MainActor () -> Void
    ) {
        guard let captureRootURL = runtimeCaptureRootURLOverride else {
            SpeakDockLog.capture.error("smoke capture dirty undo refine missing capture root")
            onFinished()
            return
        }

        runSmokeCaptureCommit(text: text, captureRootURL: captureRootURL)
        runSmokeDirtyUndoRefineSecondaryAction(onFinished: onFinished)
    }

    private func runSmokeDirtyUndoRefineSecondaryAction(
        onFinished: @escaping @MainActor () -> Void
    ) {
        undoFlowState.clearRecentSubmission()
        refreshSecondaryAction()
        performSecondaryAction()

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            for _ in 0..<100 {
                if self.activeRefineTask == nil,
                   self.workspaceState.activeWorkspace?.isRefined == true
                {
                    break
                }

                try? await Task.sleep(for: .milliseconds(50))
            }

            for _ in 0..<100 {
                self.synchronizeObservedWorkspaceTextIfNeeded()
                if self.workspaceState.activeWorkspace?.dirty == true {
                    break
                }

                try? await Task.sleep(for: .milliseconds(50))
            }

            self.performSecondaryAction()
            self.performSecondaryAction()
            onFinished()
        }
    }

    func runSmokeTermLearningSubmit(
        text: String,
        submitDelay: TimeInterval = 0.8,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeSubmit(
            text: text,
            submitDelay: submitDelay,
            recordWordCorrectionEvidence: true,
            onFinished: onFinished
        )
    }

    func runSmokeContinueAfterObservedEdit(
        initialText: String,
        continuedText: String,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeCommit(text: initialText)

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            var observedEditDetected = false

            for _ in 0..<100 {
                guard let workspace = self.workspaceState.activeWorkspace else {
                    try? await Task.sleep(for: .milliseconds(50))
                    continue
                }

                if let observedText = self.observedCurrentWorkspaceText(for: workspace),
                   observedText != workspace.visibleText
                {
                    self.synchronizeObservedWorkspaceTextIfNeeded(
                        for: workspace.mode,
                        targetID: workspace.targetID
                    )
                    observedEditDetected = true
                    break
                }

                try? await Task.sleep(for: .milliseconds(50))
            }

            if observedEditDetected {
                self.runSmokeCommit(text: continuedText)
            } else {
                SpeakDockLog.lifecycle.error(
                    "smoke live continuation timed out waiting for observed workspace edit"
                )
            }

            onFinished()
        }
    }

    func runSmokeCaptureContinueAfterObservedEdit(
        initialText: String,
        continuedText: String,
        captureRootURL: URL,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeCaptureCommit(text: initialText, captureRootURL: captureRootURL)

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            var observedEditDetected = false

            for _ in 0..<100 {
                guard let workspace = self.workspaceState.activeWorkspace,
                      workspace.mode == .capture
                else {
                    try? await Task.sleep(for: .milliseconds(50))
                    continue
                }

                if let observedText = self.observedCurrentWorkspaceText(for: workspace),
                   observedText != workspace.visibleText
                {
                    observedEditDetected = true
                    break
                }

                try? await Task.sleep(for: .milliseconds(50))
            }

            if observedEditDetected {
                self.runSmokeCaptureCommit(text: continuedText, captureRootURL: captureRootURL)
            } else {
                SpeakDockLog.capture.error(
                    "smoke capture continuation timed out waiting for observed workspace edit"
                )
            }

            onFinished()
        }
    }

    func runSmokeCaptureUndoRecentSubmission(
        text: String,
        captureRootURL: URL,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeCaptureCommit(text: text, captureRootURL: captureRootURL)
        performSecondaryAction()
        onFinished()
    }

    private func runSmokeSubmit(
        text: String,
        submitDelay: TimeInterval,
        recordWordCorrectionEvidence: Bool,
        onFinished: @escaping @MainActor () -> Void
    ) {
        runSmokeCommit(text: text)

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            if submitDelay > 0 {
                try? await Task.sleep(for: .seconds(submitDelay))
            }

            self.beginSubmitAction(
                origin: .smoke,
                shouldRecordWordCorrectionEvidence: recordWordCorrectionEvidence,
                onFinished: onFinished
            )
        }
    }

    private func wireDependencies() {
        overlayPanelController.onSecondaryAction = { [weak self] in
            self?.performSecondaryAction()
        }

        audioCaptureEngine.onAudioBufferCaptured = speechController.makeAudioBufferAppender()
        audioCaptureEngine.onLevelChanged = { [weak self] level in
            self?.overlayPanelController.updateLevel(level)
        }
        audioCaptureEngine.onAvailabilityChanged = { [weak self] availability in
            guard case let .unavailable(label) = availability else {
                return
            }

            self?.cancelRecognitionTimeout()
            self?.finishInteractionTrace(result: .microphoneUnavailable)
            self?.overlayPanelController.showError(label)
        }

        speechController.onRecognitionResult = { [weak self] result in
            self?.handleRecognitionResult(result)
        }
        speechController.onAvailabilityChanged = { [weak self] availability in
            guard case let .unavailable(label) = availability else {
                return
            }

            self?.cancelRecognitionTimeout()
            self?.finishInteractionTrace(result: .speechUnavailable)
            self?.overlayPanelController.showError(label)
        }

        triggerController.onPressStateChanged = { [weak self] isPressed in
            self?.handlePressStateChanged(isPressed)
        }
        triggerController.onAction = { [weak self] action in
            self?.handleTriggerAction(action)
        }
    }

    private func handlePressStateChanged(_ isPressed: Bool) {
        if isPressed {
            SpeakDockLog.trigger.notice("press started")
            startInteractionTrace(kind: .recording)
            cancelRefineTask()
            cancelRecognitionCommitTask()
            cancelRecognitionTimeout()
            let composeAvailabilityAtPressStart = composeTarget.captureCurrentTarget()
            composeTargetSession.begin(availability: composeAvailabilityAtPressStart)
            if composeTargetSession.hasCapturedTarget {
                SpeakDockLog.compose.notice("compose target captured at press start")
            }
            logInteractionStage(
                "pressStarted",
                extras: ["capturedTarget=\(composeTargetSession.hasCapturedTarget)"]
            )
            overlayPanelController.showListening()
            speechController.startSession()
            audioCaptureEngine.start()
        } else {
            SpeakDockLog.trigger.notice("press ended")
            mutateInteractionTrace {
                $0.markPressEnded(at: clock())
            }
            logInteractionStage("pressEnded")
            audioCaptureEngine.stop()
            speechController.finishSession()
            overlayPanelController.dismiss(after: 0.35)
        }
    }

    private func handleTriggerAction(_ action: TriggerAction) {
        switch action {
        case .recording:
            SpeakDockLog.trigger.notice("recording action completed")
            logInteractionStage("recordingCompleted")
            overlayPanelController.showThinking(transcript: speechController.latestTranscript)
            scheduleRecognitionTimeout()

        case .submit:
            SpeakDockLog.trigger.notice("submit action received")
            beginSubmitAction(origin: .live)
        }
    }

    private func handleRecognitionResult(_ result: RecognitionResult) {
        let trimmedText = result.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty {
            if result.isFinal {
                cancelRecognitionTimeout()
                finishInteractionTrace(result: .emptyTranscript)
                overlayPanelController.dismiss(after: 0.2)
            }
            return
        }

        overlayPanelController.updateTranscript(trimmedText)

        guard result.isFinal else {
            return
        }

        cancelRecognitionTimeout()
        mutateInteractionTrace {
            $0.markRecognitionFinal(at: clock())
        }
        logInteractionStage("recognitionFinal")
        let preparation = recognitionCommitPreparer.prepare(
            transcript: trimmedText,
            configuration: currentASRCorrectionConfiguration
        )

        guard preparation.shouldCallASRCorrection else {
            SpeakDockLog.speech.debug("recognition commit prepared without asr correction; committing clean text")
            commitRecognizedText(preparation.committedText)
            return
        }

        cancelRecognitionCommitTask()
        activeRecognitionCommitTask = Task { [weak self] in
            guard let self else {
                return
            }

            let committedText = await self.recognitionCommitProcessor.process(
                preparation,
                configuration: self.currentASRCorrectionConfiguration
            )

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self.overlayPanelController.updateTranscript(committedText)
                self.commitRecognizedText(committedText)
                self.activeRecognitionCommitTask = nil
            }
        }
    }

    private func commitRecognizedText(_ text: String) {
        cancelRecognitionTimeout()
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            finishInteractionTrace(result: .emptyTranscript)
            overlayPanelController.dismiss(after: 0.2)
            return
        }

        defer {
            composeTargetSession.end()
        }

        let resolvedComposeAvailability = composeTargetSession.resolvedAvailability(
            current: composeTarget.availability()
        )

        if composeTargetSession.hasCapturedTarget {
            SpeakDockLog.compose.notice("using compose target captured at press start")
            switch resolvedComposeAvailability {
            case let .available(targetID):
                markCommitStarted(route: .compose)
                commitToCompose(trimmedText, targetID: targetID)

            case .noTarget:
                SpeakDockLog.compose.warning("captured compose target disappeared before commit")
                finishInteractionTrace(result: .composeTargetLost)
                overlayPanelController.showError(AppLocalizer.string(.hotPathComposeUnavailable))

            case let .unavailable(reason):
                SpeakDockLog.compose.warning("captured compose target unavailable before commit: \(reason, privacy: .private)")
                finishInteractionTrace(result: .composeUnavailable)
                overlayPanelController.showError(reason)
            }
            return
        }

        let frontmostBundleIdentifier = composeTarget.frontmostApplicationBundleIdentifier()

        if captureTarget.shouldContinueCapture(frontmostBundleIdentifier: frontmostBundleIdentifier) {
            commitToCapture(trimmedText)
            return
        }

        switch resolvedComposeAvailability {
        case let .available(targetID):
            markCommitStarted(route: .compose)
            commitToCompose(trimmedText, targetID: targetID)

        case .noTarget:
            SpeakDockLog.compose.debug("no compose target; using capture")
            markCommitStarted(route: .capture)
            commitToCapture(trimmedText)

        case let .unavailable(reason):
            SpeakDockLog.compose.warning("compose unavailable: \(reason, privacy: .private)")
            finishInteractionTrace(result: .composeUnavailable)
            overlayPanelController.showError(reason)
        }
    }

    private func commitToCompose(_ text: String, targetID: String) {
        synchronizeObservedWorkspaceTextIfNeeded(
            for: .compose,
            targetID: targetID
        )

        do {
            try composeTarget.inject(text, expectedTargetID: targetID)
            captureTarget.resetSession()
            SpeakDockLog.compose.notice("compose commit succeeded")
            finishInteractionTrace(result: .composeCommitted)

            let workspace = activateWorkspace(mode: .compose, targetID: targetID)
            WorkspaceReducer.reduce(state: &workspaceState, action: .speechAppended(text))

            if let updatedWorkspace = workspaceState.activeWorkspace {
                undoFlowState.registerSubmission(
                    for: updatedWorkspace,
                    committedText: text,
                    timestamp: clock()
                )
                appendRenderedSegment(text, to: updatedWorkspace.id)
                overlayPanelController.updateTranscript(updatedWorkspace.visibleText)
            } else {
                _ = workspace
            }

            refreshSecondaryAction()
            overlayPanelController.dismiss(after: 0.5)
        } catch {
            SpeakDockLog.compose.error("compose commit failed: \(error.localizedDescription, privacy: .private)")
            finishInteractionTrace(result: .composeCommitFailed)
            overlayPanelController.showError(error.localizedDescription)
        }
    }

    private func commitToCapture(_ text: String, captureRootURLOverride: URL? = nil) {
        let captureRootURL = captureRootURLOverride ?? runtimeCaptureRootURLOverride ?? URL(
            fileURLWithPath: settingsStore.settings.captureRootPath,
            isDirectory: true
        )

        if let targetID = captureWorkspaceTargetIDForContinuation() {
            synchronizeObservedWorkspaceTextIfNeeded(
                for: .capture,
                targetID: targetID
            )
        }

        do {
            let fileURL = try captureTarget.write(text, captureRootURL: captureRootURL)
            SpeakDockLog.capture.notice("capture commit succeeded")
            finishInteractionTrace(result: .captureCommitted)
            let workspace = activateWorkspace(mode: .capture, targetID: fileURL.path)
            WorkspaceReducer.reduce(state: &workspaceState, action: .speechAppended(text))

            if let updatedWorkspace = workspaceState.activeWorkspace {
                undoFlowState.registerSubmission(
                    for: updatedWorkspace,
                    committedText: text,
                    timestamp: clock()
                )
                appendRenderedSegment(text, to: updatedWorkspace.id)
                overlayPanelController.updateTranscript(updatedWorkspace.visibleText)
            } else {
                _ = workspace
            }

            refreshSecondaryAction()
            overlayPanelController.dismiss(after: 0.5)
        } catch {
            SpeakDockLog.capture.error("capture commit failed: \(error.localizedDescription, privacy: .private)")
            finishInteractionTrace(result: .captureCommitFailed)
            overlayPanelController.showError(error.localizedDescription)
        }
    }

    private func runSmokeCaptureCommit(text: String, captureRootURL: URL) {
        startInteractionTrace(kind: .recording, origin: .smoke)
        logInteractionStage("smokeStarted", extras: ["route=capture"])

        let cleanedText = cleanNormalizer.normalize(text)
        guard !cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            finishInteractionTrace(result: .emptyTranscript)
            return
        }

        mutateInteractionTrace {
            $0.markRecognitionFinal(at: clock())
        }
        logInteractionStage("recognitionFinal", extras: ["synthetic=true"])
        overlayPanelController.updateTranscript(cleanedText)
        markCommitStarted(route: .capture)
        commitToCapture(cleanedText, captureRootURLOverride: captureRootURL)
    }

    private func activateWorkspace(mode: Mode, targetID: String) -> Workspace {
        if let endedWorkspace = WorkspaceTransitionObservationPolicy.endedWorkspaceBeforeTransition(
            current: workspaceState.activeWorkspace,
            nextMode: mode,
            nextTargetID: targetID
        ) {
            recordWordCorrectionEvidenceIfPossible(for: endedWorkspace)
        }

        if workspaceState.activeWorkspace?.mode != mode || workspaceState.activeWorkspace?.targetID != targetID {
            WorkspaceReducer.reduce(
                state: &workspaceState,
                action: .focusChanged(targetID: targetID, mode: mode, cursorLocation: 0)
            )
            renderedSegmentsByWorkspaceID.removeAll()
            undoFlowState.clearPendingConfirmation()
        }

        return workspaceState.activeWorkspace!
    }

    private func refineCurrentWorkspace() {
        guard let workspace = workspaceState.activeWorkspace else {
            refreshSecondaryAction()
            return
        }

        let configuration = currentRefineConfiguration
        let preparation = currentWorkspaceRefinePreparation(
            for: workspace,
            configuration: configuration
        )
        let baseText = preparation.modelInputText

        guard !baseText.isEmpty else {
            refreshSecondaryAction()
            return
        }

        if !preparation.shouldCallModel {
            SpeakDockLog.refine.debug("manual refine requested while refine is disabled; applying clean text")
            applyRefinedText(baseText, toWorkspaceID: workspace.id)
            return
        }

        SpeakDockLog.refine.notice("manual refine request started")
        overlayPanelController.showRefining(transcript: baseText)
        cancelRefineTask()
        activeRefineTask = Task { [weak self] in
            guard let self else {
                return
            }

            let refinedText: String
            do {
                let response = try await self.refineEngine.refine(
                    RefineRequest(text: baseText),
                    configuration: configuration
                )
                let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                refinedText = trimmedResponse.isEmpty ? baseText : trimmedResponse
            } catch {
                SpeakDockLog.refine.error("manual refine request failed; falling back to clean text")
                refinedText = baseText
            }

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self.applyRefinedText(refinedText, toWorkspaceID: workspace.id)
                self.activeRefineTask = nil
            }
        }
    }

    @discardableResult
    private func applyRefinedText(
        _ text: String,
        toWorkspaceID workspaceID: UUID,
        showsFailureOverlay: Bool = true
    ) -> Bool {
        guard let workspace = workspaceState.activeWorkspace, workspace.id == workspaceID else {
            refreshSecondaryAction()
            return false
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            refreshSecondaryAction()
            return false
        }

        if !workspace.isRefined && trimmedText == workspace.visibleText {
            refreshSecondaryAction()
            return true
        }

        do {
            switch workspace.mode {
            case .compose:
                let undoCount = max(renderedSegmentsByWorkspaceID[workspace.id]?.count ?? 0, 1)
                try composeTarget.replaceWorkspaceText(
                    with: trimmedText,
                    undoCount: undoCount,
                    expectedTargetID: workspace.targetID
                )
                SpeakDockLog.compose.notice("compose refine apply succeeded")

            case .capture:
                try captureTarget.replaceContents(with: trimmedText, targetID: workspace.targetID)
                SpeakDockLog.capture.notice("capture refine apply succeeded")

            case .wiki:
                break
            }

            WorkspaceReducer.reduce(state: &workspaceState, action: .refineApplied(trimmedText))
            renderedSegmentsByWorkspaceID[workspace.id] = [trimmedText]
            undoFlowState.clearRecentSubmission()
            overlayPanelController.updateTranscript(trimmedText)
            refreshSecondaryAction()
            return true
        } catch {
            SpeakDockLog.refine.error("refine apply failed: \(error.localizedDescription, privacy: .private)")
            if showsFailureOverlay {
                overlayPanelController.showError(error.localizedDescription)
            }
            return false
        }
    }

    private func undoRefine() {
        guard let workspace = workspaceState.activeWorkspace else {
            refreshSecondaryAction()
            return
        }

        let rawText = workspace.rawContext

        do {
            switch workspace.mode {
            case .compose:
                try composeTarget.replaceWorkspaceText(
                    with: rawText,
                    undoCount: 1,
                    expectedTargetID: workspace.targetID
                )
                SpeakDockLog.compose.notice("compose refine undo succeeded")

            case .capture:
                try captureTarget.replaceContents(with: rawText, targetID: workspace.targetID)
                SpeakDockLog.capture.notice("capture refine undo succeeded")

            case .wiki:
                break
            }

            WorkspaceReducer.reduce(state: &workspaceState, action: .undoRefineRequested)
            renderedSegmentsByWorkspaceID[workspace.id] = [rawText]
            overlayPanelController.updateTranscript(rawText)
            refreshSecondaryAction()
        } catch {
            SpeakDockLog.refine.error("refine undo failed: \(error.localizedDescription, privacy: .private)")
            overlayPanelController.showError(error.localizedDescription)
        }
    }

    private func undoRecentSubmission(_ recentSubmission: RecentSubmission) {
        guard let workspace = workspaceState.activeWorkspace, workspace.id == recentSubmission.workspaceID else {
            refreshSecondaryAction()
            return
        }

        do {
            switch recentSubmission.mode {
            case .compose:
                try composeTarget.undoLastInsertion(expectedTargetID: recentSubmission.targetID)
                SpeakDockLog.compose.notice("compose recent submission undo succeeded")

            case .capture:
                try captureTarget.undoLastAppend(
                    expectedTargetID: recentSubmission.targetID,
                    committedText: recentSubmission.committedText
                )
                SpeakDockLog.capture.notice("capture recent submission undo succeeded")

            case .wiki:
                break
            }

            WorkspaceReducer.reduce(
                state: &workspaceState,
                action: .speechSegmentUndone(recentSubmission.committedText)
            )

            if let updatedWorkspace = workspaceState.activeWorkspace {
                var segments = renderedSegmentsByWorkspaceID[updatedWorkspace.id] ?? []
                if !segments.isEmpty {
                    segments.removeLast()
                }
                renderedSegmentsByWorkspaceID[updatedWorkspace.id] = segments
                overlayPanelController.updateTranscript(updatedWorkspace.visibleText)
            }

            refreshSecondaryAction()
        } catch {
            switch recentSubmission.mode {
            case .compose:
                SpeakDockLog.compose.error("recent submission undo failed: \(error.localizedDescription, privacy: .private)")
            case .capture:
                SpeakDockLog.capture.error("recent submission undo failed: \(error.localizedDescription, privacy: .private)")
            case .wiki:
                SpeakDockLog.lifecycle.error("recent submission undo failed for unsupported workspace mode")
            }
            overlayPanelController.showError(error.localizedDescription)
        }
    }

    private func submitCurrentWorkspaceIfPossible() {
        guard let workspace = workspaceState.activeWorkspace, workspace.mode == .compose else {
            finishInteractionTrace(result: .submitFailed)
            return
        }

        do {
            try composeTarget.submitCurrentTarget(expectedTargetID: workspace.targetID)
            SpeakDockLog.compose.notice("compose submit succeeded")
            finishInteractionTrace(result: .submitSucceeded)
        } catch {
            SpeakDockLog.compose.error("compose submit failed: \(error.localizedDescription, privacy: .private)")
            finishInteractionTrace(result: .submitFailed)
            overlayPanelController.showError(error.localizedDescription)
        }
    }

    private func beginSubmitAction(
        origin: HotPathInteractionTrace.Origin = .live,
        shouldRecordWordCorrectionEvidence: Bool? = nil,
        onFinished: (@MainActor () -> Void)? = nil
    ) {
        startInteractionTrace(kind: .submit, origin: origin)
        logInteractionStage("submitStarted")
        cancelRefineTask()
        cancelRecognitionCommitTask()
        cancelRecognitionTimeout()
        speechController.cancelSession()

        if shouldRecordWordCorrectionEvidence ?? (origin == .live) {
            recordWordCorrectionEvidenceIfPossible()
        }

        submitCurrentWorkspaceAfterOptionalRefine(onFinished: onFinished)
    }

    private func submitCurrentWorkspaceAfterOptionalRefine(
        onFinished: (@MainActor () -> Void)? = nil
    ) {
        guard let workspace = workspaceState.activeWorkspace, workspace.mode == .compose else {
            finishInteractionTrace(result: .submitFailed)
            completeSubmitAction(onFinished: onFinished)
            return
        }

        let configuration = currentRefineConfiguration
        let preparation = currentWorkspaceRefinePreparation(
            for: workspace,
            configuration: configuration
        )

        guard preparation.shouldCallModel, !preparation.modelInputText.isEmpty else {
            submitCurrentWorkspaceIfPossible()
            completeSubmitAction(onFinished: onFinished)
            return
        }

        SpeakDockLog.refine.notice("submit refine request started")
        logInteractionStage("refineStarted", extras: ["phase=submit"])
        overlayPanelController.showRefining(transcript: preparation.modelInputText)
        cancelRefineTask()
        activeRefineTask = Task { [weak self] in
            guard let self else {
                return
            }

            let refinedText: String?
            do {
                let response = try await self.refineEngine.refine(
                    RefineRequest(text: preparation.modelInputText),
                    configuration: configuration
                )
                let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                refinedText = trimmedResponse.isEmpty ? nil : trimmedResponse
                await MainActor.run {
                    self.logInteractionStage(
                        "refineFinished",
                        extras: ["phase=submit", "outcome=success"]
                    )
                }
            } catch {
                SpeakDockLog.refine.error("submit refine request failed; falling back to current workspace text")
                refinedText = nil
                await MainActor.run {
                    self.logInteractionStage(
                        "refineFinished",
                        extras: ["phase=submit", "outcome=fallback"]
                    )
                }
            }

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                if let refinedText {
                    _ = self.applyRefinedText(
                        refinedText,
                        toWorkspaceID: workspace.id,
                        showsFailureOverlay: false
                    )
                }

                self.submitCurrentWorkspaceIfPossible()
                self.completeSubmitAction(onFinished: onFinished)
                self.activeRefineTask = nil
            }
        }
    }

    private func completeSubmitAction(onFinished: (@MainActor () -> Void)? = nil) {
        WorkspaceReducer.reduce(state: &workspaceState, action: .workspaceEnded)
        renderedSegmentsByWorkspaceID.removeAll()
        undoFlowState.clearPendingConfirmation()
        undoFlowState.clearRecentSubmission()
        composeTargetSession.end()
        refreshSecondaryAction()
        overlayPanelController.dismiss(after: 0.1)
        onFinished?()
    }

    private func recordWordCorrectionEvidenceIfPossible(for workspace: Workspace? = nil) {
        do {
            try wordCorrectionObservationRecorder.recordIfNeeded(for: workspace ?? workspaceState.activeWorkspace)
        } catch {
            SpeakDockLog.compose.error(
                "word correction evidence recording failed: \(error.localizedDescription, privacy: .private)"
            )
        }
    }

    private var currentRefineConfiguration: RefineConfiguration {
        if let runtimeRefineConfigurationOverride {
            return runtimeRefineConfigurationOverride
        }

        return RefineConfiguration(
            enabled: settingsStore.settings.refineEnabled,
            baseURL: settingsStore.settings.refineBaseURL,
            apiKey: settingsStore.settings.refineAPIKey,
            model: settingsStore.settings.refineModel
        )
    }

    private var currentASRCorrectionConfiguration: ASRCorrectionConfiguration {
        .disabled
    }

    private func currentWorkspaceRefinePreparation(
        for workspace: Workspace,
        configuration: RefineConfiguration
    ) -> WorkspaceRefinePreparation {
        workspaceRefinePreparer.prepare(
            workspace: workspace,
            observedText: observedCurrentWorkspaceText(for: workspace),
            configuration: configuration
        )
    }

    private func observedCurrentWorkspaceText(for workspace: Workspace) -> String? {
        switch workspace.mode {
        case .compose:
            composeTarget.observedWorkspaceText(expectedTargetID: workspace.targetID)
        case .capture:
            captureTarget.observedWorkspaceText(expectedTargetID: workspace.targetID)
        case .wiki:
            nil
        }
    }

    private func synchronizeObservedWorkspaceTextIfNeeded() {
        guard let workspace = workspaceState.activeWorkspace else {
            return
        }

        guard let action = ObservedWorkspaceTextSync.action(
            currentVisibleText: workspace.visibleText,
            observedText: observedCurrentWorkspaceText(for: workspace)
        ) else {
            return
        }

        WorkspaceReducer.reduce(state: &workspaceState, action: action)

        if let updatedWorkspace = workspaceState.activeWorkspace {
            overlayPanelController.updateTranscript(updatedWorkspace.visibleText)
        }

        refreshSecondaryAction()
    }

    private func synchronizeObservedWorkspaceTextIfNeeded(for mode: Mode, targetID: String) {
        guard let workspace = workspaceState.activeWorkspace else {
            return
        }

        guard let action = WorkspaceContinuationObservationSync.action(
            activeWorkspace: workspace,
            incomingMode: mode,
            incomingTargetID: targetID,
            observedText: observedCurrentWorkspaceText(for: workspace)
        ) else {
            return
        }

        WorkspaceReducer.reduce(state: &workspaceState, action: action)

        if let updatedWorkspace = workspaceState.activeWorkspace {
            overlayPanelController.updateTranscript(updatedWorkspace.visibleText)
        }

        refreshSecondaryAction()
    }

    private func captureWorkspaceTargetIDForContinuation() -> String? {
        guard let workspace = workspaceState.activeWorkspace,
              workspace.mode == .capture
        else {
            return nil
        }

        return workspace.targetID
    }

    private func refreshSecondaryAction() {
        let presentation = undoFlowState.secondaryAction(
            for: workspaceState.activeWorkspace,
            now: clock()
        )
        let localizedTitle = presentation.localizedTitle(appLanguage: settingsStore.settings.appLanguage)
        secondaryActionTitle = localizedTitle
        secondaryActionEnabled = presentation.isEnabled
        overlayPanelController.updateSecondaryAction(
            title: localizedTitle,
            isEnabled: presentation.isEnabled
        )
    }

    private func appendRenderedSegment(_ text: String, to workspaceID: UUID) {
        var segments = renderedSegmentsByWorkspaceID[workspaceID] ?? []
        segments.append(text)
        renderedSegmentsByWorkspaceID[workspaceID] = segments
    }

    private func cancelRefineTask() {
        activeRefineTask?.cancel()
        activeRefineTask = nil
    }

    private func cancelRecognitionCommitTask() {
        activeRecognitionCommitTask?.cancel()
        activeRecognitionCommitTask = nil
    }

    private func scheduleRecognitionTimeout() {
        cancelRecognitionTimeout()
        pendingRecognitionTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard let self else {
                    return
                }

                SpeakDockLog.speech.error("speech recognition timed out while waiting for final result")
                self.finishInteractionTrace(result: .speechTimedOut)
                self.overlayPanelController.showError(AppLocalizer.string(.hotPathSpeechTimedOut))
                self.pendingRecognitionTimeoutTask = nil
            }
        }
    }

    private func cancelRecognitionTimeout() {
        pendingRecognitionTimeoutTask?.cancel()
        pendingRecognitionTimeoutTask = nil
    }

    private func startInteractionTrace(
        kind: HotPathInteractionTrace.Kind,
        origin: HotPathInteractionTrace.Origin = .live
    ) {
        let trace = HotPathInteractionTrace(
            kind: kind,
            origin: origin,
            startedAt: clock()
        )
        activeInteractionTrace = trace
        SpeakDockLog.trace.notice("\(trace.startLogMessage, privacy: .public)")
    }

    private func mutateInteractionTrace(_ body: (inout HotPathInteractionTrace) -> Void) {
        guard var trace = activeInteractionTrace else {
            return
        }

        body(&trace)
        activeInteractionTrace = trace
    }

    private func logInteractionStage(_ stage: String, extras: [String] = []) {
        guard let trace = activeInteractionTrace else {
            return
        }

        SpeakDockLog.trace.notice(
            "\(trace.stageLogMessage(stage, at: self.clock(), extras: extras), privacy: .public)"
        )
    }

    private func markCommitStarted(route: HotPathInteractionTrace.Route) {
        mutateInteractionTrace {
            $0.markCommitStarted(route: route, at: clock())
        }
        logInteractionStage("commitStarted", extras: ["route=\(route.rawValue)"])
    }

    private func finishInteractionTrace(result: HotPathInteractionTrace.Result) {
        guard let trace = activeInteractionTrace else {
            return
        }

        let summary = trace.finish(result: result, at: clock())
        SpeakDockLog.trace.notice("\(summary.logMessage, privacy: .public)")
        activeInteractionTrace = nil
    }
}

extension SecondaryActionPresentation {
    func localizedTitle(appLanguage: AppLanguageOption? = nil) -> String {
        switch kind {
        case .refine:
            AppLocalizer.string(.hotPathSecondaryActionRefine, appLanguage: appLanguage)

        case let .undoRefine(requiresConfirmation):
            AppLocalizer.string(
                requiresConfirmation
                    ? .hotPathSecondaryActionConfirmUndoRefine
                    : .hotPathSecondaryActionUndoRefine,
                appLanguage: appLanguage
            )

        case .undoRecentSubmission:
            AppLocalizer.string(.hotPathSecondaryActionUndoSubmit, appLanguage: appLanguage)
        }
    }
}
