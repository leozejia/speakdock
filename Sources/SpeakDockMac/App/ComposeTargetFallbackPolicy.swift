import ApplicationServices

enum ComposeTargetFallbackPolicy {
    static func shouldQueryFrontmostApplication(afterSystemWideFocusedElementError error: AXError) -> Bool {
        error == .noValue || error == .attributeUnsupported
    }

    static func shouldUsePasteOnlyFrontmostApplicationFallback(bundleIdentifier: String) -> Bool {
        bundleIdentifier == "com.tencent.xinWeChat"
    }
}
