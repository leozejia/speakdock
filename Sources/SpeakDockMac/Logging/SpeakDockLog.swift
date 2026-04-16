import OSLog

enum SpeakDockLog {
    static let subsystem = "com.leozejia.speakdock"

    enum Category: String, CaseIterable {
        case lifecycle
        case permission
        case trace
        case trigger
        case audio
        case speech
        case compose
        case capture
        case refine
    }

    static let lifecycle = logger(.lifecycle)
    static let permission = logger(.permission)
    static let trace = logger(.trace)
    static let trigger = logger(.trigger)
    static let audio = logger(.audio)
    static let speech = logger(.speech)
    static let compose = logger(.compose)
    static let capture = logger(.capture)
    static let refine = logger(.refine)

    static func logger(_ category: Category) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }
}
