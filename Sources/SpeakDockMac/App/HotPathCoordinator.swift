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
    private let workspaceRefinePreparer: WorkspaceRefinePreparer
    private let refineEngine: any RefineEngine
    private let wordCorrectionObservationRecorder: WordCorrectionObservationRecorder
    private let clock: () -> TimeInterval

    private var workspaceState = WorkspaceState()
    private var undoFlowState = UndoFlowState()
    private var composeTargetSession = ComposeTargetSession()
    private var activeInteractionTrace: HotPathInteractionTrace?
    private var activeRefineTask: Task<Void, Never>?
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
        refineEngine: any RefineEngine = OpenAICompatibleRefineEngine(),
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
        self.workspaceRefinePreparer = WorkspaceRefinePreparer(cleanNormalizer: cleanNormalizer)
        self.refineEngine = refineEngine
        self.wordCorrectionObservationRecorder = WordCorrectionObservationRecorder(
            termDictionaryStore: termDictionaryStore,
            observeComposeText: { targetID in
                composeTarget.observedWorkspaceText(expectedTargetID: targetID)
            }
        )
        self.clock = clock

        wireDependencies()
        refreshSecondaryAction()
    }

    func performSecondaryAction() {
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
            startInteractionTrace(kind: .submit)
            logInteractionStage("submitStarted")
            cancelRefineTask()
            cancelRecognitionTimeout()
            speechController.cancelSession()
            recordWordCorrectionEvidenceIfPossible()
            submitCurrentWorkspaceAfterOptionalRefine()
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
            configuration: currentRefineConfiguration
        )
        SpeakDockLog.refine.debug("recording phase stays clean-only; committing prepared text")
        commitRecognizedText(preparation.committedText)
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

    private func commitToCapture(_ text: String) {
        let captureRootURL = URL(
            fileURLWithPath: settingsStore.settings.captureRootPath,
            isDirectory: true
        )

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

    private func activateWorkspace(mode: Mode, targetID: String) -> Workspace {
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

    private func submitCurrentWorkspaceAfterOptionalRefine() {
        guard let workspace = workspaceState.activeWorkspace, workspace.mode == .compose else {
            finishInteractionTrace(result: .submitFailed)
            completeSubmitAction()
            return
        }

        let configuration = currentRefineConfiguration
        let preparation = currentWorkspaceRefinePreparation(
            for: workspace,
            configuration: configuration
        )

        guard preparation.shouldCallModel, !preparation.modelInputText.isEmpty else {
            submitCurrentWorkspaceIfPossible()
            completeSubmitAction()
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
                self.completeSubmitAction()
                self.activeRefineTask = nil
            }
        }
    }

    private func completeSubmitAction() {
        WorkspaceReducer.reduce(state: &workspaceState, action: .workspaceEnded)
        renderedSegmentsByWorkspaceID.removeAll()
        undoFlowState.clearPendingConfirmation()
        undoFlowState.clearRecentSubmission()
        composeTargetSession.end()
        refreshSecondaryAction()
        overlayPanelController.dismiss(after: 0.1)
    }

    private func recordWordCorrectionEvidenceIfPossible() {
        do {
            try wordCorrectionObservationRecorder.recordIfNeeded(for: workspaceState.activeWorkspace)
        } catch {
            SpeakDockLog.compose.error(
                "word correction evidence recording failed: \(error.localizedDescription, privacy: .private)"
            )
        }
    }

    private var currentRefineConfiguration: RefineConfiguration {
        RefineConfiguration(
            enabled: settingsStore.settings.refineEnabled,
            baseURL: settingsStore.settings.refineBaseURL,
            apiKey: settingsStore.settings.refineAPIKey,
            model: settingsStore.settings.refineModel
        )
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
        case .capture, .wiki:
            nil
        }
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
