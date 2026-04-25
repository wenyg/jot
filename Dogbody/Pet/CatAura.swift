import SwiftUI

// MARK: - Body aura (soft glow hugging the silhouette)

/// A soft colored glow painted *behind* the cat's silhouette so she looks
/// perpetually magical. Rendered by stacking two large blurred silhouettes in
/// the aura color.
///
/// Because it's purely cosmetic, it sits as a separate layer in CatView —
/// it does not follow the body's squash / tilt (that would look like smeared
/// paint). Instead it gently breathes on its own clock.
struct CatBodyAura: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSince1970
            let breathe = 1.0 + 0.06 * sin(t * 1.1)
            let intensity = auraIntensity(for: animator.state)

            ZStack {
                CatSilhouette()
                    .fill(CatTheme.bodyAuraColor)
                    .blur(radius: 22)
                    .scaleEffect(CGFloat(breathe) * 1.08)
                    .opacity(0.55 * intensity)

                CatSilhouette()
                    .fill(CatTheme.bodyAuraColor)
                    .blur(radius: 10)
                    .scaleEffect(CGFloat(breathe) * 1.02)
                    .opacity(0.35 * intensity)
            }
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .animation(CatTheme.stateSpring, value: animator.state)
        }
    }

    private func auraIntensity(for state: PetState) -> Double {
        switch state {
        case .celebrate: return 1.6     // blaze when celebrating
        case .happy:     return 1.2
        case .remind:    return 1.25
        case .sleep:     return 0.5     // dimmer while napping
        default:         return 1.0
        }
    }
}

// MARK: - Floating stardust

/// A field of small twinkling star particles drifting around the cat. Each
/// star has its own independent lifecycle (fade in → drift → fade out → respawn
/// at a new random position) so the field never looks static.
struct CatStardust: View {
    @ObservedObject var animator: PetAnimator

    /// Number of active stardust particles. 7 feels "magical" without being busy.
    private static let count = 7

    /// Fixed per-particle seeds — we only generate them once so the stars
    /// don't jitter around on state changes.
    private let particles: [StardustParticle] = (0..<CatStardust.count).map { i in
        StardustParticle(
            seed: i,
            color: CatTheme.stardustColors[i % CatTheme.stardustColors.count],
            size: CGFloat.random(in: 3.5...6.5),
            period: Double.random(in: 3.8...6.5),
            phase: Double.random(in: 0...(2 * .pi)),
            orbitRadiusX: CGFloat.random(in: 0.45...0.65),
            orbitRadiusY: CGFloat.random(in: 0.35...0.55),
            orbitCenterX: CGFloat.random(in: 0.35...0.65),
            orbitCenterY: CGFloat.random(in: 0.35...0.60)
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSince1970
            let fieldIntensity = dustIntensity(for: animator.state)

            GeometryReader { geo in
                ZStack {
                    ForEach(particles, id: \.seed) { particle in
                        renderParticle(particle, time: t, geo: geo.size, fieldIntensity: fieldIntensity)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func renderParticle(_ p: StardustParticle, time: Double, geo: CGSize, fieldIntensity: Double) -> some View {
        // Lifecycle phase (0 → 1) — loops.
        let phaseT = (time + p.phase).truncatingRemainder(dividingBy: p.period) / p.period
        // Opacity fades in over the first 20%, out over the last 20%.
        let lifeOpacity: Double = {
            switch phaseT {
            case 0.0..<0.2:  return phaseT / 0.2
            case 0.2..<0.8:  return 1.0
            case 0.8...1.0:  return (1.0 - phaseT) / 0.2
            default:         return 0.0
            }
        }()
        // Slight spin / twinkle so the star "sparkles" rather than just glowing.
        let twinkle = 0.7 + 0.3 * sin(time * 6 + Double(p.seed))

        // Drift: move along a slow ellipse around the body.
        let angle = phaseT * 2 * .pi + p.phase * 0.3
        let cx = p.orbitCenterX + p.orbitRadiusX * 0.35 * CGFloat(cos(angle))
        let cy = p.orbitCenterY + p.orbitRadiusY * 0.35 * CGFloat(sin(angle * 1.2))
        // Slight upward drift over lifetime — stardust rises.
        let rise = CGFloat(1.0 - phaseT) * 8

        return StarMark(points: 4, innerRatio: 0.45)
            .fill(p.color)
            .frame(width: p.size, height: p.size)
            .blur(radius: 0.4)
            .shadow(color: p.color.opacity(0.8), radius: 3)
            .opacity(lifeOpacity * twinkle * fieldIntensity)
            .position(x: geo.width * cx, y: geo.height * cy - rise)
    }

    private func dustIntensity(for state: PetState) -> Double {
        switch state {
        case .celebrate: return 1.6
        case .happy:     return 1.2
        case .sleep:     return 0.4
        default:         return 1.0
        }
    }
}

private struct StardustParticle {
    let seed: Int
    let color: Color
    let size: CGFloat
    let period: Double
    let phase: Double
    /// Orbit ellipse radii as fractions of container size.
    let orbitRadiusX: CGFloat
    let orbitRadiusY: CGFloat
    /// Ellipse center as fractions of container size.
    let orbitCenterX: CGFloat
    let orbitCenterY: CGFloat
}

// MARK: - Star mark primitive

/// A classic 4-point star (slightly elongated on the vertical axis) — reads
/// as "magical sparkle" at small sizes. Used both for stardust and the tail
/// sparkle. The `points` parameter lets you request 4/5/6-pointers.
struct StarMark: Shape {
    var points: Int = 4
    var innerRatio: CGFloat = 0.45

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * innerRatio
        let totalPoints = points * 2
        for i in 0..<totalPoints {
            let angle = (Double(i) / Double(totalPoints)) * 2.0 * .pi - .pi / 2
            let r = i.isMultiple(of: 2) ? outerR : innerR
            let x = cx + CGFloat(cos(angle)) * r
            let y = cy + CGFloat(sin(angle)) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else      { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Floor shadow

/// A soft elliptical ground shadow that makes the cat look like she's
/// hovering. Fades / shifts with the body's bob.
struct CatFloorShadow: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSince1970
            // Shadow breathes slightly in anti-phase with the body's float.
            let breathe = 1.0 + 0.08 * sin(t * 1.6 + .pi)
            let stateScale: CGFloat = {
                switch animator.state {
                case .celebrate: return 1.1
                case .sleep:     return 1.2
                case .happy:     return 0.9
                default:         return 1.0
                }
            }()

            GeometryReader { geo in
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.34),
                                Color.black.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.35
                        )
                    )
                    .frame(
                        width: geo.size.width * 0.62 * CGFloat(breathe) * stateScale,
                        height: geo.size.width * 0.15 * CGFloat(breathe) * stateScale
                    )
                    .position(x: geo.size.width * 0.5, y: geo.size.height - 12)
            }
            .allowsHitTesting(false)
        }
    }
}
