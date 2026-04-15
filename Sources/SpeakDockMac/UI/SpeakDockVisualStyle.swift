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
            dark: NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.11, alpha: 1)
        )
    )
    static let panel = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.99, green: 0.99, blue: 1.0, alpha: 1),
            dark: NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.24, alpha: 1)
        )
    )
    static let panelInset = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.93, green: 0.95, blue: 0.97, alpha: 1),
            dark: NSColor(calibratedRed: 0.11, green: 0.13, blue: 0.17, alpha: 1)
        )
    )
    static let line = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedWhite: 0.0, alpha: 0.09),
            dark: NSColor(calibratedWhite: 1.0, alpha: 0.07)
        )
    )
    static let settingsBackdropTop = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.94, green: 0.96, blue: 0.99, alpha: 1),
            dark: NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 1)
        )
    )
    static let settingsBackdropBottom = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.90, green: 0.93, blue: 0.97, alpha: 1),
            dark: NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.10, alpha: 1)
        )
    )
    static let settingsSidebar = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.97, green: 0.98, blue: 0.99, alpha: 0.98),
            dark: NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.19, alpha: 0.98)
        )
    )
    static let settingsContent = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.99, green: 0.99, blue: 1.0, alpha: 0.98),
            dark: NSColor(calibratedRed: 0.09, green: 0.11, blue: 0.14, alpha: 0.98)
        )
    )
    static let settingsCard = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 1),
            dark: NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.22, alpha: 1)
        )
    )
    static let settingsCardStrong = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1),
            dark: NSColor(calibratedRed: 0.19, green: 0.22, blue: 0.27, alpha: 1)
        )
    )
    static let settingsSelectionFill = accent.opacity(0.12)
    static let settingsSelectionLine = accent.opacity(0.26)
    static let settingsLine = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedWhite: 0.0, alpha: 0.08),
            dark: NSColor(calibratedWhite: 1.0, alpha: 0.06)
        )
    )
    static let settingsShadow = Color(
        nsColor: .speakDockDynamic(
            light: NSColor(calibratedWhite: 0.0, alpha: 0.10),
            dark: NSColor(calibratedWhite: 0.0, alpha: 0.28)
        )
    )
    static let accent = Color(nsColor: NSColor(calibratedRed: 0.40, green: 0.62, blue: 1.0, alpha: 1))
    static let success = Color(nsColor: .systemGreen)
    static let warning = Color(nsColor: .systemOrange)
    static let critical = Color(nsColor: .systemRed)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
    static let highlightWash = Color(
        nsColor: .speakDockDynamic(
            light: NSColor.white.withAlphaComponent(0.42),
            dark: NSColor.white.withAlphaComponent(0.025)
        )
    )
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
        .padding(.vertical, 5)
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
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = SpeakDockBrandAssets.applicationIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
            } else {
                SpeakDockFallbackBrandGlyph(size: size)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SpeakDockMenuBarIcon: View {
    var availability: TriggerAvailability

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpeakDockMicMark(
                shellFill: .color(Color.primary.opacity(0.95)),
                signalFill: .none,
                structureColor: Color.primary.opacity(0.95),
                shellStrokeColor: .clear,
                signalGlowColor: .clear
            )
            .frame(width: 12, height: 14.5)

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

private enum SpeakDockMicFill {
    case color(Color)
    case gradient(LinearGradient)
    case none
}

enum SpeakDockBrandAssets {
    static let applicationIcon: NSImage? = {
        guard let iconURL = Bundle.main.url(forResource: "SpeakDockIcon", withExtension: "png"),
              let image = NSImage(contentsOf: iconURL) else {
            return nil
        }

        image.isTemplate = false
        return image
    }()
}

private struct SpeakDockFallbackBrandGlyph: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: NSColor(calibratedRed: 1.0, green: 0.992, blue: 0.988, alpha: 1)),
                            Color(nsColor: NSColor(calibratedRed: 0.948, green: 0.957, blue: 0.973, alpha: 1)),
                            Color(nsColor: NSColor(calibratedRed: 0.894, green: 0.917, blue: 0.949, alpha: 1)),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.14), radius: size * 0.18, x: 0, y: size * 0.12)

            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.94),
                            .white.opacity(0.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.56, height: size * 0.24)
                .offset(x: -size * 0.12, y: -size * 0.22)
                .blur(radius: size * 0.04)

            SpeakDockMicMark(
                shellFill: .gradient(
                    LinearGradient(
                        colors: [
                            Color(nsColor: NSColor(calibratedRed: 0.25, green: 0.30, blue: 0.36, alpha: 1)),
                            Color(nsColor: NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.15, alpha: 1)),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                ),
                signalFill: .gradient(
                    LinearGradient(
                        colors: [
                            Color(nsColor: NSColor(calibratedRed: 0.46, green: 0.88, blue: 1.0, alpha: 1)),
                            Color(nsColor: NSColor(calibratedRed: 0.20, green: 0.58, blue: 1.0, alpha: 1)),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                ),
                structureColor: Color(nsColor: NSColor(calibratedRed: 0.17, green: 0.20, blue: 0.24, alpha: 0.96)),
                shellStrokeColor: Color.white.opacity(0.12),
                signalGlowColor: Color(nsColor: NSColor(calibratedRed: 0.34, green: 0.76, blue: 1.0, alpha: 0.20))
            )
            .frame(width: size * 0.64, height: size * 0.74)
        }
        .frame(width: size, height: size)
    }
}

