import SwiftUI

/// A bezier-drawn tail that hinges off the cat's right hip and sways.
/// The tail is drawn *outside* the silhouette container because it needs to
/// extend beyond the body bounds when flicking.
///
/// Animation is driven by `animator.clock` via a `TimelineView` so the tail
/// keeps flowing even when no other state changes.
struct CatTail: View {
    @ObservedObject var animator: PetAnimator
    @Environment(\.self) private var env

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSince1970
            let cfg = tailConfig(for: animator.state)
            let phase = sin(t * cfg.speed + cfg.phaseOffset) * cfg.amplitude
            let curl = CGFloat(phase) + cfg.baseCurl

            GeometryReader { geo in
                ZStack {
                    // Tail stroke.
                    TailShape(curl: curl, lift: cfg.lift, puff: cfg.puff)
                        .stroke(
                            env.catBodyGradient,
                            style: StrokeStyle(
                                lineWidth: geo.size.width * 0.11,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)

                    // Tail-tip sparkle star.
                    let tip = TailShape.tipPoint(in: geo.size, curl: curl, lift: cfg.lift)
                    let twinkle = 0.85 + 0.15 * sin(t * 3.5)
                    let tipSize = geo.size.width * 0.11

                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(CatTheme.sparkPink)
                            .frame(width: tipSize * 2.2, height: tipSize * 2.2)
                            .blur(radius: 6)
                            .opacity(0.55 * twinkle)
                            .blendMode(.plusLighter)

                        // Star body
                        StarMark(points: 4, innerRatio: 0.40)
                            .fill(Color.white)
                            .frame(width: tipSize * 1.3, height: tipSize * 1.3)
                            .shadow(color: CatTheme.sparkPink.opacity(0.85), radius: 3)
                            .opacity(twinkle)
                    }
                    .position(tip)
                }
                .animation(CatTheme.stateSpring, value: animator.state)
            }
        }
    }

    // MARK: - Per-state tail personality

    private struct TailConfig {
        let speed: Double
        let amplitude: Double   // radians of sway
        let phaseOffset: Double
        let baseCurl: CGFloat   // steady-state curl offset
        let lift: CGFloat       // 0 = drooping, 1 = straight up
        let puff: CGFloat       // 0 = normal, 1 = fully puffed / spiky
    }

    private func tailConfig(for state: PetState) -> TailConfig {
        if animator.isBeingDragged {
            return TailConfig(speed: 10, amplitude: 0.35, phaseOffset: 0, baseCurl: 0, lift: 0.9, puff: 0.8)
        }
        switch state {
        case .idle:      return .init(speed: 1.4, amplitude: 0.25, phaseOffset: 0,   baseCurl: -0.10, lift: 0.30, puff: 0)
        case .happy:     return .init(speed: 3.8, amplitude: 0.55, phaseOffset: 0,   baseCurl:  0.10, lift: 0.55, puff: 0.1)
        case .thinking:  return .init(speed: 0.9, amplitude: 0.12, phaseOffset: 0,   baseCurl: -0.20, lift: 0.25, puff: 0)
        case .sleep:     return .init(speed: 0.4, amplitude: 0.05, phaseOffset: 0,   baseCurl:  0.45, lift: 0.10, puff: 0) // curled
        case .celebrate: return .init(speed: 6.5, amplitude: 0.70, phaseOffset: 0,   baseCurl:  0.00, lift: 0.85, puff: 0.25)
        case .remind:    return .init(speed: 2.6, amplitude: 0.30, phaseOffset: 0,   baseCurl: -0.05, lift: 0.45, puff: 0)
        }
    }
}

/// Single bezier spline from hip → tip. Parameterized by:
///   • `curl`: radians of sway applied to mid-control
///   • `lift`: how high (0…1) the tip sits relative to the hip
///   • `puff`: how thick the tail becomes (scalar on stroke width — applied
///     by the caller via a future enhancement)
private struct TailShape: Shape {
    var curl: CGFloat
    var lift: CGFloat
    var puff: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { .init(.init(curl, lift), puff) }
        set {
            curl = newValue.first.first
            lift = newValue.first.second
            puff = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        let hip = CGPoint(x: w * 0.88, y: h * 0.82)
        let tip = Self.tipPoint(in: CGSize(width: w, height: h), curl: curl, lift: lift)
        let mid = CGPoint(
            x: w * 0.95 + sin(curl) * w * 0.06,
            y: h * 0.72 - h * 0.25 * lift + cos(curl) * h * 0.10
        )
        p.move(to: hip)
        p.addQuadCurve(to: tip, control: mid)
        return p
    }

    /// Exposed so CatTail can position the tail-tip sparkle at the exact
    /// same coordinates the stroke terminates at.
    static func tipPoint(in size: CGSize, curl: CGFloat, lift: CGFloat) -> CGPoint {
        let w = size.width
        let h = size.height
        let baseTipX = w * 1.02
        let baseTipY = h * 0.78 - h * 0.42 * lift
        return CGPoint(
            x: baseTipX + cos(curl) * w * 0.10,
            y: baseTipY + sin(curl) * h * 0.18
        )
    }
}
