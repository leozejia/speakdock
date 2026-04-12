import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import SpeakDockCore

enum ModifierTriggerKey: String, CaseIterable, Sendable {
    case fn = "fn"
    case rightControl = "right-control"
    case rightOption = "right-option"
    case rightCommand = "right-command"
    case rightShift = "right-shift"

    init?(selection: TriggerSelection) {
        switch selection {
        case .fn:
            self = .fn
        case let .alternative(identifier):
            self.init(rawValue: identifier)
        }
    }

    var keyCode: Int64 {
        switch self {
        case .fn:
            Int64(kVK_Function)
        case .rightControl:
            Int64(kVK_RightControl)
        case .rightOption:
            Int64(kVK_RightOption)
        case .rightCommand:
            Int64(kVK_RightCommand)
        case .rightShift:
            Int64(kVK_RightShift)
        }
    }

    var modifierFlag: CGEventFlags {
        switch self {
        case .fn:
            .maskSecondaryFn
        case .rightControl:
            .maskControl
        case .rightOption:
            .maskAlternate
        case .rightCommand:
            .maskCommand
        case .rightShift:
            .maskShift
        }
    }

    var readyLabel: String {
        switch self {
        case .fn:
            "Fn Ready"
        case .rightControl:
            "Right Control Ready"
        case .rightOption:
            "Right Option Ready"
        case .rightCommand:
            "Right Command Ready"
        case .rightShift:
            "Right Shift Ready"
        }
    }

    var unavailableLabel: String {
        switch self {
        case .fn:
            "Fn Unavailable"
        case .rightControl:
            "Right Control Unavailable"
        case .rightOption:
            "Right Option Unavailable"
        case .rightCommand:
            "Right Command Unavailable"
        case .rightShift:
            "Right Shift Unavailable"
        }
    }
}

protocol EventTapPermissionChecking: AnyObject {
    func preflightListenEventAccess() -> Bool
    func requestListenEventAccess() -> Bool
}

final class CoreGraphicsEventTapPermissionChecker: EventTapPermissionChecking {
    func preflightListenEventAccess() -> Bool {
        CGPreflightListenEventAccess()
    }

    func requestListenEventAccess() -> Bool {
        CGRequestListenEventAccess()
    }
}

@MainActor
final class FnKeyTriggerAdapter: TriggerAdapter {
    var onInputEvent: ((TriggerInputEvent) -> Void)?
    var onPressStateChanged: ((Bool) -> Void)?
    var onAvailabilityChanged: ((TriggerAvailability) -> Void)?

    private let triggerKey: ModifierTriggerKey
    private let permissionChecker: EventTapPermissionChecking
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isPressed = false

    init(
        triggerKey: ModifierTriggerKey = .fn,
        permissionChecker: EventTapPermissionChecking = CoreGraphicsEventTapPermissionChecker()
    ) {
        self.triggerKey = triggerKey
        self.permissionChecker = permissionChecker
    }

    func start() {
        guard permissionChecker.preflightListenEventAccess() || permissionChecker.requestListenEventAccess() else {
            onAvailabilityChanged?(.unavailable(label: "\(triggerKey.unavailableLabel): Input Monitoring Required"))
            return
        }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else {
                    return Unmanaged.passRetained(event)
                }

                let adapter = Unmanaged<FnKeyTriggerAdapter>
                    .fromOpaque(refcon)
                    .takeUnretainedValue()
                return adapter.handle(type: type, event: event)
            },
            userInfo: refcon
        ) else {
            onAvailabilityChanged?(.unavailable(label: triggerKey.unavailableLabel))
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        onAvailabilityChanged?(.available(label: triggerKey.readyLabel))
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if isPressed {
            isPressed = false
            onPressStateChanged?(false)
        }

        runLoopSource = nil
        eventTap = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard type == .flagsChanged, keyCode == triggerKey.keyCode else {
            return Unmanaged.passRetained(event)
        }

        let keyDown = event.flags.contains(triggerKey.modifierFlag)
        let timestamp = ProcessInfo.processInfo.systemUptime

        if keyDown && !isPressed {
            isPressed = true
            DispatchQueue.main.async { [weak self] in
                self?.onPressStateChanged?(true)
                self?.onInputEvent?(.press(timestamp: timestamp))
            }
            return nil
        }

        if !keyDown && isPressed {
            isPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onPressStateChanged?(false)
                self?.onInputEvent?(.release(timestamp: timestamp))
            }
            return nil
        }

        return Unmanaged.passRetained(event)
    }
}
