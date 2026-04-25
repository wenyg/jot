import SwiftUI

/// The cat's silhouette — head fused with body into one continuous blob, plus
/// two triangular ears. Drawn as a single closed Path so we get a clean
/// silhouette with no seams between head & body.
///
/// Proportions are normalized to a 1×1 unit square (`rect.width == 1`).
/// The `CatView` scales the whole thing via `.frame(width:height:)`.
struct CatSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()

        // We build the silhouette as a single closed curve starting from the
        // left ear tip, going clockwise around head → body → tail-stub → back.
        //
        // Coordinates are authored with 0,0 = top-left (SwiftUI default).

        // --- Left ear ---
        p.move(to: CGPoint(x: w * 0.18, y: h * 0.26))              // left ear base-outer
        p.addLine(to: CGPoint(x: w * 0.24, y: h * 0.02))           // left ear tip
        p.addQuadCurve(
            to: CGPoint(x: w * 0.42, y: h * 0.12),                 // left ear base-inner
            control: CGPoint(x: w * 0.34, y: h * 0.02)
        )

        // --- Head top arc (between the ears) ---
        p.addQuadCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.12),                 // right ear base-inner
            control: CGPoint(x: w * 0.50, y: h * 0.08)
        )

        // --- Right ear ---
        p.addQuadCurve(
            to: CGPoint(x: w * 0.76, y: h * 0.02),                 // right ear tip
            control: CGPoint(x: w * 0.66, y: h * 0.02)
        )
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.26))           // right ear base-outer

        // --- Head right side, sweeping down and out into the body shoulders ---
        p.addCurve(
            to: CGPoint(x: w * 0.96, y: h * 0.62),                 // right shoulder
            control1: CGPoint(x: w * 0.96, y: h * 0.30),
            control2: CGPoint(x: w * 1.00, y: h * 0.48)
        )

        // --- Body right side down to bottom-right corner ---
        p.addCurve(
            to: CGPoint(x: w * 0.90, y: h * 0.95),                 // bottom-right of body
            control1: CGPoint(x: w * 0.96, y: h * 0.80),
            control2: CGPoint(x: w * 0.94, y: h * 0.90)
        )

        // --- Bottom curve (belly / feet) ---
        p.addQuadCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.95),                 // bottom-left
            control: CGPoint(x: w * 0.50, y: h * 1.02)
        )

        // --- Body left side up to shoulder ---
        p.addCurve(
            to: CGPoint(x: w * 0.04, y: h * 0.62),
            control1: CGPoint(x: w * 0.06, y: h * 0.90),
            control2: CGPoint(x: w * 0.04, y: h * 0.80)
        )

        // --- Left cheek up to ear base ---
        p.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.26),                 // close at left ear base-outer
            control1: CGPoint(x: w * 0.00, y: h * 0.48),
            control2: CGPoint(x: w * 0.04, y: h * 0.30)
        )

        p.closeSubpath()
        return p
    }
}

/// Inner-ear triangle — a secondary path that sits on top of the silhouette
/// to hint at a fleshy pink inside. One instance per ear.
struct CatInnerEar: Shape {
    /// True for left ear, false for right. We mirror the path manually rather
    /// than use `.scaleEffect(x: -1)` so the anchor & hit-test stay clean.
    let isLeft: Bool

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        if isLeft {
            p.move(to:    CGPoint(x: w * 0.22, y: h * 0.20))
            p.addLine(to: CGPoint(x: w * 0.27, y: h * 0.06))
            p.addLine(to: CGPoint(x: w * 0.37, y: h * 0.17))
        } else {
            p.move(to:    CGPoint(x: w * 0.78, y: h * 0.20))
            p.addLine(to: CGPoint(x: w * 0.73, y: h * 0.06))
            p.addLine(to: CGPoint(x: w * 0.63, y: h * 0.17))
        }
        p.closeSubpath()
        return p
    }
}

/// The complete rendered body: silhouette + gradient + ceramic highlight +
/// inner ears + stacked shadows. Pure visual — no animation logic here;
/// transforms (breathing, squash, tilt) are applied by CatView.
struct CatBody: View {
    @Environment(\.self) private var env

    var body: some View {
        ZStack {
            // Silhouette fill.
            CatSilhouette()
                .fill(env.catBodyGradient)

            // Ceramic highlight across the top.
            CatSilhouette()
                .fill(CatTheme.bodyHighlight)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            // Inner ears.
            CatInnerEar(isLeft: true)
                .fill(env.catEarInner)
                .blur(radius: 0.6)
            CatInnerEar(isLeft: false)
                .fill(env.catEarInner)
                .blur(radius: 0.6)
        }
        // Outer stacked shadows — applied once to the whole group so they
        // cast off the silhouette without doubling up per layer.
        .compositingGroup()
        .shadow(color: .black.opacity(0.30), radius: 1,  x: 0, y: 1)
        .shadow(color: .black.opacity(0.18), radius: 8,  x: 0, y: 5)
        .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        CatBody()
            .frame(width: 120, height: 140)
    }
    .frame(width: 240, height: 240)
}
