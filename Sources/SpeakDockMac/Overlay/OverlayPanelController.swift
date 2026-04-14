import AppKit
import QuartzCore

@MainActor
final class OverlayPanelController {
    var onSecondaryAction: (() -> Void)? {
        didSet {
            overlayView?.onSecondaryAction = onSecondaryAction
        }
    }

    private var panel: OverlayPanel?
    private var overlayView: OverlayView?
    private var content = OverlayContent(phase: .listening)
    private var dismissTask: Task<Void, Never>?
    private var secondaryActionTitle = "整理"
    private var secondaryActionEnabled = false

    init() {
    }

    func showListening(transcript: String = "") {
        dismissTask?.cancel()
        content = makeContent(phase: .listening, transcript: transcript, level: 0)
        let overlayView = ensureOverlayView()
        overlayView.render(content)
        present(resize: true, animated: true)
    }

    func updateTranscript(_ transcript: String) {
        dismissTask?.cancel()
        content.transcript = transcript
        let overlayView = ensureOverlayView()
        overlayView.render(content)
        present(resize: true, animated: true)
    }

    func updateLevel(_ level: Float) {
        content.level = level
        overlayView?.updateLevel(level)
    }

    func showThinking(transcript: String = "") {
        dismissTask?.cancel()
        content.phase = .thinking
        content.level = 0
        if !transcript.isEmpty {
            content.transcript = transcript
        }
        let overlayView = ensureOverlayView()
        overlayView.render(content)
        present(resize: true, animated: true)
    }

    func showRefining(transcript: String = "") {
        dismissTask?.cancel()
        content.phase = .refining
        content.level = 0
        if !transcript.isEmpty {
            content.transcript = transcript
        }
        let overlayView = ensureOverlayView()
        overlayView.render(content)
        present(resize: true, animated: true)
    }

    func showError(_ message: String, autoDismissAfter delay: TimeInterval = 1.8) {
        dismissTask?.cancel()
        content = makeContent(phase: .error, transcript: message, level: 0)
        let overlayView = ensureOverlayView()
        overlayView.render(content)
        present(resize: true, animated: true)
        dismiss(after: delay)
    }

    func updateSecondaryAction(title: String, isEnabled: Bool) {
        secondaryActionTitle = title
        secondaryActionEnabled = isEnabled
        content.secondaryActionTitle = title
        content.secondaryActionEnabled = isEnabled
        overlayView?.render(content)
    }

    func dismiss(after delay: TimeInterval) {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }

            guard !Task.isCancelled else {
                return
            }

            self.dismissNow()
        }
    }

    func dismissNow() {
        dismissTask?.cancel()
        dismissTask = nil

        guard let panel else {
            return
        }

        guard panel.isVisible else {
            panel.orderOut(nil)
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrame(hiddenFrame(from: panel.frame), display: true)
        }, completionHandler: { [weak panel] in
            Task { @MainActor in
                panel?.orderOut(nil)
            }
        })
    }

    private func present(resize: Bool, animated: Bool) {
        let overlayView = ensureOverlayView()
        let panel = ensurePanel()
        let targetSize = overlayView.preferredSize(for: content)
        let targetFrame = visibleFrame(for: targetSize)

        if !panel.isVisible {
            panel.alphaValue = 0
            panel.setFrame(hiddenFrame(from: targetFrame), display: true)
            panel.orderFrontRegardless()
        }

        if resize || panel.frame.size != targetSize {
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = panel.alphaValue == 0 ? 0.28 : 0.18
                    context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.85, 0.3, 1.0)
                    panel.animator().alphaValue = 1
                    panel.animator().setFrame(targetFrame, display: true)
                }
            } else {
                panel.alphaValue = 1
                panel.setFrame(targetFrame, display: true)
            }
            return
        }

        panel.alphaValue = 1
    }

    private func ensureOverlayView() -> OverlayView {
        if let overlayView {
            return overlayView
        }

        let overlayView = OverlayView(frame: .zero)
        overlayView.onSecondaryAction = { [weak self] in
            self?.onSecondaryAction?()
        }
        overlayView.render(content)
        self.overlayView = overlayView
        ensurePanel().contentView = overlayView
        return overlayView
    }

    private func ensurePanel() -> OverlayPanel {
        if let panel {
            return panel
        }

        let panel = OverlayPanel()
        self.panel = panel
        return panel
    }

    private func makeContent(
        phase: OverlayPhase,
        transcript: String,
        level: Float
    ) -> OverlayContent {
        OverlayContent(
            phase: phase,
            transcript: transcript,
            level: level,
            secondaryActionTitle: secondaryActionTitle,
            secondaryActionEnabled: secondaryActionEnabled
        )
    }

    private func visibleFrame(for size: CGSize) -> CGRect {
        let screenFrame = targetScreenFrame()
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.minY + 56
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    private func hiddenFrame(from frame: CGRect) -> CGRect {
        CGRect(x: frame.origin.x, y: frame.origin.y - 12, width: frame.width, height: frame.height)
    }

    private func targetScreenFrame() -> CGRect {
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) {
            return screen.visibleFrame
        }

        return NSScreen.main?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }
}

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow
    }
}
