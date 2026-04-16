import Foundation

struct TermDictionaryLearningEvent: Codable, Equatable {
    enum Outcome: String, Codable, Equatable {
        case observed
        case promoted
        case conflicted
        case skippedConfirmed
    }

    var canonicalTerm: String
    var alias: String
    var outcome: Outcome
    var evidenceCount: Int
}
