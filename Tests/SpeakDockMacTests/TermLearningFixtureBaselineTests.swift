import XCTest
@testable import SpeakDockMac
import SpeakDockCore

@MainActor
final class TermLearningFixtureBaselineTests: XCTestCase {
    func testAnonymousFixtureReplaysIntoExpectedSnapshot() throws {
        let fixture = try TermLearningFixtureSupport.loadFixture()
        let replayResult = try TermLearningFixtureSupport.replayFixture(fixture)
        let snapshot = replayResult.snapshot

        XCTAssertEqual(snapshot.pendingCandidates, [])
        XCTAssertEqual(snapshot.confirmedEntries, fixture.expectations.confirmedEntries)
        XCTAssertEqual(
            TermLearningFixtureSupport.sortedObservedCorrections(snapshot.observedCorrections),
            TermLearningFixtureSupport.sortedObservedCorrections(fixture.expectations.observedCorrections)
        )
        XCTAssertEqual(
            TermLearningFixtureSupport.outcomeCounts(from: snapshot),
            fixture.expectations.outcomeCounts
        )
    }

    func testAnonymousFixtureDefinesFixtureDrivenSmokeScenarios() throws {
        let fixture = try TermLearningFixtureSupport.loadFixture()

        let scenarios = try XCTUnwrap(fixture.smokeScenarios)
        let promotion = try XCTUnwrap(scenarios["promotion"])
        let conflict = try XCTUnwrap(scenarios["conflict"])

        XCTAssertEqual(promotion.cycles.count, 3)
        XCTAssertEqual(
            promotion.finalCheck,
            .init(inputText: "project adults 已完成", expectedText: "Project Atlas 已完成")
        )

        XCTAssertEqual(conflict.cycles.count, 4)
        XCTAssertEqual(
            conflict.finalCheck,
            .init(inputText: "pilot one 已经开始", expectedText: "pilot one 已经开始")
        )
    }

    func testAnonymousFixtureSmokeScenariosMatchDictionaryOutcomes() throws {
        let fixture = try TermLearningFixtureSupport.loadFixture()
        let scenarios = try XCTUnwrap(fixture.smokeScenarios)

        try assertScenario("promotion", fixture: fixture, scenarios: scenarios)
        try assertScenario("conflict", fixture: fixture, scenarios: scenarios)
    }

    private func assertScenario(
        _ scenarioName: String,
        fixture: TermLearningFixture,
        scenarios: [String: TermLearningFixture.SmokeScenario]
    ) throws {
        let scenario = try XCTUnwrap(scenarios[scenarioName])
        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("term-learning-scenario-\(scenarioName)-\(UUID().uuidString).json")
        let store = TermDictionaryStore(storageURL: storageURL, fileManager: .default)
        store.confirmedDictionary = TermDictionary(entries: fixture.initialConfirmedEntries)

        for cycle in scenario.cycles {
            try store.recordManualCorrection(
                generatedText: cycle.generatedText,
                correctedText: cycle.correctedText
            )
        }

        let rewritten = store.confirmedDictionary.applying(to: scenario.finalCheck.inputText)
        XCTAssertEqual(rewritten, scenario.finalCheck.expectedText)
    }
}
