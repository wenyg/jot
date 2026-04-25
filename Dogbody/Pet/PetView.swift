import SwiftUI
import AppKit

/// Thin shell around the pet renderer. Owns:
///   • drag/tap/hover dispatch (handled by the AppKit `PetDragHandle` overlay
///     for buttery-smooth window dragging via `NSWindow.performDrag`)
///   • cursor position tracking for pupil follow
///   • renderer selection (Rive vs the hand-drawn SwiftUI "Yuumi" cat)
///
/// All actual drawing lives in `RivePetView` (default) or `CatView`.
struct PetView: View {
    @ObservedObject var animator: PetAnimator
    let onTap: () -> Void
    let getWindow: () -> NSWindow?

    @State private var cursorTrackingTimer: Timer?

    /// Logical size of the cat's drawable frame (points). Must be large
    /// enough to hold the silhouette (which is bodyWidth × 1.18) plus some
    /// headroom above for accessories (z / sparkles / …) and extra to the
    /// right for tail flicks. Matches the PetWindow contentRect created in
    /// PetWindowController.
    private let frameWidth: CGFloat = 160
    private let frameHeight: CGFloat = 170

    /// Renderer to use. Defaults to Rive (the high-fidelity .riv file). Falls
    /// back to the original SwiftUI vector "Yuumi" build for users who set
    /// `defaults write com.dogbody.Dogbody pet.useRive -bool false`.
    private var useRive: Bool {
        // Treat the key as opt-out: anything other than an explicit `false`
        // means use Rive. Lets us ship Rive as the new default but keep the
        // hand-drawn cat as a one-flag escape hatch.
        let v = UserDefaults.standard.object(forKey: "pet.useRive")
        if let b = v as? Bool { return b }
        if let n = v as? NSNumber { return n.boolValue }
        return true
    }

    @ViewBuilder
    private var petBody: some View {
        if useRive {
            RivePetView(animator: animator, fileName: RivePetCatalog.active)
        } else {
            CatView(animator: animator, catScreenOrigin: currentScreenOrigin())
        }
    }

    var body: some View {
        ZStack {
            petBody
            // Native AppKit overlay handles drag via NSWindow.performDrag,
            // which is far smoother than SwiftUI's DragGesture + setFrameOrigin
            // because the window server runs the move off-thread from Rive's
            // Metal render loop.
            PetDragHandle(
                onTap: {
                    onTap()
                    animator.touch()
                },
                onDragBegan: {
                    animator.isBeingDragged = true
                },
                onDragEnded: {
                    animator.touch()
                    animator.isBeingDragged = false
                },
                onHoverChange: { hovering in
                    animator.isHovering = hovering
                    if hovering { startCursorTracking() }
                    else        { stopCursorTracking() }
                }
            )
        }
        .frame(width: frameWidth, height: frameHeight)
        .onAppear { startCursorTracking() }
        .onDisappear { stopCursorTracking() }
        .help("点我记一笔, 拖我换位置")
    }

    // MARK: - Cursor tracking

    /// We sample `NSEvent.mouseLocation` at 30 Hz while the cursor is near
    /// (or over) the pet. Cheaper than installing a global monitor and good
    /// enough to look "alive".
    private func startCursorTracking() {
        guard cursorTrackingTimer == nil else { return }
        cursorTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            let screenPoint = NSEvent.mouseLocation
            animator.cursorScreenPoint = screenPoint
        }
    }

    private func stopCursorTracking() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
        animator.cursorScreenPoint = nil
    }

    private func currentScreenOrigin() -> CGPoint {
        getWindow()?.frame.origin ?? .zero
    }
}
