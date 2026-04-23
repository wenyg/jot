import AppKit
import SwiftUI

final class PetWindowController: NSObject {
    private var window: PetWindow?
    private var inputController: QuickInputPanelController?

    var animator: PetAnimator?

    /// Called when the user submits text from the quick input panel.
    var onSubmit: ((String) -> Void)?
    /// Called when the quick input panel is about to open.
    var onOpenRequested: (() -> Void)?
    /// Called after the quick input panel closes.
    var onPanelClosed: (() -> Void)?

    var isVisible: Bool { window?.isVisible ?? false }

    func show() {
        if let win = window {
            win.orderFront(nil)
            return
        }
        let size = CGSize(width: 120, height: 120)
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let savedX = UserDefaults.standard.object(forKey: "pet.origin.x") as? CGFloat
        let savedY = UserDefaults.standard.object(forKey: "pet.origin.y") as? CGFloat
        let origin = CGPoint(
            x: savedX ?? (visible.maxX - size.width - 40),
            y: savedY ?? (visible.minY + 40)
        )
        let rect = CGRect(origin: origin, size: size)

        let win = PetWindow(contentRect: rect)
        let animatorRef = animator ?? PetAnimator()
        self.animator = animatorRef

        let view = PetView(
            animator: animatorRef,
            onTap: { [weak self] in self?.togglePanel() },
            getWindow: { [weak self] in self?.window }
        )
        win.contentView = NSHostingView(rootView: view)
        win.orderFront(nil)

        // Persist position when moved.
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

    private func togglePanel() {
        if inputController?.isVisible == true {
            inputController?.hide()
            return
        }
        onOpenRequested?()
        let ctrl = QuickInputPanelController()
        ctrl.onSubmit = { [weak self] text in
            self?.onSubmit?(text)
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
        let origin = win.frame.origin
        UserDefaults.standard.set(origin.x, forKey: "pet.origin.x")
        UserDefaults.standard.set(origin.y, forKey: "pet.origin.y")
        // If the input panel is up, reposition it to stay next to the pet.
        inputController?.reposition(near: win.frame)
    }
}
