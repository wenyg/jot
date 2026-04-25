import SwiftUI
import AppKit

/// Transparent overlay that handles pet window dragging via the *native*
/// `NSWindow.performDrag(with:)` API instead of SwiftUI's `DragGesture`.
///
/// Why: `DragGesture.onChanged { setFrameOrigin(...) }` runs the position
/// update on the SwiftUI event clock and can compete with rendering work on
/// the main thread, producing a stuttery drag. `performDrag` hands the move
/// off to the macOS window server, which moves the window frame-perfectly at
/// the display's refresh rate.
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
    let onDragBegan: () -> Void
    let onDragEnded: () -> Void
    let onHoverChange: (Bool) -> Void

    func makeNSView(context: Context) -> PetDragNSView {
        let v = PetDragNSView()
        v.onTap = onTap
        v.onDragBegan = onDragBegan
        v.onDragEnded = onDragEnded
        v.onHoverChange = onHoverChange
        return v
    }

    func updateNSView(_ nsView: PetDragNSView, context: Context) {
        nsView.onTap = onTap
        nsView.onDragBegan = onDragBegan
        nsView.onDragEnded = onDragEnded
        nsView.onHoverChange = onHoverChange
    }
}

final class PetDragNSView: NSView {
    var onTap: (() -> Void)?
    var onDragBegan: (() -> Void)?
    var onDragEnded: (() -> Void)?
    var onHoverChange: ((Bool) -> Void)?

    /// How far the cursor must move from the mousedown point before we treat
    /// the gesture as a drag (and therefore not a tap).
    private let dragSlop: CGFloat = 3

    private var mouseDownLocation: NSPoint?
    private var didStartDrag = false
    private var trackingArea: NSTrackingArea?

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
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = mouseDownLocation else { return }
        let here = event.locationInWindow
        let dx = here.x - start.x
        let dy = here.y - start.y

        // Once we've moved past the slop threshold, hand the rest of the
        // drag off to the window server. `performDrag` blocks until mouseUp,
        // so we won't get further mouseDragged events for this gesture.
        if !didStartDrag, hypot(dx, dy) > dragSlop {
            didStartDrag = true
            onDragBegan?()
            window?.performDrag(with: event)
            // performDrag returns when the user releases the mouse, so signal
            // drag end here. We won't see a mouseUp on this view because the
            // window server consumed it.
            onDragEnded?()
            mouseDownLocation = nil
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer { mouseDownLocation = nil }
        // performDrag swallowed the mouseUp; nothing to do.
        guard !didStartDrag else { return }
        // No drag happened → it's a tap.
        onTap?()
    }
}
