import AppKit
import SpeakDockCore
import SwiftUI

private extension NSColor {
    static func speakDockDynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            switch appearance.bestMatch(from: [.darkAqua, .aqua]) {
            case .some(.darkAqua):
                dark
            default:
                light
            }
        }
    }
}

enum SpeakDockVisualStyle {
    static let canvas = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.98, alpha: 1),
            dark: NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.08, alpha: 1)
        )
    )
    static let panel = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.99, green: 0.99, blue: 1.0, alpha: 1),
            dark: NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.15, alpha: 1)
        )
    )
    static let panelInset = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.93, green: 0.95, blue: 0.97, alpha: 1),
            dark: NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.11, alpha: 1)
        )
    )
    static let line = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedWhite: 0.0, alpha: 0.09),
            dark: NSColor(calibratedWhite: 1.0, alpha: 0.08)
        )
    )
    static let settingsBackdropTop = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.94, green: 0.96, blue: 0.99, alpha: 1),
            dark: NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.13, alpha: 1)
        )
    )
    static let settingsBackdropBottom = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.90, green: 0.93, blue: 0.97, alpha: 1),
            dark: NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.07, alpha: 1)
        )
    )
    static let settingsSidebar = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.97, green: 0.98, blue: 0.99, alpha: 0.98),
            dark: NSColor(calibratedRed: 0.09, green: 0.11, blue: 0.15, alpha: 0.98)
        )
    )
    static let settingsContent = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.99, green: 0.99, blue: 1.0, alpha: 0.98),
            dark: NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.11, alpha: 0.98)
        )
    )
    static let settingsCard = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 1),
            dark: NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.16, alpha: 1)
        )
    )
    static let settingsCardStrong = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1),
            dark: NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.18, alpha: 1)
        )
    )
    static let settingsSelectionFill = accent.opacity(0.14)
    static let settingsSelectionLine = accent.opacity(0.24)
    static let settingsLine = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedWhite: 0.0, alpha: 0.08),
            dark: NSColor(calibratedWhite: 1.0, alpha: 0.07)
        )
    )
    static let settingsShadow = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedWhite: 0.0, alpha: 0.10),
            dark: NSColor(calibratedWhite: 0.0, alpha: 0.34)
        )
    )
    static let accent = Color(nsColor: NSColor(calibratedRed: 0.30, green: 0.55, blue: 1.0, alpha: 1))
    static let success = Color(nsColor: .systemGreen)
    static let warning = Color(nsColor: .systemOrange)
    static let critical = Color(nsColor: .systemRed)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
}

enum SpeakDockBadgeTone {
    case accent
    case success
    case warning
    case critical
    case neutral

    var fillColor: Color {
        switch self {
        case .accent:
            SpeakDockVisualStyle.accent.opacity(0.16)
        case .success:
            SpeakDockVisualStyle.success.opacity(0.16)
        case .warning:
            SpeakDockVisualStyle.warning.opacity(0.18)
        case .critical:
            SpeakDockVisualStyle.critical.opacity(0.16)
        case .neutral:
            Color.primary.opacity(0.08)
        }
    }

    var strokeColor: Color {
        switch self {
        case .accent:
            SpeakDockVisualStyle.accent.opacity(0.22)
        case .success:
            SpeakDockVisualStyle.success.opacity(0.26)
        case .warning:
            SpeakDockVisualStyle.warning.opacity(0.28)
        case .critical:
            SpeakDockVisualStyle.critical.opacity(0.24)
        case .neutral:
            SpeakDockVisualStyle.line
        }
    }

    var textColor: Color {
        switch self {
        case .accent:
            SpeakDockVisualStyle.accent
        case .success:
            SpeakDockVisualStyle.success
        case .warning:
            SpeakDockVisualStyle.warning
        case .critical:
            SpeakDockVisualStyle.critical
        case .neutral:
            Color.primary.opacity(0.72)
        }
    }
}

struct SpeakDockStatusBadge: View {
    let title: String
    let tone: SpeakDockBadgeTone

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tone.textColor)
                .frame(width: 6, height: 6)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tone.textColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(tone.fillColor)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tone.strokeColor, lineWidth: 1)
        )
    }
}

