import AppKit
import SwiftUI

/// Borderless `NSPanel` that needs to explicitly opt-in to becoming key,
/// otherwise the embedded SwiftUI `TextField` cannot receive keyboard input.
final class QuickInputPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override var acceptsFirstResponder: Bool { true }
}

final class QuickInputPanelController: NSObject, NSWindowDelegate {
    private var panel: QuickInputPanel?

    var onSubmit: ((String, ParsedInput.Kind?) -> Void)?
    var onDismiss: (() -> Void)?
    var isVisible: Bool { panel?.isVisible ?? false }

    private let panelSize = CGSize(width: 480, height: 72)

    func show(near petFrame: CGRect) {
        let rect = frame(near: petFrame)

        let panel = QuickInputPanel(
            contentRect: rect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.delegate = self

        let view = QuickInputView(
            onSubmit: { [weak self] text, override in
                self?.onSubmit?(text, override)
                self?.hide()
            },
            onCancel: { [weak self] in
                self?.hide()
            }
        )
        panel.contentView = NSHostingView(rootView: view)

        // Activate the app briefly so the panel can actually become key while
        // the user is focused in some other app. With a nonactivatingPanel +
        // canBecomeKey override, the TextField will then receive keystrokes.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
    }

    func hide() {
        guard panel != nil else { return }
        panel?.orderOut(nil)
        panel = nil
        onDismiss?()
    }

    func reposition(near petFrame: CGRect) {
        guard let panel else { return }
        panel.setFrame(frame(near: petFrame), display: true, animate: false)
    }

    private func frame(near petFrame: CGRect) -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? .zero
        var x = petFrame.midX - panelSize.width / 2
        var y = petFrame.maxY + 10
        // Flip below pet if there isn't room above.
        if y + panelSize.height > screen.maxY - 20 {
            y = petFrame.minY - panelSize.height - 10
        }
        x = max(screen.minX + 8, min(x, screen.maxX - panelSize.width - 8))
        return CGRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
