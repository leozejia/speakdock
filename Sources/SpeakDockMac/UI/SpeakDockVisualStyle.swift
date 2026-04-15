import AppKit
import SpeakDockCore
import SwiftUI

enum SpeakDockVisualStyle {
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let panelInset = Color(nsColor: .underPageBackgroundColor)
    static let line = Color.black.opacity(0.08)
    static let settingsBackdropTop = Color(nsColor: NSColor(calibratedRed: 0.85, green: 0.90, blue: 0.98, alpha: 1))
    static let settingsBackdropBottom = Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.98, alpha: 1))
    static let settingsSidebar = Color(nsColor: NSColor(calibratedRed: 0.96, green: 0.97, blue: 1.0, alpha: 0.92))
    static let settingsContent = Color(nsColor: NSColor(calibratedWhite: 1.0, alpha: 0.82))
    static let settingsCard = Color(nsColor: NSColor(calibratedWhite: 1.0, alpha: 0.70))
    static let settingsCardStrong = Color(nsColor: NSColor(calibratedWhite: 1.0, alpha: 0.94))
    static let settingsSelectionFill = accent.opacity(0.14)
    static let settingsSelectionLine = accent.opacity(0.22)
    static let settingsLine = Color.black.opacity(0.07)
    static let settingsShadow = Color.black.opacity(0.09)
    static let accent = Color(nsColor: .controlAccentColor)
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
            Color.black.opacity(0.08)
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

            microphoneGlyph
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
            Color(nsColor: NSColor(calibratedRed: 0.90, green: 0.92, blue: 0.96, alpha: 1)),
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
                Color(nsColor: NSColor(calibratedRed: 0.14, green: 0.82, blue: 1.0, alpha: 1)),
                Color(nsColor: NSColor(calibratedRed: 0.21, green: 0.38, blue: 1.0, alpha: 1)),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var microphoneStandColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.72)
    }

    private var microphoneGlyph: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(microphoneGradient)
                .frame(width: size * 0.26, height: size * 0.40)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.24 : 0.42), lineWidth: 0.9)
                )
                .shadow(
                    color: Color(nsColor: NSColor(calibratedRed: 0.15, green: 0.60, blue: 1.0, alpha: colorScheme == .dark ? 0.34 : 0.18)),
                    radius: size * 0.12,
                    x: 0,
                    y: size * 0.06
                )
                .offset(y: -size * 0.07)

            RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
                .fill(microphoneStandColor)
                .frame(width: size * 0.06, height: size * 0.18)
                .offset(y: size * 0.12)

            Capsule(style: .continuous)
                .fill(microphoneStandColor)
                .frame(width: size * 0.30, height: size * 0.06)
                .offset(y: size * 0.28)

            Capsule(style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.38))
                .frame(width: size * 0.05, height: size * 0.22)
                .offset(x: -size * 0.06, y: -size * 0.09)
        }
    }
}

struct SpeakDockMenuBarIcon: View {
    var availability: TriggerAvailability

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "mic.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.primary.opacity(0.95))

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
