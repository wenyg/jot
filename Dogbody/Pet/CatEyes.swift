import SwiftUI
import AppKit

/// A pair of eyes with three independently animated behaviors:
///   • **Blinking** — one-shot squash driven by `animator.blinkTick`.
///   • **Tracking** — pupils drift toward `animator.cursorScreenPoint`.
///   • **Mood shape** — the whole eye becomes a wave / arc / wide stare
///     depending on `animator.state`.
///
/// The parent (`CatView`) positions this as a single container; eye positions
/// within it are normalized to the 1×1 coordinate space of the silhouette.
struct CatEyes: View {
    @ObservedObject var animator: PetAnimator
    /// Rendered container size (the cat's body frame).
    let size: CGSize
    /// Where the cat currently lives on screen (origin in screen coords).
    /// Used to compute the cursor → pupil vector.
    let catScreenOrigin: CGPoint

    // Blink: when blinkTick changes we drive `blinkPhase` through 0 → 1 → 0.
    @State private var blinkPhase: CGFloat = 0

    var body: some View {
        ZStack {
            eye(isLeft: true)
            eye(isLeft: false)
        }
        .onChange(of: animator.blinkTick) { _ in performBlink() }
    }

    // MARK: - Single eye

    @ViewBuilder
    private func eye(isLeft: Bool) -> some View {
        // Eye center in normalized body coordinates.
        // Eyes are large and set slightly farther apart than a realistic cat —
        // Yuumi's eyes are her defining trait, they dominate the face.
        let cx: CGFloat = isLeft ? 0.33 : 0.67
        let cy: CGFloat = 0.42
        let eyeW: CGFloat = 0.20
        let eyeH: CGFloat = 0.24

        let center = CGPoint(x: size.width * cx, y: size.height * cy)
        let baseSize = CGSize(width: size.width * eyeW, height: size.height * eyeH)

        // Pupil offset from cursor tracking.
        let pupilOffset = computePupilOffset(eyeCenterInBody: center)

        ZStack {
            // A soft magenta glow underneath each eye so they look luminous.
            Circle()
                .fill(CatTheme.eyeGlow)
                .frame(width: baseSize.width * 1.6, height: baseSize.width * 1.6)
                .blur(radius: 10)
                .opacity(eyeGlowIntensity)
                .blendMode(.plusLighter)

            eyeShape(isLeft: isLeft, baseSize: baseSize, pupilOffset: pupilOffset)
        }
        .frame(width: baseSize.width * 1.6, height: baseSize.width * 1.6)
        .position(center)
    }

    /// Eye glow fades out for non-active states so the face doesn't look "wet"
    /// all the time.
    private var eyeGlowIntensity: Double {
        switch animator.state {
        case .celebrate: return 0.55
        case .happy:     return 0.40
        case .remind:    return 0.45
        case .sleep:     return 0.0
        case .thinking:  return 0.30
        case .idle:      return 0.32
        }
    }

