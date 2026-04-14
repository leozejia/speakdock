import Foundation
import XCTest
@testable import SpeakDockMac

final class SpeechRecognitionErrorDiagnosticsTests: XCTestCase {
    func testExtractsNSErrorDomainAndCode() {
        let error = NSError(domain: "kAFAssistantErrorDomain", code: 1101)

        let diagnostics = SpeechRecognitionErrorDiagnostics(error: error)

        XCTAssertEqual(diagnostics.domain, "kAFAssistantErrorDomain")
        XCTAssertEqual(diagnostics.code, 1101)
    }
}
