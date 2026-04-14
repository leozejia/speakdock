import AppKit
import ApplicationServices

enum ComposeTargetAvailability: Equatable {
    case available(targetID: String)
    case noTarget
    case unavailable(reason: String)
}

enum ClipboardComposeTargetError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case let .unavailable(reason):
            reason
        }
    }
}

@MainActor
final class ClipboardComposeTarget {
    private struct FocusedEditableTarget {
        let element: AXUIElement
        let targetID: String
    }

    private let pasteboard: NSPasteboard
    private let inputSourceSwitcher: InputSourceSwitcher
    private let workspace: NSWorkspace
    private var capturedTarget: FocusedEditableTarget?

    init(
        pasteboard: NSPasteboard = .general,
        inputSourceSwitcher: InputSourceSwitcher = InputSourceSwitcher(),
        workspace: NSWorkspace = .shared
    ) {
        self.pasteboard = pasteboard
        self.inputSourceSwitcher = inputSourceSwitcher
        self.workspace = workspace
    }

    func availability() -> ComposeTargetAvailability {
        focusedEditableTargetAvailability(captureTarget: false)
    }

    func captureCurrentTarget() -> ComposeTargetAvailability {
        focusedEditableTargetAvailability(captureTarget: true)
    }

    private func focusedEditableTargetAvailability(captureTarget: Bool) -> ComposeTargetAvailability {
        guard AXIsProcessTrusted() else {
            if captureTarget {
                capturedTarget = nil
                SpeakDockLog.permission.warning("compose target capture failed: accessibility not trusted")
            }
            return .unavailable(reason: "Compose Unavailable")
        }

        let frontmostBundleIdentifier = workspace.frontmostApplication?.bundleIdentifier ?? "unknown"
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        switch error {
        case .success:
            guard let focusedValue else {
                if captureTarget {
                    capturedTarget = nil
                    SpeakDockLog.compose.debug(
                        "compose target capture found no focused element: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                    )
                }
                return .noTarget
            }

            let focusedElement = focusedValue as! AXUIElement
            if captureTarget {
                logFocusedElementSnapshot(focusedElement, frontmostBundleIdentifier: frontmostBundleIdentifier)
            }

            if isEditableTextElement(focusedElement) {
                let target = FocusedEditableTarget(
                    element: focusedElement,
                    targetID: targetIdentifier(for: focusedElement)
                )
                if captureTarget {
                    capturedTarget = target
                    SpeakDockLog.compose.notice(
                        "compose target capture succeeded: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                    )
                }
                return .available(targetID: target.targetID)
            }

            if captureTarget {
                capturedTarget = nil
                SpeakDockLog.compose.debug(
                    "compose target capture rejected focused element: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                )
            }
            if isClearlyNonTextTarget(focusedElement) {
                return .noTarget
            }

            return .unavailable(reason: "Compose Unavailable")

        case .noValue, .attributeUnsupported:
            if captureTarget {
                capturedTarget = nil
                SpeakDockLog.compose.debug(
                    "compose target capture has no focused UI element attribute: error=\(error.rawValue, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                )
            }
            return .noTarget

        case .apiDisabled:
            if captureTarget {
                capturedTarget = nil
                SpeakDockLog.permission.warning(
                    "compose target capture failed because AX API is disabled: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                )
            }
            return .unavailable(reason: "Compose Unavailable")

        default:
            if captureTarget {
                capturedTarget = nil
                SpeakDockLog.compose.warning(
                    "compose target capture failed: error=\(error.rawValue, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                )
            }
            return .unavailable(reason: "Compose Unavailable")
        }
    }

    func inject(_ text: String, expectedTargetID: String? = nil) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return
        }

        if let expectedTargetID {
            try ensureAvailableTargetOrRestoreCapturedTarget(expectedTargetID: expectedTargetID)
        } else {
            guard case .available = availability() else {
                throw ClipboardComposeTargetError.unavailable("Compose Unavailable")
            }
        }

        let savedText = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        pasteboard.setString(trimmedText, forType: .string)

        let restoreToken = inputSourceSwitcher.prepareForASCIIInjection()
        postPasteShortcut()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.inputSourceSwitcher.restore(restoreToken)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.pasteboard.clearContents()
            if let savedText {
                self?.pasteboard.setString(savedText, forType: .string)
            }
        }
    }

    func submitCurrentTarget(expectedTargetID: String) throws {
        try ensureAvailableTarget(expectedTargetID: expectedTargetID)
        postKeyboardShortcut(keyCode: 0x24, flags: [])
    }

    func undoLastInsertion(expectedTargetID: String) throws {
        try ensureAvailableTarget(expectedTargetID: expectedTargetID)
        postKeyboardShortcut(keyCode: 0x06, flags: .maskCommand)
    }

    func replaceWorkspaceText(
        with text: String,
        undoCount: Int,
        expectedTargetID: String
    ) throws {
        let effectiveUndoCount = max(undoCount, 1)
        try ensureAvailableTarget(expectedTargetID: expectedTargetID)

        for _ in 0..<effectiveUndoCount {
            postKeyboardShortcut(keyCode: 0x06, flags: .maskCommand)
            usleep(50_000)
        }

        try inject(text, expectedTargetID: expectedTargetID)
    }

    func frontmostApplicationBundleIdentifier() -> String? {
        workspace.frontmostApplication?.bundleIdentifier
    }

    private func ensureAvailableTarget(expectedTargetID: String) throws {
        guard case let .available(targetID) = availability(), targetID == expectedTargetID else {
            throw ClipboardComposeTargetError.unavailable("Compose Unavailable")
        }
    }

    private func ensureAvailableTargetOrRestoreCapturedTarget(expectedTargetID: String) throws {
        if case let .available(targetID) = availability(), targetID == expectedTargetID {
            return
        }

        guard let capturedTarget, capturedTarget.targetID == expectedTargetID else {
            throw ClipboardComposeTargetError.unavailable("Compose Unavailable")
        }

        restoreFocus(to: capturedTarget.element)
        guard case let .available(targetID) = availability(), targetID == expectedTargetID else {
            throw ClipboardComposeTargetError.unavailable("Compose Unavailable")
        }
    }

    private func postPasteShortcut() {
        postKeyboardShortcut(keyCode: 0x09, flags: .maskCommand)
    }

    private func postKeyboardShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        let eventSource = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags

        let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags

        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }

    private func restoreFocus(to element: AXUIElement) {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)

        NSRunningApplication(processIdentifier: pid)?.activate(
            from: .current,
            options: []
        )
        AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)

        let applicationElement = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(
            applicationElement,
            kAXFocusedUIElementAttribute as CFString,
            element
        )
        usleep(50_000)
    }