struct SpeakDockBrandGlyph: View {
    @Environment(\.colorScheme) private var colorScheme

    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: shellGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(shellStrokeColor, lineWidth: 1)
                )
                .shadow(color: shellShadowColor, radius: size * 0.22, x: 0, y: size * 0.14)

            Circle()
                .fill(shellHighlightColor)
                .blur(radius: size * 0.16)
                .frame(width: size * 0.7, height: size * 0.7)
                .offset(x: -size * 0.1, y: -size * 0.16)

            SpeakDockMicMark(
                bodyColor: .gradient(microphoneGradient),
                scaffoldColor: scaffoldColor,
                highlightColor: capsuleHighlightColor
            )
            .frame(width: size * 0.62, height: size * 0.7)
        }
        .frame(width: size, height: size)
    }

    private var shellGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(nsColor: NSColor(calibratedWhite: 0.22, alpha: 1)),
                Color(nsColor: NSColor(calibratedWhite: 0.10, alpha: 1)),
            ]
        }

        return [
            Color(nsColor: NSColor(calibratedRed: 0.99, green: 0.99, blue: 0.98, alpha: 1)),
            Color(nsColor: NSColor(calibratedRed: 0.90, green: 0.93, blue: 0.97, alpha: 1)),
        ]
    }

    private var shellStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10)
    }

    private var shellShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.24) : .black.opacity(0.14)
    }

    private var shellHighlightColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.72)
    }

    private var microphoneGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(nsColor: NSColor(calibratedRed: 0.27, green: 0.84, blue: 1.0, alpha: 1)),
                Color(nsColor: NSColor(calibratedRed: 0.22, green: 0.45, blue: 1.0, alpha: 1)),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var scaffoldColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.86)
            : Color(nsColor: NSColor(calibratedRed: 0.19, green: 0.22, blue: 0.28, alpha: 0.92))
    }

    private var capsuleHighlightColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.22 : 0.34)
    }
}

struct SpeakDockMenuBarIcon: View {
    var availability: TriggerAvailability

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpeakDockMicMark(
                bodyColor: .solid(Color.primary.opacity(0.95)),
                scaffoldColor: Color.primary.opacity(0.95),
                highlightColor: .clear,
                monochrome: true
            )
            .frame(width: 11, height: 14)

            if case .unavailable = availability {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 4, height: 4)
                    .offset(x: 1, y: -1)
            }
        }
        .frame(width: 16, height: 14)
        .accessibilityLabel("SpeakDock")
    }
}

private enum SpeakDockMicBodyFill {
    case solid(Color)
    case gradient(LinearGradient)
}

private struct SpeakDockMicMark: View {
    let bodyColor: SpeakDockMicBodyFill
    let scaffoldColor: Color
    let highlightColor: Color
    var monochrome = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let width = size.width
            let height = size.height

            ZStack {
                SpeakDockMicYoke()
                    .stroke(
                        scaffoldColor,
                        style: StrokeStyle(
                            lineWidth: max(1.4, width * 0.12),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: width * 0.74, height: height * 0.50)
                    .offset(y: height * 0.02)

                capsuleFill
                    .frame(width: width * 0.26, height: height * 0.42)
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(highlightColor)
                            .frame(width: width * 0.06, height: height * 0.22)
                            .offset(x: -width * 0.045, y: -height * 0.05)
                    )
                    .offset(y: -height * 0.13)

                RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
                    .fill(scaffoldColor)
                    .frame(width: width * 0.08, height: height * 0.14)
                    .offset(y: height * 0.17)

                Capsule(style: .continuous)
                    .fill(scaffoldColor)
                    .frame(width: width * 0.36, height: height * 0.07)
                    .offset(y: height * 0.33)
            }
            .frame(width: width, height: height)
        }
    }

    @ViewBuilder
    private var capsuleFill: some View {
        switch bodyColor {
        case let .solid(color):
            Capsule(style: .continuous)
                .fill(monochrome ? scaffoldColor : color)

        case let .gradient(gradient):
            if monochrome {
                Capsule(style: .continuous)
                    .fill(scaffoldColor)
            } else {
                Capsule(style: .continuous)
                    .fill(gradient)
            }
        }
    }
}

