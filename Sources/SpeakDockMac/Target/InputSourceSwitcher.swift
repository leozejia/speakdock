import Carbon
import Foundation

@MainActor
final class InputSourceSwitcher {
    final class RestoreToken {
        fileprivate let originalSource: TISInputSource

        fileprivate init(originalSource: TISInputSource) {
            self.originalSource = originalSource
        }
    }

    func prepareForASCIIInjection() -> RestoreToken? {
        let originalSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard !isASCIICapable(originalSource) else {
            return nil
        }

        guard let asciiSource = findASCIICapableSource() else {
            return nil
        }

        TISSelectInputSource(asciiSource)
        usleep(50_000)
        return RestoreToken(originalSource: originalSource)
    }

    func restore(_ token: RestoreToken?) {
        guard let token else {
            return
        }

        TISSelectInputSource(token.originalSource)
    }

    private func isASCIICapable(_ source: TISInputSource) -> Bool {
        guard let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsASCIICapable) else {
            return false
        }

        let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
        return CFBooleanGetValue(value)
    }

    private func findASCIICapableSource() -> TISInputSource? {
        let criteria = [
            kTISPropertyInputSourceIsASCIICapable: true,
            kTISPropertyInputSourceIsEnabled: true,
        ] as CFDictionary

        guard let sourceList = TISCreateInputSourceList(criteria, false)?.takeRetainedValue() as? [TISInputSource] else {
            return nil
        }

        for source in sourceList {
            guard let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
                continue
            }

            let sourceIdentifier = Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
            if sourceIdentifier == "com.apple.keylayout.ABC" || sourceIdentifier == "com.apple.keylayout.US" {
                return source
            }
        }

        return sourceList.first
    }
}
