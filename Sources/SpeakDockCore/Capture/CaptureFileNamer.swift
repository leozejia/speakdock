import Foundation

public struct CaptureFileNamer: Sendable {
    private let timeZoneIdentifier: String

    public init(timeZone: TimeZone = .current) {
        self.timeZoneIdentifier = timeZone.identifier
    }

    public func makeFileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "speakdock-\(formatter.string(from: date)).md"
    }
}
