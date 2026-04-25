import SwiftUI

/// Design tokens for the Moji cat. All magic numbers for the pet's visual
/// identity live here — colors, gradients, shadows, sizing, animation timings.
///
/// Changing the cat's "mood" (e.g. switching to a white cat for light mode)
/// should only require tweaking this file.
enum CatTheme {

    // MARK: - Canvas

    /// Size of the cat's drawable area (logical points). The PetView frame
    /// adds extra padding for accessories that float above the body.
    static let bodySize: CGFloat = 96

    // MARK: - Palette — Yuumi-inspired magical kitty

    /// Dark-mode body: deep violet-indigo with a warm rose undertone at the
    /// belly. Not true black — needs to read as "magical creature" on a
    /// translucent panel.
    static let bodyGradientDark = LinearGradient(
        colors: [
            Color(red: 0.89, green: 0.83, blue: 0.95),  // #E3D4F1 top (lavender-white, like fur catching moonlight)
            Color(red: 0.72, green: 0.64, blue: 0.88),  // #B8A3E1 mid
            Color(red: 0.55, green: 0.47, blue: 0.80)   // #8C78CC belly
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Light-mode body: classic Yuumi — soft cream-white fur with a hint of
    /// rose at the belly.
    static let bodyGradientLight = LinearGradient(
        colors: [
            Color(red: 0.995, green: 0.98, blue: 0.99),  // #FDFAFC top
            Color(red: 0.98,  green: 0.92, blue: 0.95),  // #FAEAF2 mid (rose kiss)
            Color(red: 0.93,  green: 0.83, blue: 0.89)   // #EDD4E2 belly
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Top-half glossy highlight — stronger than before to give a soft "magical fur" shine.
    static let bodyHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.35),
            Color.white.opacity(0.0)
        ],
        startPoint: .top,
        endPoint: .center
    )

    /// Inner-ear pink — warm and saturated; Yuumi's defining pink-inside-ear look.
    static let earInnerDark = Color(red: 0.98, green: 0.55, blue: 0.72).opacity(0.75)
    static let earInnerLight = Color(red: 0.98, green: 0.60, blue: 0.74).opacity(0.80)

    // MARK: - Eyes (magical)

    /// Eye whites — soft warm off-white that won't clash with the pink pupil.
    static let eyeWhite = Color(red: 0.99, green: 0.97, blue: 0.98)

    /// Pupil — pink-to-violet radial gradient (Yuumi's iconic eye color).
    /// The gradient is authored center-dark-pink → edge-violet so each eye
    /// reads as a glowing orb.
    static let pupilGradient = RadialGradient(
        colors: [
            Color(red: 1.00, green: 0.55, blue: 0.85),  // hot pink center
            Color(red: 0.85, green: 0.40, blue: 0.90),  // magenta
            Color(red: 0.45, green: 0.28, blue: 0.75)   // deep violet edge
        ],
        center: .center,
        startRadius: 0,
        endRadius: 12
    )

    /// Specular highlight — bright pure white.
    static let eyeSpec = Color.white

    /// A soft magenta glow painted *behind* the eye to make it look luminous.
    static let eyeGlow = Color(red: 1.0, green: 0.55, blue: 0.85)

    // MARK: - Features (mouth, nose)

    /// Pink cat nose — Yuumi has a bright pink nose.
    static let noseColor = Color(red: 1.0, green: 0.50, blue: 0.62)
    /// Mouth stroke color — dark rose so it still reads against cream fur.
    static let featureStrokeDark = Color(red: 0.25, green: 0.15, blue: 0.32).opacity(0.80)
    static let featureStrokeLight = Color(red: 0.50, green: 0.25, blue: 0.42)

    /// Blush — stays on by default for the Yuumi look (she's always a bit flushed).
    static let blush = Color(red: 1.0, green: 0.55, blue: 0.72)

    // MARK: - Magic gem (forehead)

    /// The jewel's main color — the classic Yuumi blue-violet sapphire.
    static let gemCore = Color(red: 0.45, green: 0.55, blue: 0.95)       // bright periwinkle
    static let gemDeep = Color(red: 0.25, green: 0.20, blue: 0.60)       // indigo base
    static let gemBright = Color(red: 0.85, green: 0.92, blue: 1.0)      // near-white spec
    /// Radiant glow around the gem.
    static let gemAura = Color(red: 0.70, green: 0.75, blue: 1.0)

    // MARK: - Aura / stardust

    /// The faint overall glow around the cat's body.
    static let bodyAuraColor = Color(red: 0.85, green: 0.65, blue: 1.0)

    /// Stardust palette — rotated through randomly.
    static let stardustColors: [Color] = [
        Color(red: 1.0,  green: 0.75, blue: 0.92),   // bubblegum pink
        Color(red: 0.75, green: 0.80, blue: 1.0),    // ice blue
        Color(red: 0.95, green: 0.80, blue: 1.0),    // lavender
        Color(red: 1.0,  green: 0.90, blue: 0.55),   // starlight gold
        Color(red: 0.80, green: 1.0,  blue: 0.95)    // aqua mint
    ]

    // MARK: - Accessories (state-specific, legacy)

    static let dotReminder = Color(red: 1.0, green: 0.40, blue: 0.55)
    static let zSleep = Color(red: 0.70, green: 0.72, blue: 0.98).opacity(0.92)
    static let sparkGold = Color(red: 1.0, green: 0.85, blue: 0.45)
    static let sparkPink = Color(red: 1.0, green: 0.58, blue: 0.85)
    static let sparkCyan = Color(red: 0.65, green: 0.88, blue: 1.0)
    static let thinkDot = Color(red: 0.82, green: 0.78, blue: 0.95)

    // MARK: - Shadows (stacked for depth)

    struct ShadowSpec {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    /// Applied bottom-up (closest to surface first).
    static let bodyShadows: [ShadowSpec] = [
        .init(color: .black.opacity(0.30), radius: 1,  x: 0, y: 1),
        .init(color: .black.opacity(0.20), radius: 10, x: 0, y: 6),
        .init(color: .black.opacity(0.10), radius: 22, x: 0, y: 10)
    ]

    // MARK: - Animation timings

    /// Soft spring used for most state transitions.
    static let stateSpring: Animation = .spring(response: 0.45, dampingFraction: 0.72)
    /// A livelier spring for celebrate / happy onsets.
    static let bouncySpring: Animation = .spring(response: 0.35, dampingFraction: 0.55)
    /// Slow sinusoidal drivers (breathing, tail) don't use SwiftUI animations —
    /// they read continuous time from `PetAnimator.clock`.

    /// Mean time between involuntary blinks (seconds).
    static let blinkIntervalMean: Double = 5.0
    /// Jitter range around the mean, seconds.
    static let blinkIntervalJitter: Double = 3.0
    /// A single blink: close → pause → open.
    static let blinkCloseDuration: Double = 0.08
    static let blinkHoldDuration: Double = 0.04
    static let blinkOpenDuration: Double = 0.10

    /// Max offset the pupil can travel when tracking the cursor.
    static let pupilTrackingRadius: CGFloat = 1.8
}

/// Color-scheme-aware token resolver. Lets views ask for "the right body
/// gradient" without every view doing the @Environment dance.
///
/// `catFeatureStroke` lives in `CatFeatures.swift` because it's backed by an
/// EnvironmentKey there; the two below are derived purely from `colorScheme`
/// and don't need a storage slot.
extension EnvironmentValues {
    var catBodyGradient: LinearGradient {
        colorScheme == .dark ? CatTheme.bodyGradientDark : CatTheme.bodyGradientLight
    }
    var catEarInner: Color {
        colorScheme == .dark ? CatTheme.earInnerDark : CatTheme.earInnerLight
    }
}
