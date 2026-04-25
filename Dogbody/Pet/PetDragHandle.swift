import SwiftUI
import AppKit

/// Transparent overlay that handles pet window dragging via direct AppKit
/// `mouseDragged` + `setFrameOrigin`, *not* SwiftUI's `DragGesture` and not
/// `NSWindow.performDrag`.
///
/// Why not SwiftUI's `DragGesture`: it runs through SwiftUI's hit-testing /
/// gesture pipeline on every event, which competes with view body rebuilds
/// and tends to stutter for window-following drags.
///
/// Why not `NSWindow.performDrag(with:)`: that call *blocks the main thread*
/// until mouse-up, so SwiftUI never gets to commit the `isBeingDragged = true`
/// state change — the pet sprite never flips to `dog_dragging` and the
/// in-drag wiggle animation never ticks. Doing the move ourselves with
/// `setFrameOrigin` on each `mouseDragged` keeps the runloop alive so the
/// sprite updates and animates throughout the drag.
///
/// Also handles tap detection: if the cursor doesn't move beyond
/// `dragSlop` between mouseDown and mouseUp, we treat it as a click and
/// call `onTap` instead of dragging.
///
/// Hit testing follows the same generous rounded-rect silhouette as the old
/// `PetHitShape` so that clicks in the transparent corners of the pet's
/// bounding box pass through to the desktop, not the pet.
struct PetDragHandle: NSViewRepresentable {
    let onTap: () -> Void
    let onRightClick: () -> Void
    let onDragBegan: () -> Void
    let onDragEnded: () -> Void
    let onHoverChange: (Bool) -> Void

    func makeNSView(context: Context) -> PetDragNSView {
        let v = PetDragNSView()
        v.onTap = onTap
        v.onRightClick = onRightClick
        v.onDragBegan = onDragBegan
        v.onDragEnded = onDragEnded
        v.onHoverChange = onHoverChange
        return v
    }

    func updateNSView(_ nsView: PetDragNSView, context: Context) {
        nsView.onTap = onTap
        nsView.onRightClick = onRightClick
        nsView.onDragBegan = onDragBegan
        nsView.onDragEnded = onDragEnded
        nsView.onHoverChange = onHoverChange
    }
}

final class PetDragNSView: NSView {
    var onTap: (() -> Void)?
    var onRightClick: (() -> Void)?
    var onDragBegan: (() -> Void)?
    var onDragEnded: (() -> Void)?
    var onHoverChange: ((Bool) -> Void)?

    /// How far the cursor must move from the mousedown point before we treat
    /// the gesture as a drag (and therefore not a tap).
    private let dragSlop: CGFloat = 3

    private var mouseDownLocation: NSPoint?
    private var didStartDrag = false
    private var trackingArea: NSTrackingArea?

    // Captured at mouseDown so we can compute the new window origin from the
    // global cursor delta on each mouseDragged. Using screen coords (rather
    // than `event.locationInWindow` deltas) avoids feedback loops once the
    // window itself starts moving.
    private var dragStartScreenLocation: NSPoint?
    private var windowOriginAtDragStart: NSPoint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        // Fully transparent — we only exist to capture mouse events.
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Hit testing (drop transparent corners)

    /// Mirrors the old SwiftUI `PetHitShape`: a rounded rect inset 8% on each
    /// side. Outside that shape, return nil so the click goes to the desktop
    /// (or to whatever's behind us), preventing accidental drags from clicks
    /// in the pet's empty bounding-box corners.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let inset = bounds.width * 0.08
        let inner = bounds.insetBy(dx: inset, dy: inset)
        let radius = bounds.width * 0.35
        let path = NSBezierPath(roundedRect: inner, xRadius: radius, yRadius: radius)
        return path.contains(point) ? self : nil
    }

    // MARK: - Hover tracking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) { onHoverChange?(true) }
    override func mouseExited(with event: NSEvent)  { onHoverChange?(false) }

    // MARK: - Click vs drag

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        didStartDrag = false
        dragStartScreenLocation = NSEvent.mouseLocation
        windowOriginAtDragStart = window?.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = mouseDownLocation,
              let win = window,
              let dragStartScreen = dragStartScreenLocation,
              let originAtStart = windowOriginAtDragStart
        else { return }

        let here = event.locationInWindow
        let dx = here.x - start.x
        let dy = here.y - start.y

        if !didStartDrag, hypot(dx, dy) > dragSlop {
            didStartDrag = true
            onDragBegan?()
        }

        guard didStartDrag else { return }

        // Move via global cursor delta against the window origin captured at
        // mouseDown — independent of how far the window itself has moved so
        // far this gesture.
        let now = NSEvent.mouseLocation
        let newOrigin = NSPoint(
            x: originAtStart.x + (now.x - dragStartScreen.x),
            y: originAtStart.y + (now.y - dragStartScreen.y)
        )
        win.setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            mouseDownLocation = nil
            dragStartScreenLocation = nil
            windowOriginAtDragStart = nil
        }
        if didStartDrag {
            onDragEnded?()
            return
        }
        onTap?()
    }

    // Right-click (and ctrl-click, which AppKit also routes through
    // `rightMouseUp`): the pet's calm second action — open today's review.
    override func rightMouseUp(with event: NSEvent) {
        onRightClick?()
    }
}