    private func isEditableTextElement(_ element: AXUIElement) -> Bool {
        guard boolAttribute(kAXEnabledAttribute, on: element) ?? true else {
            return false
        }

        if boolAttribute("AXEditable", on: element) == true {
            return true
        }

        guard let role = stringAttribute(kAXRoleAttribute, on: element) else {
            return false
        }

        if role == kAXTextFieldRole as String || role == kAXTextAreaRole as String || role == "AXSearchField" {
            return true
        }

        return false
    }

    private func logFocusedElementSnapshot(_ element: AXUIElement, frontmostBundleIdentifier: String) {
        let role = stringAttribute(kAXRoleAttribute, on: element) ?? "nil"
        let subrole = stringAttribute(kAXSubroleAttribute, on: element) ?? "nil"
        let axEditable = logValue(boolAttribute("AXEditable", on: element))
        let valueSettable = logValue(isAttributeSettable(kAXValueAttribute as CFString, on: element))
        let selectedTextRangeSettable = logValue(
            isAttributeSettable(kAXSelectedTextRangeAttribute as CFString, on: element)
        )

        SpeakDockLog.compose.debug(
            "compose target capture focused element: frontmost=\(frontmostBundleIdentifier, privacy: .public), role=\(role, privacy: .public), subrole=\(subrole, privacy: .public), axEditable=\(axEditable, privacy: .public), valueSettable=\(valueSettable, privacy: .public), selectedTextRangeSettable=\(selectedTextRangeSettable, privacy: .public)"
        )
    }

    private func isClearlyNonTextTarget(_ element: AXUIElement) -> Bool {
        guard let role = stringAttribute(kAXRoleAttribute, on: element) else {
            return false
        }

        return [
            kAXApplicationRole as String,
            kAXWindowRole as String,
            kAXButtonRole as String,
            kAXGroupRole as String,
            kAXScrollAreaRole as String,
            kAXToolbarRole as String,
            kAXSplitGroupRole as String,
            kAXLayoutAreaRole as String,
            kAXImageRole as String,
            kAXMenuBarRole as String,
            kAXMenuItemRole as String,
        ].contains(role)
    }

    private func targetIdentifier(for element: AXUIElement) -> String {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        let role = stringAttribute(kAXRoleAttribute, on: element) ?? "unknown"
        let title = stringAttribute(kAXTitleAttribute, on: element) ?? ""
        return "\(pid):\(role):\(title)"
    }

    private func boolAttribute(_ attribute: String, on element: AXUIElement) -> Bool? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return nil
        }

        return (value as? NSNumber)?.boolValue
    }

    private func isAttributeSettable(_ attribute: CFString, on element: AXUIElement) -> Bool? {
        var isSettable = DarwinBoolean(false)
        let error = AXUIElementIsAttributeSettable(element, attribute, &isSettable)
        guard error == .success else {
            return nil
        }

        return isSettable.boolValue
    }

    private func stringAttribute(_ attribute: String, on element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return nil
        }

        return value as? String
    }

    private func logValue(_ value: Bool?) -> String {
        guard let value else {
            return "nil"
        }

        return value ? "true" : "false"
    }
}
