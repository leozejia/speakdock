import AppKit
import SpeakDockCore
import SwiftUI

enum SpeakDockVisualStyle {
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let panelInset = Color(nsColor: .underPageBackgroundColor)
    static let line = Color.black.opacity(0.08)
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
    var size: CGFloat = 44

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: NSColor(calibratedWhite: 0.22, alpha: 1)),
                            Color(nsColor: NSColor(calibratedWhite: 0.14, alpha: 1)),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)

            HStack(alignment: .bottom, spacing: size * 0.075) {
                glyphBar(height: size * 0.22)
                glyphBar(height: size * 0.42)
                glyphBar(height: size * 0.56)
                glyphBar(height: size * 0.34)
            }
            .frame(height: size * 0.58)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            SpeakDockVisualStyle.accent.opacity(0.95),
                            SpeakDockVisualStyle.accent.opacity(0.65),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.18, height: size * 0.18)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 0.8)
                )
                .offset(x: size * 0.06, y: -size * 0.06)
        }
        .frame(width: size, height: size)
    }

    private func glyphBar(height: CGFloat) -> some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(0.96))
            .frame(width: size * 0.1, height: height)
            .shadow(color: Color.white.opacity(0.18), radius: 1.5, x: 0, y: 0.5)
    }
}

struct SpeakDockMenuBarIcon: View {
    var availability: TriggerAvailability

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .bottom, spacing: 1.6) {
                menuBar(height: 5)
                menuBar(height: 9)
                menuBar(height: 12)
                menuBar(height: 7)
            }
            .frame(width: 17, height: 14)

            if case .unavailable = availability {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 4, height: 4)
                    .offset(x: 1, y: -1)
            }
        }
        .frame(width: 18, height: 14)
        .accessibilityLabel("SpeakDock")
    }

    private func menuBar(height: CGFloat) -> some View {
        Capsule(style: .continuous)
            .fill(Color.primary.opacity(0.92))
            .frame(width: 2.2, height: height)
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
    var displayName: String {
        switch self {
        case .fn:
            "Fn"
        case .rightControl:
            "Right Control"
        case .rightOption:
            "Right Option"
        case .rightCommand:
            "Right Command"
        case .rightShift:
            "Right Shift"
        }
    }
}

