import SwiftUI

/// The sapphire-like gem on the cat's forehead — Yuumi's signature feature.
///
/// Rendered as a diamond (rotated square) with a rich blue-violet radial
/// gradient, a bright white specular highlight in the upper-left, and a
/// pulsing glow ring behind it that breathes in sync with the clock.
///
/// Positioned by the parent (CatView) so it sits dead-center between the ears.
struct CatMagicGem: View {
    @ObservedObject var animator: PetAnimator
    /// Size of the gem's bounding square.
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSince1970
            // Gentle breathing: 0.8 → 1.15
            let pulse = 1.0 + 0.18 * sin(t * 1.8)
            // Stronger pulse in celebrate/remind states.
            let pulseBoost = (animator.state == .celebrate) ? 1.0 + 0.12 * sin(t * 5.2) : 1.0
            let scale = CGFloat(pulse * pulseBoost)

            ZStack {
                // Outer halo — large soft glow that breathes.
                RadialGradient(
                    colors: [
                        CatTheme.gemAura.opacity(0.55),
                        CatTheme.gemAura.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 1.1
                )
                .frame(width: size * 2.2, height: size * 2.2)
                .blendMode(.plusLighter)
                .scaleEffect(scale)

                // The gem itself — a diamond (square rotated 45°).
                gemShape
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(45))
                    .shadow(color: CatTheme.gemAura.opacity(0.8), radius: 6)
                    .shadow(color: CatTheme.gemCore.opacity(0.6), radius: 2)
            }
        }
    }

    private var gemShape: some View {
        ZStack {
            // Base fill — blue-violet radial gradient, deeper at edges.
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(
                    RadialGradient(
                        colors: [
                            CatTheme.gemCore,
                            CatTheme.gemDeep
                        ],
                        center: UnitPoint(x: 0.35, y: 0.30),
                        startRadius: 0,
                        endRadius: size * 0.75
                    )
                )

            // Bright upper-left spec.
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            CatTheme.gemBright.opacity(0.95),
                            CatTheme.gemBright.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.50, height: size * 0.35)
                .offset(x: -size * 0.14, y: -size * 0.16)

            // Tiny sharp star-shine on the brightest corner.
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)
                .blur(radius: 0.6)
                .offset(x: -size * 0.22, y: -size * 0.22)

            // Facet line — a subtle diagonal crease giving the gem depth.
            Path { p in
                p.move(to: CGPoint(x: 0, y: size * 0.5))
                p.addLine(to: CGPoint(x: size, y: size * 0.5))
            }
            .stroke(CatTheme.gemDeep.opacity(0.4), lineWidth: 0.8)
        }
        // Clip fill + highlight to rounded square (we keep the outer glow outside).
        .clipShape(RoundedRectangle(cornerRadius: size * 0.12))
    }
}

#Preview {
    ZStack {
        Color(red: 0.98, green: 0.94, blue: 0.96)
        CatMagicGem(animator: PetAnimator(), size: 22)
    }
    .frame(width: 100, height: 100)
}
