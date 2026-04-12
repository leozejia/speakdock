import AppKit
import QuartzCore

enum OverlayPhase: Equatable, Sendable {
    case listening
    case thinking
    case refining
    case error

    var title: String {
        switch self {
        case .listening:
            "Listening"
        case .thinking:
            "Thinking"
        case .refining:
            "Refining"
        case .error:
            "Unavailable"
        }
    }

    var defaultTranscript: String {
        switch self {
        case .listening:
            "Listening..."
        case .thinking:
            "Processing speech..."
        case .refining:
            "Refining..."
        case .error:
            "Microphone Unavailable"
        }
    }

    var waveformIsActive: Bool {
        self == .listening
    }
}

struct OverlayContent: Equatable, Sendable {
    var phase: OverlayPhase
    var transcript: String
    var level: Float
    var secondaryActionTitle: String
    var secondaryActionEnabled: Bool

    init(
        phase: OverlayPhase,
        transcript: String = "",
        level: Float = 0,
        secondaryActionTitle: String = "整理",
        secondaryActionEnabled: Bool = false
    ) {
        self.phase = phase
        self.transcript = transcript
        self.level = level
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryActionEnabled = secondaryActionEnabled
    }

    var resolvedTranscript: String {
        transcript.isEmpty ? phase.defaultTranscript : transcript
    }
}

final class OverlayView: NSVisualEffectView {
    var onSecondaryAction: (() -> Void)?

    private let metrics = Metrics()
    private let waveformView = WaveformBarsView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let transcriptLabel = NSTextField(labelWithString: "")
    private let secondaryButton = NSButton(title: "整理", target: nil, action: nil)

    private var content = OverlayContent(phase: .listening)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureView()
        configureLayout()
        render(content)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        configureLayout()
        render(content)
    }

    func render(_ content: OverlayContent) {
        self.content = content

        statusLabel.stringValue = content.phase.title
        transcriptLabel.stringValue = content.resolvedTranscript
        secondaryButton.title = content.secondaryActionTitle
        secondaryButton.isEnabled = content.secondaryActionEnabled
        waveformView.setActive(content.phase.waveformIsActive)
        waveformView.setLevel(content.level)
    }

    func updateLevel(_ level: Float) {
        content.level = level
        waveformView.setLevel(level)
    }

    func preferredSize(for content: OverlayContent? = nil) -> CGSize {
        let content = content ?? self.content
        let statusText = content.phase.title
        let transcriptText = content.resolvedTranscript

        let statusWidth = ceil((statusText as NSString).size(withAttributes: [
            .font: statusLabel.font as Any,
        ]).width)
        let transcriptWidth = ceil((transcriptText as NSString).size(withAttributes: [
            .font: transcriptLabel.font as Any,
        ]).width)
        let textWidth = min(max(statusWidth, transcriptWidth), metrics.maxTextWidth)

        let buttonWidth = max(metrics.minButtonWidth, secondaryButton.intrinsicContentSize.width)
        let totalWidth =
            metrics.horizontalPadding +
            metrics.waveformWidth +
            metrics.stackSpacing +
            textWidth +
            metrics.stackSpacing +
            buttonWidth +
            metrics.horizontalPadding

        return CGSize(
            width: min(max(totalWidth, metrics.minWidth), metrics.maxWidth),
            height: metrics.height
        )
    }

    private func configureView() {
        material = .hudWindow
        state = .active
        appearance = NSAppearance(named: .darkAqua)
        blendingMode = .behindWindow
        wantsLayer = true
        layer?.cornerRadius = metrics.height / 2
        layer?.masksToBounds = true
    }

    private func configureLayout() {
        let borderView = NSView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.wantsLayer = true
        borderView.layer?.cornerRadius = metrics.height / 2
        borderView.layer?.borderWidth = 0.5
        borderView.layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
        addSubview(borderView)

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        statusLabel.textColor = NSColor.white.withAlphaComponent(0.72)
        statusLabel.lineBreakMode = .byTruncatingTail

        transcriptLabel.font = .systemFont(ofSize: 14, weight: .medium)
        transcriptLabel.textColor = NSColor.white.withAlphaComponent(0.95)
        transcriptLabel.lineBreakMode = .byTruncatingTail
        transcriptLabel.maximumNumberOfLines = 1
        transcriptLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textStack.addArrangedSubview(statusLabel)
        textStack.addArrangedSubview(transcriptLabel)

        waveformView.translatesAutoresizingMaskIntoConstraints = false

        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        secondaryButton.bezelStyle = .rounded
        secondaryButton.setButtonType(.momentaryPushIn)
        secondaryButton.target = self
        secondaryButton.action = #selector(handleSecondaryAction)
        secondaryButton.controlSize = .small

        let row = NSStackView(views: [waveformView, textStack, secondaryButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = metrics.stackSpacing
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            waveformView.widthAnchor.constraint(equalToConstant: metrics.waveformWidth),
            waveformView.heightAnchor.constraint(equalToConstant: metrics.waveformHeight),
            secondaryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: metrics.minButtonWidth),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: metrics.horizontalPadding),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -metrics.horizontalPadding),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc
    private func handleSecondaryAction() {
        onSecondaryAction?()
    }
}

private struct Metrics {
    let height: CGFloat = 68
    let minWidth: CGFloat = 260
    let maxWidth: CGFloat = 640
    let maxTextWidth: CGFloat = 360
    let horizontalPadding: CGFloat = 18
    let stackSpacing: CGFloat = 14
    let waveformWidth: CGFloat = 44
    let waveformHeight: CGFloat = 32
    let minButtonWidth: CGFloat = 54
}

private final class WaveformBarsView: NSView {
    private let barWeights: [CGFloat] = [0.5, 0.8, 1.0, 0.75, 0.55]
    private let minBarFraction: CGFloat = 0.15
    private var barLayers: [CALayer] = []
    private var level: CGFloat = 0
    private var isActive = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBars()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBars()
    }

    override func layout() {
        super.layout()
        applyBars(animated: false)
    }

    func setActive(_ isActive: Bool) {
        self.isActive = isActive
        alphaValue = isActive ? 1 : 0.55
        applyBars(animated: true)
    }

    func setLevel(_ level: Float) {
        self.level = CGFloat(min(max(level, 0), 1))
        applyBars(animated: true)
    }

    private func setupBars() {
        guard barLayers.isEmpty else {
            return
        }

        for _ in barWeights {
            let barLayer = CALayer()
            barLayer.backgroundColor = NSColor.white.withAlphaComponent(0.92).cgColor
            barLayer.cornerRadius = 2.5
            layer?.addSublayer(barLayer)
            barLayers.append(barLayer)
        }
    }

    private func applyBars(animated: Bool) {
        let barWidth: CGFloat = 4.5
        let barGap: CGFloat = 4
        let totalWidth = CGFloat(barWeights.count) * barWidth + CGFloat(barWeights.count - 1) * barGap
        let startX = (bounds.width - totalWidth) / 2
        let effectiveLevel = isActive ? level : 0

        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.08)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        }

        for (index, barLayer) in barLayers.enumerated() {
            let jitter = isActive ? CGFloat.random(in: -0.04...0.04) : 0
            let fraction = minBarFraction + (1 - minBarFraction) * effectiveLevel * barWeights[index]
            let height = bounds.height * min(max(fraction + jitter, minBarFraction), 1)
            let x = startX + CGFloat(index) * (barWidth + barGap)
            let y = (bounds.height - height) / 2
            barLayer.frame = CGRect(x: x, y: y, width: barWidth, height: height)
        }

        if animated {
            CATransaction.commit()
        }
    }
}