private struct SpeakDockMicMark: View {
    let shellFill: SpeakDockMicFill
    let signalFill: SpeakDockMicFill
    let structureColor: Color
    let shellStrokeColor: Color
    let signalGlowColor: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let width = size.width
            let height = size.height

            ZStack {
                Circle()
                    .fill(signalGlowColor)
                    .frame(width: width * 0.42, height: width * 0.42)
                    .blur(radius: width * 0.12)
                    .offset(y: -height * 0.09)

                SpeakDockMicYoke()
                    .stroke(
                        structureColor,
                        style: StrokeStyle(
                            lineWidth: max(1.4, width * 0.115),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: width * 0.70, height: height * 0.46)
                    .offset(y: height * 0.03)

                fillView(for: shellFill)
                    .frame(width: width * 0.31, height: height * 0.46)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(shellStrokeColor, lineWidth: max(1, width * 0.025))
                    )
                    .overlay(signalView(width: width, height: height))
                    .offset(y: -height * 0.13)

                RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
                    .fill(structureColor)
                    .frame(width: width * 0.08, height: height * 0.14)
                    .offset(y: height * 0.16)

                Capsule(style: .continuous)
                    .fill(structureColor)
                    .frame(width: width * 0.36, height: height * 0.065)
                    .offset(y: height * 0.33)
            }
            .frame(width: width, height: height)
        }
    }

    @ViewBuilder
    private func fillView(for fill: SpeakDockMicFill) -> some View {
        switch fill {
        case let .color(color):
            Capsule(style: .continuous)
                .fill(color)
        case let .gradient(gradient):
            Capsule(style: .continuous)
                .fill(gradient)
        case .none:
            Capsule(style: .continuous)
                .fill(.clear)
        }
    }

    @ViewBuilder
    private func signalView(width: CGFloat, height: CGFloat) -> some View {
        switch signalFill {
        case .none:
            EmptyView()
        case let .color(color):
            RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
                .fill(color)
                .frame(width: width * 0.08, height: height * 0.24)
                .offset(y: -height * 0.12)
        case let .gradient(gradient):
            RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
                .fill(gradient)
                .frame(width: width * 0.08, height: height * 0.24)
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.04, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: max(1, width * 0.015))
                )
                .offset(y: -height * 0.12)
        }
    }
}

private struct SpeakDockMicYoke: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let leftX = rect.minX + rect.width * 0.20
        let rightX = rect.maxX - rect.width * 0.20
        let topY = rect.minY + rect.height * 0.18
        let bottomY = rect.maxY - rect.height * 0.08
        let innerLeft = rect.minX + rect.width * 0.35
        let innerRight = rect.maxX - rect.width * 0.35

        path.move(to: CGPoint(x: leftX, y: topY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: bottomY),
            control1: CGPoint(x: leftX, y: rect.minY + rect.height * 0.72),
            control2: CGPoint(x: innerLeft, y: bottomY)
        )
        path.addCurve(
            to: CGPoint(x: rightX, y: topY),
            control1: CGPoint(x: innerRight, y: bottomY),
            control2: CGPoint(x: rightX, y: rect.minY + rect.height * 0.72)
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
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor.opacity(configuration.isPressed ? 0.0 : 1.0), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
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
            SpeakDockVisualStyle.accent.opacity(0.24)
        case .secondary:
            SpeakDockVisualStyle.settingsLine
        case .subtle:
            Color.clear
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch kind {
        case .primary:
            SpeakDockVisualStyle.accent.opacity(isPressed ? 0.80 : 0.92)
        case .secondary:
            SpeakDockVisualStyle.settingsCardStrong.opacity(isPressed ? 0.76 : 0.92)
        case .subtle:
            Color.primary.opacity(isPressed ? 0.10 : 0.05)
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

    private var shadowColor: Color {
        switch kind {
        case .primary:
            SpeakDockVisualStyle.accent.opacity(0.22)
        case .secondary:
            .black.opacity(0.10)
        case .subtle:
            .clear
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
