import SwiftUI

/// State-specific decorations that float *above* the cat's head (or beside it):
///   • thinking  — three dots that cascade in & out
///   • sleep     — "z"s drifting upward
///   • celebrate — sparkle particles bursting out on every sparkleTick
///   • remind    — a pulsing notification dot
struct CatAccessories: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        ZStack {
            ThinkingDots(animator: animator)
                .opacity(animator.state == .thinking ? 1 : 0)
                .animation(CatTheme.stateSpring, value: animator.state)

            SleepZs(animator: animator)
                .opacity(animator.state == .sleep ? 1 : 0)
                .animation(CatTheme.stateSpring, value: animator.state)

            ReminderDot(animator: animator)
                .opacity(animator.state == .remind ? 1 : 0)
                .animation(CatTheme.stateSpring, value: animator.state)

            CelebrationSparkles(animator: animator)
                .opacity(animator.state == .celebrate ? 1 : 0)
                .animation(CatTheme.stateSpring, value: animator.state)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Thinking "..."

private struct ThinkingDots: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSince1970
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let dotSize: CGFloat = 5
                let cy = h * 0.08
                let cx = w * 0.50
                HStack(spacing: 5) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(CatTheme.thinkDot)
                            .frame(width: dotSize, height: dotSize)
                            .scaleEffect(dotScale(at: i, time: t))
                            .opacity(dotOpacity(at: i, time: t))
                    }
                }
                .position(x: cx + w * 0.18, y: cy)
            }
        }
    }

    private func dotScale(at index: Int, time: Double) -> CGFloat {
        let phase = time * 2.8 - Double(index) * 0.5
        let v = max(0.5, 1.0 + sin(phase) * 0.4)
        return CGFloat(v)
    }
    private func dotOpacity(at index: Int, time: Double) -> Double {
        let phase = time * 2.8 - Double(index) * 0.5
        return 0.55 + sin(phase) * 0.35
    }
}

// MARK: - Sleep "z"

private struct SleepZs: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSince1970
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    ForEach(0..<3) { i in
                        let cycle = 3.0
                        let phase = (t + Double(i) * 1.0).truncatingRemainder(dividingBy: cycle) / cycle
                        let y = (1.0 - phase) * Double(geo.size.height) * 0.35
                        let opacity = sin(phase * .pi) * 0.9
                        Text("z")
                            .font(.system(size: 18 - CGFloat(i) * 3, weight: .semibold, design: .rounded))
                            .foregroundColor(CatTheme.zSleep)
                            .position(
                                x: w * 0.72 + CGFloat(sin(phase * .pi * 2)) * 4,
                                y: CGFloat(y) + 6
                            )
                            .opacity(opacity)
                    }
                }
            }
        }
    }
}

// MARK: - Reminder red dot

private struct ReminderDot: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSince1970
            let pulse = 1.0 + sin(t * 5.0) * 0.12
            GeometryReader { geo in
                let w = geo.size.width
                Circle()
                    .fill(CatTheme.dotReminder)
                    .frame(width: 8, height: 8)
                    .shadow(color: CatTheme.dotReminder.opacity(0.7), radius: 6)
                    .scaleEffect(CGFloat(pulse))
                    .position(x: w * 0.78, y: geo.size.height * 0.05)
            }
        }
    }
}

// MARK: - Celebration sparkles

/// A burst of 6 particles fanning out from the top of the head every time
/// `animator.sparkleTick` increments.
private struct CelebrationSparkles: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        ZStack {
            ForEach(Array(burstParticles.enumerated()), id: \.offset) { idx, particle in
                SparkleParticle(
                    particle: particle,
                    triggerId: animator.sparkleTick
                )
            }
        }
    }

    private static let burstParticles: [Particle] = (0..<8).map { i in
        let angle = Double(i) / 8.0 * .pi * 2
        let colorIdx = i % 3
        return Particle(
            angle: angle,
            distance: CGFloat.random(in: 28...44),
            color: [CatTheme.sparkGold, CatTheme.sparkPink, CatTheme.sparkCyan][colorIdx],
            size: CGFloat.random(in: 5...9)
        )
    }
    private var burstParticles: [Particle] { Self.burstParticles }

    struct Particle {
        let angle: Double
        let distance: CGFloat
        let color: Color
        let size: CGFloat
    }
}

private struct SparkleParticle: View {
    let particle: CelebrationSparkles.Particle
    let triggerId: Int

    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let originX = geo.size.width * 0.5
            let originY = geo.size.height * 0.08
            let x = originX + cos(particle.angle) * Double(particle.distance) * Double(progress)
            let y = originY + sin(particle.angle) * Double(particle.distance) * Double(progress) - Double(progress) * 10
            ZStack {
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: 1)
                Circle()
                    .fill(Color.white)
                    .frame(width: particle.size * 0.4, height: particle.size * 0.4)
            }
            .position(x: x, y: y)
            .opacity(Double(1 - progress))
            .scaleEffect(0.4 + (1 - progress) * 0.8)
        }
        .onChange(of: triggerId) { _ in
            progress = 0
            withAnimation(.easeOut(duration: 0.8)) { progress = 1 }
        }
    }
}
