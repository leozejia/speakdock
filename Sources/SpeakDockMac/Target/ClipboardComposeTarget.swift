import AppKit
import ApplicationServices

enum ComposeTargetAvailability: Equatable {
    case available(targetID: String)
    case noTarget
    case unavailable(reason: String)
}

enum ComposeProbeVerdict: String, Equatable {
    case available = "available"
    case noTarget = "no-target"
    case unavailable = "unavailable"
}

enum ClipboardComposeTargetError: LocalizedError {
    case unavailable(String)

    static var composeUnavailableReason: String {
        AppLocalizer.string(.hotPathComposeUnavailable)
    }

    var errorDescription: String? {
        switch self {
        case let .unavailable(reason):
            reason
        }
    }
}

@MainActor
final class ClipboardComposeTarget {
    nonisolated static func composeTargetIdentifier(
        processIdentifier: pid_t,
        role: String,
        identifier: String,
        description _: String,
        windowTitle: String,
        title _: String,
        structuralPath: String
    ) -> String {
        "\(processIdentifier):\(role):\(identifier):\(windowTitle):\(structuralPath)"
    }

    nonisolated static func composeProbeVerdict(for availability: ComposeTargetAvailability) -> ComposeProbeVerdict {
        switch availability {
        case .available:
            .available
        case .noTarget:
            .noTarget
        case .unavailable:
            .unavailable
        }
    }

    nonisolated static func accumulatedComposeProbeVerdict(
        _ current: ComposeProbeVerdict?,
        availability: ComposeTargetAvailability
    ) -> ComposeProbeVerdict {
        accumulatedComposeProbeVerdict(current, next: composeProbeVerdict(for: availability))
    }

    nonisolated static func accumulatedComposeProbeVerdict(
        _ current: ComposeProbeVerdict?,
        next: ComposeProbeVerdict
    ) -> ComposeProbeVerdict {
        switch (current ?? .unavailable, next) {
        case (.available, _), (_, .available):
            .available
        case (.noTarget, _), (_, .noTarget):
            .noTarget
        default:
            .unavailable
        }
    }

    private struct FocusedEditableTarget {
        let element: AXUIElement
        let targetID: String
        let observationContext: EditableTextObservationContext?
    }

    private struct PasteOnlyApplicationTarget {
        let processIdentifier: pid_t
        let bundleIdentifier: String

        var targetID: String {
            "\(processIdentifier):paste-only:\(bundleIdentifier)"
        }
    }

    private enum CapturedTarget {
        case focusedEditableElement(FocusedEditableTarget)
        case pasteOnlyApplication(PasteOnlyApplicationTarget)

        var targetID: String {
            switch self {
            case let .focusedEditableElement(target):
                target.targetID
            case let .pasteOnlyApplication(target):
                target.targetID
            }
        }
    }

