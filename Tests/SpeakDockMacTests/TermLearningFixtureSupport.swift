import Foundation
@testable import SpeakDockMac
import SpeakDockCore

struct TermLearningObservedCorrection: Decodable, Equatable {
    let canonicalTerm: String
    let alias: String
    let evidenceCount: Int
}

struct TermLearningFixture: Decodable {
    struct Correction: Decodable {
        let generatedText: String
        let correctedText: String
    }

    struct Expectations: Decodable {
        let confirmedEntries: [TermDictionaryEntry]
        let observedCorrections: [TermLearningObservedCorrection]
        let outcomeCounts: [String: Int]
    }

    let name: String
    let initialConfirmedEntries: [TermDictionaryEntry]
    let corrections: [Correction]
    let expectations: Expectations
}

struct TermLearningFixtureSnapshot: Decodable {
    struct LearningEvent: Decodable {
        let canonicalTerm: String
        let alias: String
        let outcome: String
        let evidenceCount: Int
    }

    let confirmedEntries: [TermDictionaryEntry]
    let pendingCandidates: [TermDictionaryCandidate]
    let observedCorrections: [TermLearningObservedCorrection]
    let learningEvents: [LearningEvent]
}

struct TermLearningFixtureReplayResult {
    let storageURL: URL
    let snapshot: TermLearningFixtureSnapshot
}

enum TermLearningFixtureSupport {
    static func loadFixture(named fixtureName: String = "term-learning-anonymous-baseline") throws -> TermLearningFixture {
        guard let fixtureURL = Bundle.module.url(
            forResource: fixtureName,
            withExtension: "json"
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode(TermLearningFixture.self, from: data)
    }

    @MainActor
    static func replayFixture(
        _ fixture: TermLearningFixture,
        fileManager: FileManager = .default
    ) throws -> TermLearningFixtureReplayResult {
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("term-learning-fixture-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

        let storageURL = rootDirectory.appendingPathComponent("term-dictionary.json")
        let store = TermDictionaryStore(storageURL: storageURL, fileManager: fileManager)
        store.confirmedDictionary = TermDictionary(entries: fixture.initialConfirmedEntries)

        for correction in fixture.corrections {
            try store.recordManualCorrection(
                generatedText: correction.generatedText,
                correctedText: correction.correctedText
            )
        }

        let data = try Data(contentsOf: storageURL)
        let snapshot = try JSONDecoder().decode(TermLearningFixtureSnapshot.self, from: data)
        return TermLearningFixtureReplayResult(storageURL: storageURL, snapshot: snapshot)
    }

    static func outcomeCounts(from snapshot: TermLearningFixtureSnapshot) -> [String: Int] {
        snapshot.learningEvents.reduce(into: [:]) { partialResult, event in
            partialResult[event.outcome, default: 0] += 1
        }
    }

    static func sortedObservedCorrections(
        _ corrections: [TermLearningObservedCorrection]
    ) -> [TermLearningObservedCorrection] {
        corrections.sorted {
            if $0.alias != $1.alias {
                return $0.alias.localizedCaseInsensitiveCompare($1.alias) == .orderedAscending
            }
            if $0.evidenceCount != $1.evidenceCount {
                return $0.evidenceCount > $1.evidenceCount
            }
            return $0.canonicalTerm.localizedCaseInsensitiveCompare($1.canonicalTerm) == .orderedAscending
        }
    }
}
