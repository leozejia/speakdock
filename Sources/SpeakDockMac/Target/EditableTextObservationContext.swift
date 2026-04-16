import Foundation

struct EditableTextObservationContext {
    let prefix: String
    let suffix: String

    init?(fullText: String, selectedRange: NSRange) {
        let text = fullText as NSString
        let rangeUpperBound = selectedRange.location + selectedRange.length

        guard selectedRange.location != NSNotFound,
              selectedRange.location >= 0,
              selectedRange.length >= 0,
              selectedRange.location <= text.length,
              rangeUpperBound <= text.length else {
            return nil
        }

        self.prefix = text.substring(to: selectedRange.location)
        self.suffix = text.substring(from: rangeUpperBound)
    }

    func observedText(in fullText: String) -> String? {
        guard fullText.hasPrefix(prefix), fullText.hasSuffix(suffix) else {
            return nil
        }

        let text = fullText as NSString
        let prefixLength = (prefix as NSString).length
        let suffixLength = (suffix as NSString).length
        let observedLength = text.length - prefixLength - suffixLength

        guard observedLength >= 0 else {
            return nil
        }

        return text.substring(with: NSRange(location: prefixLength, length: observedLength))
    }
}