    private let pasteboard: NSPasteboard
    private let inputSourceSwitcher: InputSourceSwitcher
    private let workspace: NSWorkspace
    private var capturedTarget: CapturedTarget?

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
            return .unavailable(reason: ClipboardComposeTargetError.composeUnavailableReason)
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
                    SpeakDockLog.compose.notice(
                        "compose target capture found no focused element: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                    )
                }
                return .noTarget
            }

            return availability(
                forFocusedElement: focusedValue as! AXUIElement,
                captureTarget: captureTarget,
                frontmostBundleIdentifier: frontmostBundleIdentifier
            )

        case .noValue, .attributeUnsupported:
            if ComposeTargetFallbackPolicy.shouldQueryFrontmostApplication(afterSystemWideFocusedElementError: error),
                let focusedElement = frontmostApplicationFocusedElement(
                    captureTarget: captureTarget,
                    frontmostBundleIdentifier: frontmostBundleIdentifier
                )
            {
                if captureTarget {
                    SpeakDockLog.compose.notice(
                        "compose target capture using frontmost application fallback: systemWideError=\(error.rawValue, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                    )
                }
                return availability(
                    forFocusedElement: focusedElement,
                    captureTarget: captureTarget,
                    frontmostBundleIdentifier: frontmostBundleIdentifier
                )
            }

            if captureTarget,
                let pasteOnlyTarget = frontmostPasteOnlyApplicationTarget(
                    frontmostBundleIdentifier: frontmostBundleIdentifier
                )
            {
                capturedTarget = .pasteOnlyApplication(pasteOnlyTarget)
                SpeakDockLog.compose.notice(
                    "compose target capture using paste-only frontmost application fallback: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                )
                return .available(targetID: pasteOnlyTarget.targetID)
            }

            if captureTarget {
                capturedTarget = nil
                SpeakDockLog.compose.notice(
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
            return .unavailable(reason: ClipboardComposeTargetError.composeUnavailableReason)

        default:
            if captureTarget {
                capturedTarget = nil
                SpeakDockLog.compose.warning(
                    "compose target capture failed: error=\(error.rawValue, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                )
            }
            return .unavailable(reason: ClipboardComposeTargetError.composeUnavailableReason)
        }
    }

    private func availability(
        forFocusedElement focusedElement: AXUIElement,
        captureTarget: Bool,
        frontmostBundleIdentifier: String
    ) -> ComposeTargetAvailability {
        if captureTarget {
            logFocusedElementSnapshot(focusedElement, frontmostBundleIdentifier: frontmostBundleIdentifier)
        }

        if isEditableTextElement(focusedElement) {
            let target = FocusedEditableTarget(
                element: focusedElement,
                targetID: targetIdentifier(for: focusedElement),
                observationContext: captureTarget ? makeObservationContext(for: focusedElement) : nil
            )
            if captureTarget {
                capturedTarget = .focusedEditableElement(target)
                SpeakDockLog.compose.notice(
                    "compose target capture succeeded: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                )
            }
            return .available(targetID: target.targetID)
        }

        if captureTarget {
            capturedTarget = nil
            SpeakDockLog.compose.notice(
                "compose target capture rejected focused element: frontmost=\(frontmostBundleIdentifier, privacy: .public)"
            )
        }
        if isClearlyNonTextTarget(focusedElement) {
            return .noTarget
        }

        return .unavailable(reason: ClipboardComposeTargetError.composeUnavailableReason)
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
                throw ClipboardComposeTargetError.unavailable(ClipboardComposeTargetError.composeUnavailableReason)
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
        try ensureAvailableTargetOrRestoreCapturedTarget(expectedTargetID: expectedTargetID)
        postKeyboardShortcut(keyCode: 0x24, flags: [])
    }

    func undoLastInsertion(expectedTargetID: String) throws {
        try ensureAvailableTargetOrRestoreCapturedTarget(expectedTargetID: expectedTargetID)
        postKeyboardShortcut(keyCode: 0x06, flags: .maskCommand)
    }

    func replaceWorkspaceText(
        with text: String,
        undoCount: Int,
        expectedTargetID: String
    ) throws {
        let effectiveUndoCount = max(undoCount, 1)
        try ensureAvailableTargetOrRestoreCapturedTarget(expectedTargetID: expectedTargetID)

        for _ in 0..<effectiveUndoCount {
            postKeyboardShortcut(keyCode: 0x06, flags: .maskCommand)
            usleep(50_000)
        }

        try inject(text, expectedTargetID: expectedTargetID)
    }

    func frontmostApplicationBundleIdentifier() -> String? {
        workspace.frontmostApplication?.bundleIdentifier
    }

    func observedWorkspaceText(expectedTargetID: String) -> String? {
        guard let target = capturedFocusedEditableTarget(expectedTargetID: expectedTargetID) else {
            return nil
        }

        guard let observationContext = target.observationContext else {
            SpeakDockLog.compose.debug("compose observation skipped because no editable text context was captured")
            return nil
        }

        do {
            try ensureAvailableTargetOrRestoreCapturedTarget(expectedTargetID: expectedTargetID)
        } catch {
            SpeakDockLog.compose.debug("compose observation skipped because target is no longer available")
            return nil
        }

        guard let fullText = stringAttribute(kAXValueAttribute, on: target.element) else {
            SpeakDockLog.compose.debug("compose observation skipped because current AX value is unavailable")
            return nil
        }

        guard let observedText = observationContext.observedText(in: fullText) else {
            SpeakDockLog.compose.debug("compose observation skipped because captured boundary no longer matches")
            return nil
        }

        return observedText
    }

    private func ensureAvailableTarget(expectedTargetID: String) throws {
        if case let .available(targetID) = availability(), targetID == expectedTargetID {
            return
        }

        if let pasteOnlyTarget = frontmostPasteOnlyApplicationTarget(),
            pasteOnlyTarget.targetID == expectedTargetID
        {
            return
        }

        throw ClipboardComposeTargetError.unavailable(ClipboardComposeTargetError.composeUnavailableReason)
    }

    private func ensureAvailableTargetOrRestoreCapturedTarget(expectedTargetID: String) throws {
        if case let .available(targetID) = availability(), targetID == expectedTargetID {
            return
        }

        guard let capturedTarget, capturedTarget.targetID == expectedTargetID else {
            throw ClipboardComposeTargetError.unavailable(ClipboardComposeTargetError.composeUnavailableReason)
        }

        switch capturedTarget {
        case let .focusedEditableElement(target):
            restoreFocus(to: target.element)
            return

        case let .pasteOnlyApplication(target):
            guard isFrontmostPasteOnlyApplicationTarget(target) else {
                throw ClipboardComposeTargetError.unavailable(ClipboardComposeTargetError.composeUnavailableReason)
            }
            return
        }
    }

    private func postPasteShortcut() {
        postKeyboardShortcut(keyCode: 0x09, flags: .maskCommand)
    }

    private func capturedFocusedEditableTarget(expectedTargetID: String) -> FocusedEditableTarget? {
        guard let capturedTarget, capturedTarget.targetID == expectedTargetID else {
            return nil
        }

        guard case let .focusedEditableElement(target) = capturedTarget else {
            return nil
        }

        return target
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

    private func frontmostApplicationFocusedElement(
        captureTarget: Bool,
        frontmostBundleIdentifier: String
    ) -> AXUIElement? {
        guard let processIdentifier = workspace.frontmostApplication?.processIdentifier, processIdentifier > 0 else {
            if captureTarget {
                SpeakDockLog.compose.notice(
                    "compose target frontmost fallback skipped: missing frontmost process identifier"
                )
            }
            return nil
        }

        let applicationElement = AXUIElementCreateApplication(processIdentifier)
        var visitedCount = 0
        let appFocusedElement = axElementLookup(kAXFocusedUIElementAttribute, on: applicationElement)
        if let focusedElement = appFocusedElement.element {
            if let editableElement = firstEditableDescendant(
                of: focusedElement,
                depth: 0,
                visitedCount: &visitedCount
            ) {
                if captureTarget {
                    SpeakDockLog.compose.notice(
                        "compose target frontmost fallback found editable descendant: source=appFocusedElement, visited=\(visitedCount, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                    )
                }
                return editableElement
            }
        }

        let focusedWindow = axElementLookup(kAXFocusedWindowAttribute, on: applicationElement)
        let mainWindow = axElementLookup(kAXMainWindowAttribute, on: applicationElement)
        let windows = axElementArrayLookup(kAXWindowsAttribute, on: applicationElement)
        let children = axElementArrayLookup(kAXChildrenAttribute, on: applicationElement)

        let primaryContainers: [(source: String, element: AXUIElement?)] = [
            ("focusedWindow", focusedWindow.element),
            ("mainWindow", mainWindow.element),
        ]
        let containerCandidates: [(source: String, element: AXUIElement)] =
            primaryContainers.compactMap { candidate in
                guard let element = candidate.element else {
                    return nil
                }
                return (candidate.source, element)
            }
            + windows.elements.enumerated().map { index, element in
                ("windows[\(index)]", element)
            }
            + children.elements.enumerated().map { index, element in
                ("appChildren[\(index)]", element)
            }

        for candidate in containerCandidates {
            if let editableElement = firstEditableDescendant(
                of: candidate.element,
                depth: 0,
                visitedCount: &visitedCount
            ) {
                if captureTarget {
                    SpeakDockLog.compose.notice(
                        "compose target frontmost fallback found editable descendant: source=\(candidate.source, privacy: .public), visited=\(visitedCount, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public)"
                    )
                }
                return editableElement
            }
        }

        if captureTarget {
            SpeakDockLog.compose.notice(
                "compose target frontmost fallback failed: appFocusedError=\(appFocusedElement.error.rawValue, privacy: .public), focusedWindowError=\(focusedWindow.error.rawValue, privacy: .public), mainWindowError=\(mainWindow.error.rawValue, privacy: .public), windowsError=\(windows.error.rawValue, privacy: .public), windowsCount=\(windows.elements.count, privacy: .public), childrenError=\(children.error.rawValue, privacy: .public), childrenCount=\(children.elements.count, privacy: .public), visited=\(visitedCount, privacy: .public), frontmost=\(frontmostBundleIdentifier, privacy: .public)"
            )
        }

        return nil
    }

    private func frontmostPasteOnlyApplicationTarget(
        frontmostBundleIdentifier: String? = nil
    ) -> PasteOnlyApplicationTarget? {
        guard let frontmostApplication = workspace.frontmostApplication else {
            return nil
        }

        let bundleIdentifier = frontmostBundleIdentifier
            ?? frontmostApplication.bundleIdentifier
            ?? "unknown"
        guard ComposeTargetFallbackPolicy.shouldUsePasteOnlyFrontmostApplicationFallback(
            bundleIdentifier: bundleIdentifier
        ) else {
            return nil
        }

        return PasteOnlyApplicationTarget(
            processIdentifier: frontmostApplication.processIdentifier,
            bundleIdentifier: bundleIdentifier
        )
    }

    private func isFrontmostPasteOnlyApplicationTarget(_ target: PasteOnlyApplicationTarget) -> Bool {
        guard let frontmostApplication = workspace.frontmostApplication else {
            return false
        }

        return frontmostApplication.processIdentifier == target.processIdentifier
            && frontmostApplication.bundleIdentifier == target.bundleIdentifier
    }

    private func firstEditableDescendant(
        of element: AXUIElement,
        depth: Int,
        visitedCount: inout Int
    ) -> AXUIElement? {
        guard depth <= 8, visitedCount < 500 else {
            return nil
        }

        visitedCount += 1

        if isEditableTextElement(element) {
            return element
        }

        let children = axDescendantCandidateElements(of: element)
        let prioritizedChildren = children.map { child in
            (element: child, isFocused: boolAttribute(kAXFocusedAttribute, on: child) == true)
        }

        for child in prioritizedChildren where child.isFocused {
            if let focusedEditableChild = firstEditableDescendant(
                of: child.element,
                depth: depth + 1,
                visitedCount: &visitedCount
            ) {
                return focusedEditableChild
            }
        }

        for child in prioritizedChildren where !child.isFocused {
            if let editableChild = firstEditableDescendant(
                of: child.element,
                depth: depth + 1,
                visitedCount: &visitedCount
            ) {
                return editableChild
            }
        }

        return nil
    }

    private func isEditableTextElement(_ element: AXUIElement) -> Bool {
        guard boolAttribute(kAXEnabledAttribute, on: element) ?? true else {
            return false
        }

        if boolAttribute("AXEditable", on: element) == true {
            return true
        }

        if isAttributeSettable(kAXSelectedTextRangeAttribute as CFString, on: element) == true {
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
        let identifier = stringAttribute("AXIdentifier", on: element) ?? "nil"
        let description = stringAttribute(kAXDescriptionAttribute, on: element) ?? "nil"
        let resolvedWindowTitle = windowTitle(for: element)
        let windowTitle = resolvedWindowTitle.isEmpty ? "nil" : resolvedWindowTitle
        let structuralPath = structuralIdentifierPath(for: element)
        let axEditable = logValue(boolAttribute("AXEditable", on: element))
        let valueSettable = logValue(isAttributeSettable(kAXValueAttribute as CFString, on: element))
        let selectedTextRangeSettable = logValue(
            isAttributeSettable(kAXSelectedTextRangeAttribute as CFString, on: element)
        )

        SpeakDockLog.compose.notice(
            "compose target capture focused element: frontmost=\(frontmostBundleIdentifier, privacy: .public), role=\(role, privacy: .public), subrole=\(subrole, privacy: .public), identifier=\(identifier, privacy: .public), description=\(description, privacy: .public), windowTitle=\(windowTitle, privacy: .public), path=\(structuralPath, privacy: .public), axEditable=\(axEditable, privacy: .public), valueSettable=\(valueSettable, privacy: .public), selectedTextRangeSettable=\(selectedTextRangeSettable, privacy: .public)"
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
        let identifier = stringAttribute("AXIdentifier", on: element) ?? ""
        let description = stringAttribute(kAXDescriptionAttribute, on: element) ?? ""
        let windowTitle = windowTitle(for: element)
        let structuralPath = structuralIdentifierPath(for: element)
        return Self.composeTargetIdentifier(
            processIdentifier: pid,
            role: role,
            identifier: identifier,
            description: description,
            windowTitle: windowTitle,
            title: title,
            structuralPath: structuralPath
        )
    }

    private func windowTitle(for element: AXUIElement) -> String {
        if let windowElement = axElementLookup(kAXWindowAttribute, on: element).element,
           let title = stringAttribute(kAXTitleAttribute, on: windowElement),
           !title.isEmpty
        {
            return title
        }

        var currentElement: AXUIElement? = element
        for _ in 0..<12 {
            guard let resolvedCurrentElement = currentElement else {
                break
            }

            let role = stringAttribute(kAXRoleAttribute, on: resolvedCurrentElement)
            if role == kAXWindowRole as String,
               let title = stringAttribute(kAXTitleAttribute, on: resolvedCurrentElement),
               !title.isEmpty
            {
                return title
            }

            currentElement = axElementLookup(kAXParentAttribute, on: resolvedCurrentElement).element
        }

        return ""
    }

    private func structuralIdentifierPath(for element: AXUIElement) -> String {
        var pathSegments: [String] = []
        var currentElement: AXUIElement? = element

        for _ in 0..<12 {
            guard let resolvedCurrentElement = currentElement else {
                break
            }

            let parentLookup = axElementLookup(kAXParentAttribute, on: resolvedCurrentElement)
            guard let parentElement = parentLookup.element else {
                break
            }

            let siblings = axElementArrayAttribute(kAXChildrenAttribute, on: parentElement)
            guard let index = siblings.firstIndex(where: { sibling in
                CFEqual(sibling, resolvedCurrentElement)
            }) else {
                break
            }

            pathSegments.append(String(index))
            currentElement = parentElement
        }

        guard !pathSegments.isEmpty else {
            return "root"
        }

        return pathSegments.reversed().joined(separator: ".")
    }

    private func makeObservationContext(for element: AXUIElement) -> EditableTextObservationContext? {
        guard let fullText = stringAttribute(kAXValueAttribute, on: element),
              let selectedRange = selectedTextRange(on: element) else {
            return nil
        }

        return EditableTextObservationContext(
            fullText: fullText,
            selectedRange: selectedRange
        )
    }

    private func boolAttribute(_ attribute: String, on element: AXUIElement) -> Bool? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return nil
        }

        return (value as? NSNumber)?.boolValue
    }

    private func axElementLookup(_ attribute: String, on element: AXUIElement) -> (element: AXUIElement?, error: AXError) {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return (nil, error)
        }

        return ((value as! AXUIElement), error)
    }

    private func axElementArrayLookup(
        _ attribute: String,
        on element: AXUIElement
    ) -> (elements: [AXUIElement], error: AXError) {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return ([], error)
        }

        return ((value as? [AXUIElement]) ?? [], error)
    }

    private func axElementArrayAttribute(_ attribute: String, on element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return []
        }

        return (value as? [AXUIElement]) ?? []
    }

    private func axDescendantCandidateElements(of element: AXUIElement) -> [AXUIElement] {
        axElementArrayAttribute(kAXChildrenAttribute, on: element)
            + axElementArrayAttribute("AXContents", on: element)
            + axElementArrayAttribute("AXVisibleChildren", on: element)
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

    private func selectedTextRange(on element: AXUIElement) -> NSRange? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &value
        )
        guard error == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cfRange else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range),
              range.location != kCFNotFound,
              range.location >= 0,
              range.length >= 0 else {
            return nil
        }

        return NSRange(location: range.location, length: range.length)
    }

    private func logValue(_ value: Bool?) -> String {
        guard let value else {
            return "nil"
        }

        return value ? "true" : "false"
    }
}
