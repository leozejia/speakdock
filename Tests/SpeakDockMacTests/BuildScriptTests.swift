import XCTest

final class BuildScriptTests: XCTestCase {
    func testAdHocSigningUsesStableDesignatedRequirementForTCC() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("--requirements"))
        XCTAssertTrue(script.contains("designated => identifier"))
        XCTAssertTrue(script.contains("CFBundleIdentifier"))
    }

    func testBuildScriptRefreshesAndCopiesAppIcon() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("generate-app-icon.sh"))
        XCTAssertTrue(script.contains("render-app-icon.swift"))
        XCTAssertTrue(script.contains("SpeakDock.icns"))
    }

    func testRunDevScriptDoesNotForceNewAppInstance() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-dev.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("open -W"))
        XCTAssertFalse(script.contains("open -n -W"))
    }

    func testRunDevScriptForwardsASRCorrectionEnvironmentOverrides() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-dev.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("SPEAKDOCK_ASR_CORRECTION_BASE_URL"))
        XCTAssertTrue(script.contains("SPEAKDOCK_ASR_CORRECTION_API_KEY"))
        XCTAssertTrue(script.contains("SPEAKDOCK_ASR_CORRECTION_MODEL"))
        XCTAssertTrue(script.contains("--asr-correction-base-url"))
        XCTAssertTrue(script.contains("--asr-correction-api-key"))
        XCTAssertTrue(script.contains("--asr-correction-model"))
    }

    func testBuildScriptCopiesSwiftPMResourceBundlesIntoAppResources() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains(".bundle"))
        XCTAssertTrue(script.contains("Contents/Resources"))
        XCTAssertTrue(script.contains("cp -R"))
    }

    func testBuildScriptCopiesLocalizationDirectoriesIntoMainBundleResources() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("Resources/Localization"))
        XCTAssertTrue(script.contains("*.lproj"))
        XCTAssertTrue(script.contains("mkdir -p"))
    }

    func testShowLogsScriptFiltersBySpeakDockSubsystem() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/show-logs.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("subsystem == \"com.leozejia.speakdock\""))
        XCTAssertTrue(script.contains("/usr/bin/log"))
        XCTAssertTrue(script.contains("--info"))
        XCTAssertTrue(script.contains("--debug"))
        XCTAssertTrue(script.contains("--last"))
    }

    func testShowTracesScriptFiltersByTraceCategory() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/show-traces.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("subsystem == \"com.leozejia.speakdock\""))
        XCTAssertTrue(script.contains("category == \"trace\""))
        XCTAssertTrue(script.contains("trace.finish"))
        XCTAssertTrue(script.contains("/usr/bin/log"))
    }

    func testShowSpeechLogsScriptFiltersBySpeechCategory() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/show-speech-logs.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("subsystem == \"com.leozejia.speakdock\""))
        XCTAssertTrue(script.contains("category == \"speech\""))
        XCTAssertTrue(script.contains("/usr/bin/log"))
    }

    func testMakefileExposesTraceReportCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-traces.py")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("trace-report:"))
        XCTAssertTrue(makefile.contains("report-traces.py"))
        XCTAssertTrue(script.contains("Trace Report"))
        XCTAssertTrue(script.contains("trace.finish"))
        XCTAssertTrue(script.contains("/usr/bin/log"))
    }

    func testMakefileExposesSpeechErrorReportCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-speech-errors.py")

        XCTAssertTrue(makefile.contains("speech-error-report:"))
        XCTAssertTrue(makefile.contains("report-speech-errors.py"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
    }

    func testMakefileExposesASRCorrectionReportCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-asr-correction.py")

        XCTAssertTrue(makefile.contains("asr-correction-report:"))
        XCTAssertTrue(makefile.contains("report-asr-correction.py"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
    }

    func testMakefileExposesASRSampleReportCommandAcrossSpeechAndCorrectionReports() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("ASR_EVAL_THRESHOLD ?= 20"))
        XCTAssertTrue(makefile.contains("asr-sample-report:"))
        XCTAssertTrue(makefile.contains("report-speech-errors.py"))
        XCTAssertTrue(makefile.contains("report-asr-correction.py --last $(LOG_WINDOW) --min-samples $(ASR_EVAL_THRESHOLD)"))
    }

    func testMakefileExposesASRPostCorrectionEvalReportCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-asr-post-correction-eval.py")

        XCTAssertTrue(makefile.contains("ASR_POST_CORRECTION_FIXTURE ?="))
        XCTAssertTrue(makefile.contains("ASR_POST_CORRECTION_RESULTS ?="))
        XCTAssertTrue(makefile.contains("asr-post-correction-eval-report:"))
        XCTAssertTrue(makefile.contains("report-asr-post-correction-eval.py --fixture $(ASR_POST_CORRECTION_FIXTURE) --results $(ASR_POST_CORRECTION_RESULTS)"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
    }

    func testMakefileExposesASRPostCorrectionEvalRunnerCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-asr-post-correction-eval.py")

        XCTAssertTrue(makefile.contains("ASR_POST_CORRECTION_PYTHON ?="))
        XCTAssertTrue(makefile.contains("ASR_POST_CORRECTION_MODEL ?="))
        XCTAssertTrue(makefile.contains("ASR_POST_CORRECTION_PROMPT_PROFILE ?= fewshot_terms_homophone"))
        XCTAssertTrue(makefile.contains("asr-post-correction-eval:"))
        XCTAssertTrue(makefile.contains("$(ASR_POST_CORRECTION_PYTHON) ./scripts/run-asr-post-correction-eval.py --fixture $(ASR_POST_CORRECTION_FIXTURE) --results $(ASR_POST_CORRECTION_RESULTS) --model-path $(ASR_POST_CORRECTION_MODEL) --prompt-profile $(ASR_POST_CORRECTION_PROMPT_PROFILE)"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
    }

    func testMakefileExposesASRPostCorrectionOpenAIEvalCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-asr-post-correction-openai-eval.sh")
        let envExampleURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".env.example")

        XCTAssertTrue(makefile.contains("asr-post-correction-openai-eval:"))
        XCTAssertTrue(makefile.contains("./scripts/run-asr-post-correction-openai-eval.sh $(ASR_POST_CORRECTION_PYTHON) $(ASR_POST_CORRECTION_FIXTURE) $(ASR_POST_CORRECTION_RESULTS) $(ASR_POST_CORRECTION_PROMPT_PROFILE)"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: envExampleURL.path))
    }

    func testMakefileExposesSpeechLogsCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/show-speech-logs.sh")

        XCTAssertTrue(makefile.contains("speech-logs:"))
        XCTAssertTrue(makefile.contains("show-speech-logs.sh"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
    }

    func testMakefileExposesTermLearningReportCommandAndScript() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/report-term-learning.py")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("term-learning-report:"))
        XCTAssertTrue(makefile.contains("report-term-learning.py"))
        XCTAssertTrue(script.contains("Term Learning Report"))
        XCTAssertTrue(script.contains("learning events"))
    }

    func testMakefileExposesFixtureDrivenTermLearningSmokeTargets() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-term-learning:"))
        XCTAssertTrue(makefile.contains("smoke-term-learning-conflict:"))
        XCTAssertTrue(makefile.contains("SMOKE_TERM_LEARNING_SCENARIO=conflict"))
    }

    func testComposeProbeScriptLaunchesSpeakDockBundleWithProbeArguments() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-compose-probe.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("scripts/build-app.sh"))
        XCTAssertTrue(script.contains("open -n -W"))
        XCTAssertTrue(script.contains("--args --probe-compose --probe-compose-duration"))
        XCTAssertTrue(script.contains("--probe-compose-result-file"))
    }

    func testComposeProbeScriptReportsMinimalAXVerdict() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-compose-probe.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("Compose probe verdict:"))
        XCTAssertTrue(script.contains("available"))
        XCTAssertTrue(script.contains("no-target"))
        XCTAssertTrue(script.contains("unavailable"))
        XCTAssertTrue(script.contains("exit 1"))
    }

    func testBuildTestHostScriptBuildsHostBundle() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/build-test-host.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("--product SpeakDockTestHost"))
        XCTAssertTrue(script.contains("SpeakDockTestHost.app"))
        XCTAssertTrue(script.contains("Sources/SpeakDockTestHost/Resources/Info.plist"))
    }

    func testSmokeComposeScriptLaunchesSmokeModeAgainstTestHost() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-compose.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("build-test-host.sh"))
        XCTAssertTrue(script.contains("tell application id \"com.leozejia.speakdock.testhost\" to activate"))
        XCTAssertTrue(script.contains("--smoke-hot-path"))
        XCTAssertTrue(script.contains("--smoke-text"))
        XCTAssertTrue(script.contains("SpeakDockTestHost"))
    }

    func testMakefileExposesComposeContinuationSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-compose-continue:"))
        XCTAssertTrue(makefile.contains("SMOKE_COMPOSE_SCENARIO=continue"))
    }

    func testMakefileExposesComposeUndoSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-compose-undo:"))
        XCTAssertTrue(makefile.contains("SMOKE_COMPOSE_SCENARIO=undo"))
    }

    func testMakefileExposesComposeSwitchUndoSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-compose-switch-undo:"))
        XCTAssertTrue(makefile.contains("SMOKE_COMPOSE_SCENARIO=switch-undo"))
    }

    func testSmokeComposeScriptSupportsContinuationScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-compose.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("SMOKE_COMPOSE_SCENARIO"))
        XCTAssertTrue(script.contains("continue"))
        XCTAssertTrue(script.contains("--command-file"))
        XCTAssertTrue(script.contains("--smoke-hot-path-phase"))
        XCTAssertTrue(script.contains("--smoke-text-2"))
    }

    func testSmokeComposeScriptSupportsUndoScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-compose.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("undo"))
        XCTAssertTrue(script.contains("undo-recent-submission"))
        XCTAssertTrue(script.contains("Smoke compose undo passed."))
    }

    func testSmokeComposeScriptSupportsSwitchUndoScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-compose.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("switch-undo"))
        XCTAssertTrue(script.contains("switch-target-undo-recent-submission"))
        XCTAssertTrue(script.contains("Smoke compose switch undo passed."))
    }

    func testMakefileExposesCaptureContinuationSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-capture-continue:"))
        XCTAssertTrue(makefile.contains("SMOKE_CAPTURE_SCENARIO=continue"))
    }

    func testSmokeCaptureScriptSupportsContinuationScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-capture.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("SMOKE_CAPTURE_SCENARIO"))
        XCTAssertTrue(script.contains("capture-continue-after-observed-edit"))
        XCTAssertTrue(script.contains("--smoke-capture-root"))
        XCTAssertTrue(script.contains("find_capture_file"))
    }

    func testMakefileExposesCaptureUndoSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-capture-undo:"))
        XCTAssertTrue(makefile.contains("SMOKE_CAPTURE_SCENARIO=undo"))
    }

    func testSmokeCaptureScriptSupportsUndoScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-capture.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("capture-undo-recent-submission"))
        XCTAssertTrue(script.contains("Smoke capture undo passed."))
        XCTAssertTrue(script.contains("undo)"))
    }

    func testSmokeRefineScriptLaunchesLocalRefineStubAndSmokeMode() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("run-refine-stub-server.py"))
        XCTAssertTrue(script.contains("tell application id \"com.leozejia.speakdock.testhost\" to activate"))
        XCTAssertTrue(script.contains("--smoke-refine"))
        XCTAssertTrue(script.contains("--smoke-refine-base-url"))
        XCTAssertTrue(script.contains("SpeakDockTestHost"))
    }

    func testMakefileExposesRefineFallbackSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-refine-fallback:"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_SCENARIO=fallback"))
    }

    func testMakefileExposesCaptureRefineFallbackSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-capture-refine-fallback:"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_TARGET=capture"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_SCENARIO=manual-fallback"))
    }

    func testSmokeRefineScriptSupportsFallbackScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("SMOKE_REFINE_SCENARIO"))
        XCTAssertTrue(script.contains("--status-code"))
        XCTAssertTrue(script.contains("fallback"))
    }

    func testSmokeRefineScriptSupportsManualFallbackScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("manual-fallback"))
        XCTAssertTrue(script.contains("APP_REFINE_PHASE=\"manual\""))
    }

    func testMakefileExposesManualRefineSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-refine-manual:"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_SCENARIO=manual"))
    }

    func testSmokeRefineScriptSupportsManualScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("manual"))
        XCTAssertTrue(script.contains("--smoke-refine-phase"))
    }

    func testMakefileExposesCaptureManualRefineSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-capture-refine-manual:"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_TARGET=capture"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_SCENARIO=manual"))
    }

    func testSmokeRefineScriptSupportsCaptureTargetScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("SMOKE_REFINE_TARGET"))
        XCTAssertTrue(script.contains("--smoke-refine-target"))
        XCTAssertTrue(script.contains("--smoke-capture-root"))
        XCTAssertTrue(script.contains("find_capture_file"))
    }

    func testMakefileExposesDirtyUndoRefineSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-refine-dirty-undo:"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_SCENARIO=dirty-undo"))
    }

    func testMakefileExposesCaptureDirtyUndoRefineSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-capture-refine-dirty-undo:"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_TARGET=capture"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_SCENARIO=dirty-undo"))
    }

    func testSmokeRefineScriptSupportsDirtyUndoScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("dirty-undo"))
        XCTAssertTrue(script.contains("--command-file"))
    }

    func testSmokeRefineScriptSupportsCaptureDirtyUndoScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("wait_for_capture_text \"$HOST_COMMAND_TRIGGER_TEXT\""))
        XCTAssertTrue(script.contains("print -n -- \"$HOST_COMMAND_TEXT\" > \"$capture_file\""))
    }

    func testMakefileExposesSubmitObservedEditRefineSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-refine-submit-sync:"))
        XCTAssertTrue(makefile.contains("SMOKE_REFINE_SCENARIO=submit-observed-edit"))
    }

    func testMakefileExposesMixedLanguageRefineSmokeTargets() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-refine-mixed:"))
        XCTAssertTrue(makefile.contains("smoke-refine-mixed-manual:"))
        XCTAssertTrue(makefile.contains("api key fallback"))
        XCTAssertTrue(makefile.contains("apiKey fallback"))
        XCTAssertTrue(makefile.contains("push dev/internal"))
    }

    func testMakefileExposesASRCorrectionSmokeTarget() throws {
        let makefileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Makefile")
        let makefile = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(makefile.contains("smoke-asr-correction:"))
        XCTAssertTrue(makefile.contains("run-smoke-asr-correction.sh"))
    }

    func testSmokeRefineScriptSupportsSubmitObservedEditScenario() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-refine.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("submit-observed-edit"))
        XCTAssertTrue(script.contains("--record-user-message"))
        XCTAssertTrue(script.contains("request.txt"))
    }

    func testSmokeASRCorrectionScriptLaunchesLocalStubAndDedicatedSmokeMode() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-asr-correction.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("run-refine-stub-server.py"))
        XCTAssertTrue(script.contains("SMOKE_ASR_CORRECTION_PROVIDER"))
        XCTAssertTrue(script.contains("--asr-correction-provider"))
        XCTAssertTrue(script.contains("SPEAKDOCK_MLX_LM_SERVER_STUB_RESPONSE_TEXT"))
        XCTAssertTrue(script.contains("run-mlx-lm-server-stub.sh"))
        XCTAssertTrue(script.contains("--on-device-asr-correction-executable"))
        XCTAssertTrue(script.contains("tell application id \"com.leozejia.speakdock.testhost\" to activate"))
        XCTAssertTrue(script.contains("--smoke-asr-correction"))
        XCTAssertTrue(script.contains("--asr-correction-base-url"))
        XCTAssertTrue(script.contains("SpeakDockTestHost"))
    }

    func testRefineStubServerCanAdvertiseModelsForOnDeviceSmoke() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-refine-stub-server.py")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("--advertised-model"))
        XCTAssertTrue(script.contains("/v1/models"))
        XCTAssertTrue(script.contains("\"data\": models"))
    }

    func testSmokeTermLearningScriptLaunchesSmokeModeAgainstIsolatedTermDictionaryStore() throws {
        let scriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/run-smoke-term-learning.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("build-test-host.sh"))
        XCTAssertTrue(script.contains("SMOKE_TERM_LEARNING_FIXTURE"))
        XCTAssertTrue(script.contains("SMOKE_TERM_LEARNING_SCENARIO"))
        XCTAssertTrue(script.contains("term-learning-anonymous-baseline.json"))
        XCTAssertTrue(script.contains("tell application id \"com.leozejia.speakdock.testhost\" to activate"))
        XCTAssertTrue(script.contains("--smoke-term-learning"))
        XCTAssertTrue(script.contains("--smoke-term-dictionary-storage"))
        XCTAssertTrue(script.contains("SpeakDockTestHost"))
    }
}
