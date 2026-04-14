import Foundation

struct SpeechRecognitionErrorDiagnostics: Equatable {
    let domain: String
    let code: Int

    init(error: Error) {
        let nsError = error as NSError
        domain = nsError.domain
        code = nsError.code
    }
}
