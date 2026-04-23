import SwiftUI
import AppKit

/// Single-sprite pet: one PNG, all state differences expressed through
/// transform animations (scale / rotation / offset). No emoji stickers,
/// no thought bubbles, no "Z" decals — the design IS the typography.
struct PetView: View {
    @ObservedObject var animator: PetAnimator
    let onTap: () -> Void
    let getWindow: () -> NSWindow?

    @State private var dragStartOrigin: NSPoint?
    @State private var didDrag = false

    private let petSize: CGFloat = 96

    var body: some View {
        ZStack {
            Color.clear
            Image("pet")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: petSize, height: petSize)
                .opacity(bodyOpacity)
                .scaleEffect(x: bodyScaleX, y: bodyScaleY, anchor: .bottom)
                .rotationEffect(.degrees(bodyTilt), anchor: .bottom)
                .offset(x: bodyOffsetX, y: bodyOffsetY)
                .animation(.easeInOut(duration: 0.18), value: animator.frame)
                .animation(.easeInOut(duration: 0.3), value: animator.state)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .frame(width: petSize + 24, height: petSize + 24)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dragStartOrigin == nil, let win = getWindow() {
                        dragStartOrigin = win.frame.origin
                    }
                    if abs(value.translation.width) > 3 || abs(value.translation.height) > 3 {
                        didDrag = true
                    }
                    if let start = dragStartOrigin, let win = getWindow() {
                        let newOrigin = NSPoint(
                            x: start.x + value.translation.width,
                            y: start.y - value.translation.height
                        )
                        win.setFrameOrigin(newOrigin)
                    }
                }
                .onEnded { _ in
                    if !didDrag { onTap() }
                    animator.touch()
                    dragStartOrigin = nil
                    didDrag = false
                }
        )
        .help("点我记一笔, 拖我换位置")
    }

    // MARK: - Per-state transforms

    /// Vertical scale with bottom anchor (so breathing feels like a belly-rise,
    /// not a head-rise).
    private var bodyScaleY: CGFloat {
        let f = animator.frame
        switch animator.state {
        case .idle:
            return [1.000, 1.025, 1.015, 0.995][f % 4]
        case .happy:
            return [1.05, 1.12, 1.08, 1.10][f % 4]
        case .thinking:
            return [1.000, 1.015, 1.000, 1.015][f % 4]
        case .sleep:
            // A long, slow exhale. Pet is "lying down" → squashed vertically.
            return [0.56, 0.58, 0.57][f % 3]
        case .celebrate:
            return [1.00, 1.25, 1.00, 1.25, 1.05][f % 5]
        case .remind:
            return [1.00, 1.06, 1.00, 1.06][f % 4]
        }
    }

    private var bodyScaleX: CGFloat {
        switch animator.state {
        case .sleep: return 1.18  // splayed out while asleep
        case .celebrate: return 1.0
        default: return 1.0
        }
    }

    private var bodyTilt: Double {
        let f = animator.frame
        switch animator.state {
        case .celebrate:
            return [-8, 8, -10, 10, -4, 4][f % 6]
        case .remind:
            // Gentle head-tilt left-right — "hey, I'm here."
            return [-10, 10, -10, 10][f % 4]
        case .happy:
            return [-3, 3, -2, 2][f % 4]
        case .thinking:
            return [0, 4, 0, -4][f % 4]
        case .sleep:
            return 90  // lying on its side
        default:
            return 0
        }
    }

    private var bodyOffsetX: CGFloat {
        switch animator.state {
        case .sleep: return -4
        default: return 0
        }
    }

    private var bodyOffsetY: CGFloat {
        let f = animator.frame
        switch animator.state {
        case .idle:
            return [0, -1.5, 0, 1][f % 4]
        case .sleep:
            return 14  // settled onto the ground
        case .celebrate:
            return [0, -10, 0, -8, 0][f % 5]
        default:
            return 0
        }
    }

    private var bodyOpacity: Double {
        switch animator.state {
        case .sleep: return 0.75
        default: return 1.0
        }
    }
}