    /// Switches between the structural representations of the eye — a full
    /// eye, a closed arc, a wave, a wide stare — and applies the blink squash
    /// uniformly on top.
    @ViewBuilder
    private func eyeShape(isLeft: Bool, baseSize: CGSize, pupilOffset: CGPoint) -> some View {
        let blinkScale = 1.0 - blinkPhase * 0.95  // squash ≈ to zero at peak

        switch animator.state {
        case .sleep:
            // Permanently closed: a downward arc.
            ClosedEyeArc(downward: true)
                .stroke(Color(red: 0.25, green: 0.23, blue: 0.30), lineWidth: max(1.2, baseSize.height * 0.22))
                .frame(width: baseSize.width * 1.2, height: baseSize.height * 0.7)

        case .happy, .celebrate:
            // Upward-curving "^_^" eyes.
            ClosedEyeArc(downward: false)
                .stroke(Color(red: 0.15, green: 0.13, blue: 0.20), lineWidth: max(1.2, baseSize.height * 0.24))
                .frame(width: baseSize.width * 1.25, height: baseSize.height * 0.7)
                .scaleEffect(y: blinkScale, anchor: .center)

        case .thinking:
            // One eye stays open (tracks cursor); the other becomes a wavy line.
            if isLeft {
                openEye(baseSize: baseSize, pupilOffset: pupilOffset, blinkScale: blinkScale)
            } else {
                WavyLine()
                    .stroke(Color(red: 0.20, green: 0.18, blue: 0.25), style: StrokeStyle(lineWidth: max(1.2, baseSize.height * 0.22), lineCap: .round))
                    .frame(width: baseSize.width * 1.3, height: baseSize.height * 0.5)
            }

        case .remind:
            // Wide, alert eyes with a subtle pulse.
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSince1970
                let pulse = 1.0 + 0.08 * sin(t * 4.5)
                openEye(baseSize: baseSize, pupilOffset: pupilOffset, blinkScale: blinkScale)
                    .scaleEffect(pulse, anchor: .center)
            }

        case .idle:
            openEye(baseSize: baseSize, pupilOffset: pupilOffset, blinkScale: blinkScale)
        }
    }

    /// The "normal" open eye — Yuumi-style:
    ///   • warm-white ellipse
    ///   • big pink-violet iris (pupil) with its own radial gradient
    ///   • main circular spec (upper-left)
    ///   • tiny star-sparkle (upper-right) for that magical girl shine
    ///   • thin bottom inner-rim highlight
    private func openEye(baseSize: CGSize, pupilOffset: CGPoint, blinkScale: CGFloat) -> some View {
        ZStack {
            // Eye white.
            Ellipse()
                .fill(CatTheme.eyeWhite)

            // Iris.
            Circle()
                .fill(CatTheme.pupilGradient)
                .frame(width: baseSize.width * 0.82, height: baseSize.width * 0.82)
                .offset(x: pupilOffset.x, y: pupilOffset.y)

            // Warm inner rim — simulates the iris's edge catching light.
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.95).opacity(0.85),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    ),
                    lineWidth: 1
                )
                .frame(width: baseSize.width * 0.82, height: baseSize.width * 0.82)
                .offset(x: pupilOffset.x, y: pupilOffset.y)

            // Main round specular (upper-left).
            Circle()
                .fill(CatTheme.eyeSpec)
                .frame(width: baseSize.width * 0.26, height: baseSize.width * 0.26)
                .blur(radius: 0.3)
                .offset(
                    x: pupilOffset.x - baseSize.width * 0.18,
                    y: pupilOffset.y - baseSize.width * 0.22
                )

            // Star sparkle (upper-right) — this is the "magical" hit.
            StarMark(points: 4, innerRatio: 0.38)
                .fill(Color.white)
                .frame(width: baseSize.width * 0.24, height: baseSize.width * 0.24)
                .shadow(color: Color.white.opacity(0.9), radius: 1.5)
                .offset(
                    x: pupilOffset.x + baseSize.width * 0.20,
                    y: pupilOffset.y - baseSize.width * 0.14
                )
        }
        .scaleEffect(y: blinkScale, anchor: .center)
    }

    // MARK: - Pupil tracking

    /// Returns how far the pupil should drift inside the eye, based on the
    /// current cursor position. Returned in points within the eye's coord
    /// space.
    private func computePupilOffset(eyeCenterInBody: CGPoint) -> CGPoint {
        guard let cursorScreen = animator.cursorScreenPoint else { return .zero }
        // Convert the eye's center into screen coordinates.
        let eyeScreen = CGPoint(
            x: catScreenOrigin.x + eyeCenterInBody.x,
            y: catScreenOrigin.y + (size.height - eyeCenterInBody.y) // flip Y for AppKit
        )
        let dx = cursorScreen.x - eyeScreen.x
        let dy = cursorScreen.y - eyeScreen.y
        let dist = sqrt(dx * dx + dy * dy)
        guard dist > 0.001 else { return .zero }
        let r = CatTheme.pupilTrackingRadius
        // Clamp to the tracking radius — beyond ~200 pt the pupil saturates.
        let saturation: CGFloat = 200
        let scale = min(dist, saturation) / saturation
        return CGPoint(
            x: (dx / dist) * r * scale,
            y: -(dy / dist) * r * scale   // flip back into SwiftUI's down-positive Y
        )
    }

    // MARK: - Blink driver

    private func performBlink() {
        withAnimation(.easeIn(duration: CatTheme.blinkCloseDuration)) {
            blinkPhase = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + CatTheme.blinkCloseDuration + CatTheme.blinkHoldDuration) {
            withAnimation(.easeOut(duration: CatTheme.blinkOpenDuration)) {
                blinkPhase = 0
            }
        }
    }
}

// MARK: - Shapes

/// A shallow arc used for closed / happy / sleepy eyes.
private struct ClosedEyeArc: Shape {
    let downward: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midY = rect.midY
        if downward {
            // ︶
            p.move(to: CGPoint(x: rect.minX, y: midY - rect.height * 0.15))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: midY - rect.height * 0.15),
                control: CGPoint(x: rect.midX, y: midY + rect.height * 0.55)
            )
        } else {
            // ⌒
            p.move(to: CGPoint(x: rect.minX, y: midY + rect.height * 0.15))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: midY + rect.height * 0.15),
                control: CGPoint(x: rect.midX, y: midY - rect.height * 0.55)
            )
        }
        return p
    }
}

/// A 2-crest sine wave for the thinking eye.
private struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let steps = 24
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = rect.minX + t * rect.width
            let y = rect.midY + sin(t * .pi * 4) * rect.height * 0.35
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else      { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }
}
