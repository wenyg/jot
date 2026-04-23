import SwiftUI
import AppKit

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
            Text(emoji)
                .font(.system(size: petSize * 0.82))
                .scaleEffect(bodyScale)
                .rotationEffect(.degrees(bodyTilt))
                .offset(y: bodyBobY)
                .animation(.easeInOut(duration: 0.18), value: animator.frame)
                .animation(.easeInOut(duration: 0.25), value: animator.state)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

            stateBadge
                .offset(x: petSize * 0.32, y: -petSize * 0.36)
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
        .help(helpText)
    }

    // MARK: - Visuals

    /// Placeholder sprite: emoji that changes per state.
    /// Replace with an `Image(name)` frame sequence once art assets are in `Resources/PetSprites/`.
    private var emoji: String {
        switch animator.state {
        case .idle: return "🐶"
        case .happy: return "🐕"
        case .thinking: return "🐶"
        case .sleep: return "💤"
        case .celebrate: return "🎉"
        case .remind: return "🔔"
        }
    }

    private var bodyScale: CGFloat {
        let f = animator.frame
        switch animator.state {
        case .idle:
            return [1.00, 1.03, 1.00, 0.97][f % 4]
        case .happy:
            return [1.05, 1.15, 1.05, 1.10, 1.05, 1.00][f % 6]
        case .thinking:
            return [1.00, 1.02, 1.00, 1.02][f % 4]
        case .sleep:
            return [0.98, 1.02][f % 2]
        case .celebrate:
            return [1.00, 1.20, 1.00, 1.25, 1.10, 1.30, 1.05, 1.15][f % 8]
        case .remind:
            return [1.00, 1.20, 0.85, 1.20, 0.90, 1.10][f % 6]
        }
    }

    private var bodyTilt: Double {
        let f = animator.frame
        switch animator.state {
        case .celebrate:
            return [-8, 8, -10, 10, -6, 6, -4, 4][f % 8]
        case .remind:
            return [-12, 12, -10, 10, -6, 6][f % 6]
        case .happy:
            return [-3, 3, -3, 3, -2, 2][f % 6]
        default:
            return 0
        }
    }

    private var bodyBobY: CGFloat {
        let f = animator.frame
        switch animator.state {
        case .idle:
            return [0, -2, 0, 2][f % 4]
        case .sleep:
            return [0, -1][f % 2]
        default:
            return 0
        }
    }

    @ViewBuilder
    private var stateBadge: some View {
        switch animator.state {
        case .thinking:
            Text("💭")
                .font(.system(size: 22))
                .transition(.scale.combined(with: .opacity))
        case .sleep:
            Text("Z")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        case .happy:
            Text("✨")
                .font(.system(size: 20))
        default:
            EmptyView()
        }
    }

    private var helpText: String {
        "点击记一笔, 拖动换位置"
    }
}
