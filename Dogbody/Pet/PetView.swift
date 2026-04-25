import SwiftUI

/// Thin shell around the pet renderer. Owns:
///   • drag/tap/hover dispatch (handled by the AppKit `PetDragHandle` overlay
///     for buttery-smooth window dragging via `NSWindow.performDrag`)
///
/// All actual drawing lives in `ImageDogView`.
struct PetView: View {
    @ObservedObject var animator: PetAnimator
    let onTap: () -> Void

    /// Logical size of the pet's drawable frame (points). Must be large
    /// enough to hold the silhouette (which is bodyWidth × 1.18) plus some
    /// headroom above for accessories (z / sparkles / …) and extra to the
    /// right for tail flicks. Matches the PetWindow contentRect created in
    /// PetWindowController.
    private let frameWidth: CGFloat = 160
    private let frameHeight: CGFloat = 170

    var body: some View {
        ZStack {
            ImageDogView(animator: animator)
            // Native AppKit overlay handles drag via NSWindow.performDrag,
            // which is far smoother than SwiftUI's DragGesture + setFrameOrigin
            // because the window server runs the move off-thread from SwiftUI.
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
                }
            )
        }
        .frame(width: frameWidth, height: frameHeight)
        .help("点我记一笔, 拖我换位置")
    }
}
