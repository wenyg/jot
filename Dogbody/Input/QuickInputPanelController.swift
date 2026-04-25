import AppKit
import SwiftUI

/// Borderless `NSPanel` that needs to explicitly opt-in to becoming key,
/// otherwise the embedded SwiftUI `TextField` cannot receive keyboard input.
final class QuickInputPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override var acceptsFirstResponder: Bool { true }
}

extension Notification.Name {
    /// Posted by the panel controller when the user presses Tab inside the
    /// quick-input bubble. Caught by `QuickInputView` to flip TODO ↔ 记一笔.
    static let quickInputToggleKind = Notification.Name("io.github.wenyg.jot.quickInputToggleKind")
}

/// Owns the speech-bubble panel that appears next to the pet. The panel is
/// sized to include a small tail; the tail's tip is always positioned over
/// the pet, even when the bubble itself has to slide along the screen edge
/// to stay on-screen.
final class QuickInputPanelController: NSObject, NSWindowDelegate {
    private var panel: QuickInputPanel?
    private var keyMonitor: Any?

    var onSubmit: ((String, ParsedInput.Kind?) -> Void)?
    var onDismiss: (() -> Void)?
    var isVisible: Bool { panel?.isVisible ?? false }

    /// Bubble width and total panel height (body + tail).
    private let bubbleWidth: CGFloat = 460
    private let bubbleBodyHeight: CGFloat = 60
    private var totalHeight: CGFloat { bubbleBodyHeight + BubbleShape.tailHeight }
    private var panelSize: CGSize { CGSize(width: bubbleWidth, height: totalHeight) }

    /// Vertical breathing room between the pet's edge and the tail tip.
    private let tipGap: CGFloat = 6

    func show(near petFrame: CGRect) {
        let layout = layout(near: petFrame)

        let panel = QuickInputPanel(
            contentRect: layout.rect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // The bubble is a non-rectangular Shape, so the system shadow (which
        // shadows the panel rectangle) would betray its corners. Use SwiftUI's
        // own shadow inside `QuickInputView` instead.
        panel.hasShadow = false
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
            },
            tailCenterX: layout.tailCenterX,
            tailOnTop: layout.tailOnTop
        )
        panel.contentView = NSHostingView(rootView: view)

        // Activate the app briefly so the panel can actually become key while
        // the user is focused in some other app. With a nonactivatingPanel +
        // canBecomeKey override, the TextField will then receive keystrokes.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
        installKeyMonitor()
    }

    func hide() {
        guard panel != nil else { return }
        removeKeyMonitor()
        panel?.orderOut(nil)
        panel = nil
        onDismiss?()
    }

    // MARK: - Tab key interception
    //
    // SwiftUI's `Button.keyboardShortcut(.tab)` does NOT fire while a SwiftUI
    // `TextField` holds first-responder focus, because AppKit's text input
    // pipeline consumes Tab first as "go to next key view". To classify on
    // Tab anyway, install a panel-scoped local key monitor that swallows the
    // event and posts a notification the SwiftUI view picks up.

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel?.isKeyWindow == true else { return event }
            // 48 = Tab keycode. Only fire on a bare Tab — let ⇧⌘⌃⌥-Tab through.
            let bareModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 48 && bareModifiers.isEmpty {
                NotificationCenter.default.post(name: .quickInputToggleKind, object: self)
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    func reposition(near petFrame: CGRect) {
        guard let panel else { return }
        // Only follow the pet's position with the panel frame. Replacing the
        // SwiftUI view here would reset @State (the in-progress TextField
        // contents) — and reposition is called on every pet drag tick. The
        // tail will be momentarily off-target while the user is dragging the
        // pet *with the bubble already open*, which in practice is never.
        let layout = layout(near: petFrame)
        panel.setFrame(layout.rect, display: true, animate: false)
    }

    // MARK: - Layout

    private struct BubbleLayout {
        let rect: CGRect
        /// Tail's horizontal position in *view coordinates* (0 = panel left).
        let tailCenterX: CGFloat
        /// `true` if tail is at the top of the view (bubble is below the pet).
        let tailOnTop: Bool
    }

    private func layout(near petFrame: CGRect) -> BubbleLayout {
        let screen = NSScreen.main?.visibleFrame ?? .zero
        let size = panelSize

        // SwiftUI inside the panel uses top-left coords (y grows down) but
        // an NSWindow frame uses macOS bottom-up coords. The panel's
        // `frame.minY` is therefore the *bottom* edge of the SwiftUI canvas,
        // i.e. where the tail tip sits when the tail is at the SwiftUI bottom.
        //
        // Default placement: bubble *above* the pet, tail pointing down.
        // We want the tail tip to sit just above the pet → panel.minY = petFrame.maxY + tipGap.
        var tailOnTop = false
        var originY = petFrame.maxY + tipGap

        // If the bubble would overflow the top of the screen, flip below the pet.
        // Tail-up case: tail tip is at view y=0, which is panel.maxY in screen
        // coords. We want tip just below the pet → panel.maxY = petFrame.minY - tipGap.
        if originY + size.height > screen.maxY - 12 {
            tailOnTop = true
            originY = petFrame.minY - tipGap - size.height
        }

        // Horizontally, center the bubble on the pet, then clamp to screen.
        let desiredX = petFrame.midX - size.width / 2
        let originX = max(screen.minX + 8, min(desiredX, screen.maxX - size.width - 8))

        let rect = CGRect(x: originX, y: originY, width: size.width, height: size.height)

        // Tail X in view coords: where the pet's center falls within the view.
        // After horizontal clamping the bubble may have shifted, so we recompute.
        let tailX = petFrame.midX - originX
        return BubbleLayout(rect: rect, tailCenterX: tailX, tailOnTop: tailOnTop)
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
