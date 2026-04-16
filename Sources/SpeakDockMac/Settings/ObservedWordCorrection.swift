import Foundation

struct ObservedWordCorrection: Codable, Equatable {
    var canonicalTerm: String
    var alias: String
    var evidenceCount: Int
}
