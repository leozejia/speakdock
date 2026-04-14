import ApplicationServices

enum ComposeTargetFallbackPolicy {
    static func shouldQueryFrontmostApplication(afterSystemWideFocusedElementError error: AXError) -> Bool {
        error == .noValue || error == .attributeUnsupported
    }
}
