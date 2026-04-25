import SwiftUI

/// Mouth. Morphs between four shapes:
///   • idle / remind  — a tiny classic "ω" kitty mouth
///   • happy / celebrate — a wide upward smile
///   • thinking        — a small "o"
///   • sleep           — a flat line
///
/// We just switch between different Shape paths; SwiftUI's built-in
/// transaction animation will handle the fade for us via `.id()`.
struct CatMouth: View {
    @ObservedObject var animator: PetAnimator
    @Environment(\.catFeatureStroke) private var stroke

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Anchor mouth at ~58% down the head.
            let cx = w * 0.50
            let cy = h * 0.58

            Group {
                switch animator.state {
                case .happy, .celebrate:
                    SmileMouth()
                        .stroke(stroke, style: StrokeStyle(lineWidth: max(1.2, w * 0.018), lineCap: .round))
                        .frame(width: w * 0.16, height: h * 0.08)
                        .position(x: cx, y: cy + h * 0.02)
                        .transition(.opacity)

                case .thinking:
                    Circle()
                        .stroke(stroke, lineWidth: max(1.0, w * 0.014))
                        .frame(width: w * 0.05, height: w * 0.05)
                        .position(x: cx, y: cy + h * 0.01)
                        .transition(.opacity)

                case .sleep:
                    Rectangle()
                        .fill(stroke)
                        .frame(width: w * 0.10, height: max(1.0, h * 0.01))
                        .position(x: cx, y: cy + h * 0.02)
                        .transition(.opacity)

                case .idle, .remind:
                    OmegaMouth()
                        .stroke(stroke, style: StrokeStyle(lineWidth: max(1.2, w * 0.016), lineCap: .round, lineJoin: .round))
                        .frame(width: w * 0.14, height: h * 0.06)
                        .position(x: cx, y: cy + h * 0.01)
                        .transition(.opacity)
                }
            }
            .animation(CatTheme.stateSpring, value: animator.state)
        }
    }
}

/// A wide smile: gentle upward curve.
private struct SmileMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.4)
        )
        return p
    }
}

/// A tiny "ω" cat-mouth, no nose — the nose is painted separately in
/// CatView as a pink dot so it can use a dedicated color.
private struct OmegaMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let mid = CGPoint(x: rect.midX, y: rect.minY)
        // Left half.
        p.move(to: mid)
        p.addQuadCurve(
            to: CGPoint(x: rect.midX - w * 0.45, y: rect.maxY),
            control: CGPoint(x: rect.midX - w * 0.22, y: rect.maxY * 1.1)
        )
        // Right half.
        p.move(to: mid)
        p.addQuadCurve(
            to: CGPoint(x: rect.midX + w * 0.45, y: rect.maxY),
            control: CGPoint(x: rect.midX + w * 0.22, y: rect.maxY * 1.1)
        )
        return p
    }
}

/// Two peach blush circles that fade in during positive states.
struct CatBlush: View {
    @ObservedObject var animator: PetAnimator

    private var intensity: Double {
        switch animator.state {
        case .happy:     return 0.85
        case .celebrate: return 1.00
        case .remind:    return 0.60
        case .thinking:  return 0.45
        case .idle:      return 0.40  // Yuumi is always a little pink
        case .sleep:     return 0.25
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let blushSize: CGFloat = w * 0.13
            let y = h * 0.48

            ZStack {
                Circle()
                    .fill(CatTheme.blush)
                    .frame(width: blushSize, height: blushSize * 0.75)
                    .blur(radius: blushSize * 0.25)
                    .position(x: w * 0.22, y: y)

                Circle()
                    .fill(CatTheme.blush)
                    .frame(width: blushSize, height: blushSize * 0.75)
                    .blur(radius: blushSize * 0.25)
                    .position(x: w * 0.78, y: y)
            }
            .opacity(intensity)
            .animation(CatTheme.stateSpring, value: animator.state)
        }
    }
}

// MARK: - Environment plumbing for color-scheme-aware stroke

extension EnvironmentValues {
    /// Computed from colorScheme — picks the right stroke color so features
    /// stay readable on both the dark-purple and cream-cat bodies.
    var catFeatureStroke: Color {
        colorScheme == .dark ? CatTheme.featureStrokeDark : CatTheme.featureStrokeLight
    }
}
