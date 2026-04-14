import Foundation
import Observation
import SpeakDockCore

@MainActor
@Observable
final class TermDictionaryStore {
    static let defaultDirectoryURL: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
    }()

    static let defaultStorageURL = defaultDirectoryURL
        .appendingPathComponent("SpeakDock", isDirectory: true)
        .appendingPathComponent("term-dictionary.json")

    var confirmedDictionary: TermDictionary {
        didSet {
            persistIfReady()
        }
    }

    var pendingCandidates: [TermDictionaryCandidate] {
        didSet {
            persistIfReady()
        }
    }

    private let storageURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var isReady = false

    init(
        storageURL: URL = TermDictionaryStore.defaultStorageURL,
        fileManager: FileManager = .default
    ) {
        self.storageURL = storageURL
        self.fileManager = fileManager

        let snapshot = Self.loadSnapshot(
            from: storageURL,
            using: JSONDecoder(),
            fileManager: fileManager
        )
        self.confirmedDictionary = TermDictionary(entries: snapshot.confirmedEntries)
        self.pendingCandidates = snapshot.pendingCandidates
        self.isReady = true
    }

    func save() throws {
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let snapshot = Snapshot(
            confirmedEntries: confirmedDictionary.entries,
            pendingCandidates: pendingCandidates
        )
        let data = try encoder.encode(snapshot)
        try data.write(to: storageURL, options: .atomic)
    }

    func reload() {
        let snapshot = Self.loadSnapshot(
            from: storageURL,
            using: decoder,
            fileManager: fileManager
        )
        confirmedDictionary = TermDictionary(entries: snapshot.confirmedEntries)
        pendingCandidates = snapshot.pendingCandidates
    }

    private func persistIfReady() {
        guard isReady else {
            return
        }

        try? save()
    }

    private static func loadSnapshot(
        from storageURL: URL,
        using decoder: JSONDecoder,
        fileManager: FileManager
    ) -> Snapshot {
        guard
            fileManager.fileExists(atPath: storageURL.path),
            let data = try? Data(contentsOf: storageURL),
            let snapshot = try? decoder.decode(Snapshot.self, from: data)
        else {
            return Snapshot(
                confirmedEntries: [],
                pendingCandidates: []
            )
        }

        return snapshot
    }
}

private struct Snapshot: Codable, Equatable {
    var confirmedEntries: [TermDictionaryEntry]
    var pendingCandidates: [TermDictionaryCandidate]
}
