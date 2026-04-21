import Foundation

struct ASRPostCorrectionFixture: Decodable {
    struct Sample: Decodable, Equatable {
        enum Bucket: String, Decodable, CaseIterable {
            case term
            case mixed
            case homophone
            case control
        }

        let id: String
        let bucket: Bucket
        let input: String
        let expected: String
        let shouldChange: Bool
        let source: String
        let notes: String

        private enum CodingKeys: String, CodingKey {
            case id
            case bucket
            case input
            case expected
            case shouldChange = "should_change"
            case source
            case notes
        }
    }

    let samples: [Sample]

    var bucketCounts: [String: Int] {
        samples.reduce(into: [:]) { partialResult, sample in
            partialResult[sample.bucket.rawValue, default: 0] += 1
        }
    }
}

enum ASRPostCorrectionFixtureSupport {
    static func loadFixture(
        named fixtureName: String = "asr-post-correction-anonymous-baseline"
    ) throws -> ASRPostCorrectionFixture {
        guard let fixtureURL = Bundle.module.url(
            forResource: fixtureName,
            withExtension: "json"
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode(ASRPostCorrectionFixture.self, from: data)
    }
}
