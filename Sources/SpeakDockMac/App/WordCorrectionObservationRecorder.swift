import Foundation
import SpeakDockCore

@MainActor
struct WordCorrectionObservationRecorder {
    var termDictionaryStore: TermDictionaryStore
    var observeComposeText: (String) -> String? = { _ in nil }
    var observeCaptureText: (String) -> String? = { _ in nil }

    func recordIfNeeded(for workspace: Workspace?) throws {
        guard let workspace else {
            return
        }

        let generatedText = workspace.visibleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !generatedText.isEmpty else {
            return
        }

        let correctedText: String?
        switch workspace.mode {
        case .compose:
            correctedText = observeComposeText(workspace.targetID)
        case .capture:
            correctedText = observeCaptureText(workspace.targetID)
        case .wiki:
            correctedText = nil
        }

        guard let correctedText else {
            return
        }

        try termDictionaryStore.recordManualCorrection(
            generatedText: generatedText,
            correctedText: correctedText
        )
    }
}