private struct SpeakDockMicYoke: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let leftX = rect.minX + rect.width * 0.20
        let rightX = rect.maxX - rect.width * 0.20
        let topY = rect.minY + rect.height * 0.12
        let bottomY = rect.maxY - rect.height * 0.10
        let innerLeft = rect.minX + rect.width * 0.34
        let innerRight = rect.maxX - rect.width * 0.34

        path.move(to: CGPoint(x: leftX, y: topY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: bottomY),
            control1: CGPoint(x: leftX, y: rect.minY + rect.height * 0.62),
            control2: CGPoint(x: innerLeft, y: bottomY)
        )
        path.addCurve(
            to: CGPoint(x: rightX, y: topY),
            control1: CGPoint(x: innerRight, y: bottomY),
            control2: CGPoint(x: rightX, y: rect.minY + rect.height * 0.62)
        )

        return path
    }
}

struct SpeakDockPanel<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.92))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(SpeakDockVisualStyle.secondaryText)
                }
            }

            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpeakDockVisualStyle.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SpeakDockVisualStyle.line, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 18, x: 0, y: 10)
    }
}

struct SpeakDockActionButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case subtle
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var horizontalPadding: CGFloat {
        switch kind {
        case .primary, .secondary:
            14
        case .subtle:
            10
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary:
            SpeakDockVisualStyle.accent.opacity(0.18)
        case .secondary:
            Color.black.opacity(0.08)
        case .subtle:
            Color.clear
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch kind {
        case .primary:
            SpeakDockVisualStyle.accent.opacity(isPressed ? 0.82 : 0.94)
        case .secondary:
            Color.primary.opacity(isPressed ? 0.1 : 0.07)
        case .subtle:
            Color.primary.opacity(isPressed ? 0.08 : 0.04)
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        switch kind {
        case .primary:
            .white.opacity(isPressed ? 0.92 : 1)
        case .secondary, .subtle:
            .primary.opacity(isPressed ? 0.78 : 0.88)
        }
    }
}

extension ModifierTriggerKey {
    func displayName(appLanguage: AppLanguageOption? = nil) -> String {
        switch self {
        case .fn:
            "Fn"
        case .rightControl:
            AppLocalizer.string(.modifierTriggerRightControl, appLanguage: appLanguage)
        case .rightOption:
            AppLocalizer.string(.modifierTriggerRightOption, appLanguage: appLanguage)
        case .rightCommand:
            AppLocalizer.string(.modifierTriggerRightCommand, appLanguage: appLanguage)
        case .rightShift:
            AppLocalizer.string(.modifierTriggerRightShift, appLanguage: appLanguage)
        }
    }
}

extension InputLanguageOption {
    func displayName(appLanguage: AppLanguageOption? = nil) -> String {
        switch self {
        case .english:
            AppLocalizer.string(.inputLanguageEnglish, appLanguage: appLanguage)
        case .simplifiedChinese:
            AppLocalizer.string(.inputLanguageSimplifiedChinese, appLanguage: appLanguage)
        case .traditionalChinese:
            AppLocalizer.string(.inputLanguageTraditionalChinese, appLanguage: appLanguage)
        case .japanese:
            AppLocalizer.string(.inputLanguageJapanese, appLanguage: appLanguage)
        case .korean:
            AppLocalizer.string(.inputLanguageKorean, appLanguage: appLanguage)
        }
    }
}

extension AppLanguageOption {
    func displayName(appLanguage: AppLanguageOption? = nil) -> String {
        switch self {
        case .followSystem:
            AppLocalizer.string(.appLanguageFollowSystem, appLanguage: appLanguage)
        case .english:
            AppLocalizer.string(.appLanguageEnglish, appLanguage: appLanguage)
        case .simplifiedChinese:
            AppLocalizer.string(.appLanguageSimplifiedChinese, appLanguage: appLanguage)
        }
    }
}
