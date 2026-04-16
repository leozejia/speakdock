import AppKit
import Foundation
import SpeakDockCore

@MainActor
final class CaptureFileTarget {
    private struct LastAppend: Equatable {
        let fileURL: URL
        let text: String
    }

    private let fileManager: FileManager
    private let namer: CaptureFileNamer
    private let workspace: NSWorkspace
    private let now: () -> Date
    private let opensFilesOnFirstWrite: Bool

    private(set) var activeFileURL: URL?
    private var activeEditorBundleIdentifier: String?
    private var lastAppend: LastAppend?

    init(
        fileManager: FileManager = .default,
        namer: CaptureFileNamer = CaptureFileNamer(),
        workspace: NSWorkspace = .shared,
        now: @escaping () -> Date = Date.init,
        opensFilesOnFirstWrite: Bool = true
    ) {
        self.fileManager = fileManager
        self.namer = namer
        self.workspace = workspace
        self.now = now
        self.opensFilesOnFirstWrite = opensFilesOnFirstWrite
    }

    func write(_ text: String, captureRootURL: URL) throws -> URL {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return activeFileURL ?? captureRootURL
        }

        try fileManager.createDirectory(at: captureRootURL, withIntermediateDirectories: true)

        let isFirstWrite = activeFileURL == nil
        let fileURL = activeFileURL ?? captureRootURL.appendingPathComponent(namer.makeFileName(for: now()))

        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }

        try append(trimmedText, to: fileURL)
        lastAppend = LastAppend(fileURL: fileURL, text: trimmedText)

        if isFirstWrite {
            activeFileURL = fileURL
            if opensFilesOnFirstWrite {
                activeEditorBundleIdentifier = workspace
                    .urlForApplication(toOpen: fileURL)
                    .flatMap { url in
                        Bundle(url: url)?.bundleIdentifier
                    }
                workspace.open(fileURL)
            }
        }

        return fileURL
    }

    func shouldContinueCapture(frontmostBundleIdentifier: String?) -> Bool {
        guard activeFileURL != nil else {
            return false
        }

        guard let activeEditorBundleIdentifier else {
            return true
        }

        return frontmostBundleIdentifier == activeEditorBundleIdentifier
    }

    func resetSession() {
        activeFileURL = nil
        activeEditorBundleIdentifier = nil
        lastAppend = nil
    }

    func replaceContents(with text: String, targetID: String) throws {
        let fileURL = URL(fileURLWithPath: targetID)
        let data = text.data(using: .utf8) ?? Data()
        try data.write(to: fileURL)
        activeFileURL = fileURL
        lastAppend = nil
    }

    func observedWorkspaceText(expectedTargetID: String) -> String? {
        let fileURL = URL(fileURLWithPath: expectedTargetID)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try? existingContents(of: fileURL)
    }

    func undoLastAppend(
        expectedTargetID: String,
        committedText: String
    ) throws {
        guard let activeFileURL else {
            return
        }

        guard activeFileURL.path == expectedTargetID else {
            return
        }

        let rollbackText = lastAppend?.text ?? committedText
        var contents = try existingContents(of: activeFileURL)

        if contents.hasSuffix("\n\(rollbackText)") {
            contents.removeLast(rollbackText.count + 1)
        } else if contents.hasSuffix(rollbackText) {
            contents.removeLast(rollbackText.count)
        }

        let data = contents.data(using: .utf8) ?? Data()
        try data.write(to: activeFileURL)
        lastAppend = nil
    }

    private func append(_ text: String, to fileURL: URL) throws {
        let needsSeparator = (try? existingContents(of: fileURL).isEmpty == false) == true
        let payload = "\(needsSeparator ? "\n" : "")\(text)"

        let handle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? handle.close()
        }

        try handle.seekToEnd()
        if let data = payload.data(using: .utf8) {
            try handle.write(contentsOf: data)
        }
    }

    private func existingContents(of fileURL: URL) throws -> String {
        guard let data = fileManager.contents(atPath: fileURL.path) else {
            return ""
        }

        return String(decoding: data, as: UTF8.self)
    }
}
