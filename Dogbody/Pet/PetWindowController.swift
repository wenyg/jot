import AppKit
import SwiftUI

final class PetWindowController: NSObject {
    private var window: PetWindow?
    private var inputController: QuickInputPanelController?

    var animator: PetAnimator?

    /// Called when the user submits text from the quick input panel.
    var onSubmit: ((String, ParsedInput.Kind?) -> Void)?
    /// Called when the quick input panel is about to open.
    var onOpenRequested: (() -> Void)?
    /// Called after the quick input panel closes.
    var onPanelClosed: (() -> Void)?

    var isVisible: Bool { window?.isVisible ?? false }

    // Remember where the pet "lives" so it can walk home after a reminder.
    private var homeOrigin: CGPoint?

    // Disable position persistence while the pet is animating across the screen
    // for a reminder — otherwise the walk itself would overwrite "home".
    private var isPerformingWalk = false
    private var walkReturnTimer: Timer?

    func show() {
        if let win = window {
            win.orderFront(nil)
            return
        }
        let size = CGSize(width: 160, height: 170)
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let savedX = UserDefaults.standard.object(forKey: "pet.origin.x") as? CGFloat
        let savedY = UserDefaults.standard.object(forKey: "pet.origin.y") as? CGFloat
        let origin = CGPoint(
            x: savedX ?? (visible.maxX - size.width - 40),
            y: savedY ?? (visible.minY + 40)
        )
        homeOrigin = origin
        let rect = CGRect(origin: origin, size: size)

        let win = PetWindow(contentRect: rect)
        let animatorRef = animator ?? PetAnimator()
        self.animator = animatorRef

        let view = PetView(
            animator: animatorRef,
            onTap: { [weak self] in self?.handleTap() }
        )
        win.contentView = NSHostingView(rootView: view)
        win.orderFront(nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowMoved(_:)),
            name: NSWindow.didMoveNotification,
            object: win
        )

        self.window = win
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    /// Walk the pet from its home position to the center of the screen and
    /// have it wait there for the user. Called by the daily reminder. After
    /// `timeout` seconds of no interaction the pet walks itself back home.
    func walkToCenter(timeout: TimeInterval = 10 * 60) {
        guard let win = window, let screen = NSScreen.main else { return }
        if homeOrigin == nil { homeOrigin = win.frame.origin }

        let visible = screen.visibleFrame
        let targetOrigin = CGPoint(
            x: visible.midX - win.frame.width / 2,
            y: visible.midY - win.frame.height / 2
        )

        isPerformingWalk = true
        animator?.set(.remind)
        animate(window: win, to: targetOrigin, duration: 1.4) { [weak self] in
            self?.isPerformingWalk = false
            // Stay in .remind state so the pet keeps gesturing until
            // the user either engages or the timeout elapses.
            self?.walkReturnTimer?.invalidate()
            self?.walkReturnTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
                self?.walkHome()
            }
        }
    }

    /// Send the pet back to its last-known "home" position.
    func walkHome() {
        guard let win = window, let home = homeOrigin else { return }
        walkReturnTimer?.invalidate()
        walkReturnTimer = nil
        isPerformingWalk = true
        animate(window: win, to: home, duration: 1.0) { [weak self] in
            self?.isPerformingWalk = false
            self?.animator?.set(.idle)
        }
    }

    private func animate(window: NSWindow, to origin: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrameOrigin(origin)
        }, completionHandler: completion)
    }

    private func handleTap() {
        // Tapping the pet always takes precedence: cancel any ongoing reminder.
        if walkReturnTimer != nil {
            walkHome()
        }
        togglePanel()
    }

    private func togglePanel() {
        if inputController?.isVisible == true {
            inputController?.hide()
            return
        }
        onOpenRequested?()
        let ctrl = QuickInputPanelController()
        ctrl.onSubmit = { [weak self] text, override in
            self?.onSubmit?(text, override)
        }
        ctrl.onDismiss = { [weak self] in
            self?.onPanelClosed?()
            self?.inputController = nil
        }
        if let frame = window?.frame {
            ctrl.show(near: frame)
        }
        self.inputController = ctrl
    }

    @objc private func windowMoved(_ note: Notification) {
        guard let win = window else { return }
        // Ignore programmatic moves during the reminder walk — we don't want
        // the pet's "home" to follow its reminder excursion.
        if !isPerformingWalk {
            let origin = win.frame.origin
            UserDefaults.standard.set(origin.x, forKey: "pet.origin.x")
            UserDefaults.standard.set(origin.y, forKey: "pet.origin.y")
            homeOrigin = origin
        }
        inputController?.reposition(near: win.frame)
    }
}
