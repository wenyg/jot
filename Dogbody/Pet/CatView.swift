import SwiftUI
import AppKit

/// The composed Yuumi-style cat. Layer order (back → front):
///
///   1. CatStardust      — twinkling motes drifting around the whole area
///   2. CatFloorShadow   — soft elliptical shadow under the floating body
///   3. CatBodyAura      — a pink/violet glow hugging the silhouette
///   4. CatTail          — tail stroke + tip sparkle (rendered behind body
///                         so it emerges from the right hip)
///   5. Body stack       — silhouette, blush, eyes, mouth, forehead gem
///   6. CatAccessories   — state-specific decorations above the head
///
/// A gentle float offset lifts the body off the floor so she reads as
/// "hovering" rather than "sitting".
struct CatView: View {
    @ObservedObject var animator: PetAnimator
    let catScreenOrigin: CGPoint

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { context in
            let t = context.date.timeIntervalSince1970
            let breathe = CGFloat(sin(t * breatheSpeed) * breatheAmount)
            let bob     = CGFloat(sin(t * bobSpeed) * bobAmount)
            // Gentle continuous float — makes her look like she's hovering.
            let floatLift = CGFloat(sin(t * 1.1) * 3.0) - floatBase

            GeometryReader { geo in
                // The silhouette is authored 1 : 1.18. We reserve room on
                // top for gem + accessories and a little floor for the shadow.
                let bodyWidth: CGFloat = min(geo.size.width * 0.66, (geo.size.height - 44) / 1.18)
                let bodySize = CGSize(width: bodyWidth, height: bodyWidth * 1.18)
                let bodyOrigin = CGPoint(
                    x: (geo.size.width  - bodySize.width) / 2,
                    y: geo.size.height  - bodySize.height - 22
                )

                ZStack {
                    // --- Background stardust (fills whole frame) ---
                    CatStardust(animator: animator)
                        .frame(width: geo.size.width, height: geo.size.height)

                    // --- Floor shadow (anchored to container bottom) ---
                    CatFloorShadow(animator: animator)
                        .frame(width: geo.size.width, height: geo.size.height)

                    // --- Body aura (tracks body position, not float) ---
                    CatBodyAura(animator: animator)
                        .frame(width: bodySize.width, height: bodySize.height)
                        .offset(x: bodyOrigin.x, y: bodyOrigin.y + floatLift)

                    // --- Tail (behind body, tracks float) ---
                    CatTail(animator: animator)
                        .frame(width: bodySize.width, height: bodySize.height)
                        .offset(x: bodyOrigin.x, y: bodyOrigin.y + floatLift)

                    // --- Body stack ---
                    ZStack {
                        CatBody()
                        CatBlush(animator: animator)
                        CatEyes(
                            animator: animator,
                            size: bodySize,
                            catScreenOrigin: CGPoint(
                                x: catScreenOrigin.x + bodyOrigin.x,
                                y: catScreenOrigin.y + bodyOrigin.y
                            )
                        )
                        // Forehead gem, positioned between the ears.
                        CatMagicGem(animator: animator, size: bodySize.width * 0.14)
                            .position(x: bodySize.width * 0.50, y: bodySize.height * 0.16)
                        CatMouth(animator: animator)
                        // Pink nose dot.
                        Circle()
                            .fill(CatTheme.noseColor)
                            .frame(width: bodySize.width * 0.035, height: bodySize.width * 0.035)
                            .position(x: bodySize.width * 0.50, y: bodySize.height * 0.52)
                    }
                    .frame(width: bodySize.width, height: bodySize.height)
                    .scaleEffect(
                        x: 1.0 + stateSquashX,
                        y: 1.0 + breathe + stateSquashY,
                        anchor: .bottom
                    )
                    .rotationEffect(.degrees(stateTilt), anchor: .bottom)
                    .offset(
                        x: bodyOrigin.x + stateOffsetX,
                        y: bodyOrigin.y + bob + stateOffsetY + floatLift
                    )
                    .animation(CatTheme.stateSpring, value: animator.state)
                    .animation(CatTheme.bouncySpring, value: animator.isBeingDragged)

                    // --- Accessories (...,z,sparkles,red-dot) above head ---
                    CatAccessories(animator: animator)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
    }

    // MARK: - Breathing / bob / float

    /// Base vertical lift applied to the body so it sits "in the air". Sleep
    /// zeros this out because a sleeping cat is lying down, not floating.
    private var floatBase: CGFloat {
        switch animator.state {
        case .sleep: return 0
        default:     return 8
        }
    }

    private var breatheSpeed: Double {
        switch animator.state {
        case .sleep:     return 0.8
        case .happy:     return 3.2
        case .celebrate: return 4.4
        default:         return 1.3   // slower, more "meditative" Yuumi
        }
    }
    private var breatheAmount: Double {
        switch animator.state {
        case .sleep: return 0.008
        default:     return 0.018
        }
    }
    private var bobSpeed: Double {
        switch animator.state {
        case .happy:     return 3.6
        case .celebrate: return 5.0
        default:         return 0.0
        }
    }
    private var bobAmount: Double {
        switch animator.state {
        case .happy:     return 1.0
        case .celebrate: return 3.0
        default:         return 0.0
        }
    }

    // MARK: - State-driven deformations (mostly unchanged)

    private var stateSquashX: CGFloat {
        if animator.isBeingDragged { return -0.05 }
        switch animator.state {
        case .sleep: return 0.12
        default: return 0
        }
    }
    private var stateSquashY: CGFloat {
        if animator.isBeingDragged { return 0.08 }
        switch animator.state {
        case .sleep: return -0.42
        default: return 0
        }
    }
    private var stateTilt: Double {
        if animator.isBeingDragged { return -6 }
        switch animator.state {
        case .sleep: return -90
        case .thinking: return 3
        default: return 0
        }
    }
    private var stateOffsetX: CGFloat {
        switch animator.state {
        case .sleep: return -6
        default: return 0
        }
    }
    private var stateOffsetY: CGFloat {
        switch animator.state {
        case .sleep: return 14
        default: return 0
        }
    }
}

#Preview("Idle - Yuumi") {
    ZStack {
        LinearGradient(colors: [.black.opacity(0.9), .purple.opacity(0.4)], startPoint: .top, endPoint: .bottom)
        CatView(animator: {
            let a = PetAnimator(); a.set(.idle); return a
        }(), catScreenOrigin: .zero)
        .frame(width: 180, height: 190)
    }
    .frame(width: 360, height: 360)
}
