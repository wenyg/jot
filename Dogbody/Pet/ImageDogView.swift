import SwiftUI
import AppKit

/// Sprite-based puppy renderer backed by the generated PNG states in
/// `DogAssets`. This is the default pet when custom AI artwork is present.
struct ImageDogView: View {
    @ObservedObject var animator: PetAnimator

    @State private var tapPulse: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { context in
            let time = context.date.timeIntervalSince1970
            let sprite = DogSpriteCatalog.sprite(for: animator)
            let motion = DogSpriteMotion(animator: animator, time: time, tapPulse: tapPulse)

            GeometryReader { geo in
                ZStack {
                    DogSpriteGlow(animator: animator, time: time)
                    DogSpriteShadow(animator: animator, time: time)

                    if let image = DogSpriteCatalog.image(named: sprite.assetName) {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                width: geo.size.width * sprite.frameScale,
                                height: geo.size.height * sprite.frameScale
                            )
                            .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
                            .rotationEffect(.degrees(motion.rotation), anchor: .bottom)
                            .offset(x: motion.offsetX, y: motion.offsetY + sprite.verticalOffset)
                            .id(sprite.assetName)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            .animation(DogSpriteTheme.stateSpring, value: sprite.assetName)
                            .animation(DogSpriteTheme.playfulSpring, value: tapPulse)
                            .animation(DogSpriteTheme.playfulSpring, value: animator.isBeingDragged)
                            .animation(DogSpriteTheme.playfulSpring, value: animator.isHovering)
                    } else {
                        Color.clear
                    }

                    DogSpriteOverlays(animator: animator)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onChange(of: animator.touchTick) { _ in
            performTapPulse()
        }
    }

    private func performTapPulse() {
        withAnimation(.spring(response: 0.16, dampingFraction: 0.42)) {
            tapPulse = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
                tapPulse = 0
            }
        }
    }
}

private enum DogSpriteTheme {
    static let glow = Color(red: 1.0, green: 0.72, blue: 0.35)
    static let remind = Color(red: 1.0, green: 0.28, blue: 0.22)
    static let thought = Color(red: 0.72, green: 0.80, blue: 0.95)
    static let stateSpring: Animation = .spring(response: 0.38, dampingFraction: 0.74)
    static let playfulSpring: Animation = .spring(response: 0.26, dampingFraction: 0.52)
}

private struct DogSprite {
    let assetName: String
    let frameScale: CGFloat
    let verticalOffset: CGFloat
}

private enum DogSpriteCatalog {
    static func sprite(for animator: PetAnimator) -> DogSprite {
        if animator.isBeingDragged {
            return DogSprite(assetName: "dog_dragging", frameScale: 1.18, verticalOffset: 0)
        }

        switch animator.state {
        case .happy:
            return DogSprite(assetName: "dog_happy", frameScale: 1.16, verticalOffset: -4)
        case .thinking:
            return DogSprite(assetName: "dog_thinking", frameScale: 1.13, verticalOffset: -2)
        case .sleep:
            return DogSprite(assetName: "dog_sleep", frameScale: 1.22, verticalOffset: 10)
        case .celebrate:
            return DogSprite(assetName: "dog_celebrate", frameScale: 1.20, verticalOffset: -6)
        case .remind:
            return DogSprite(assetName: "dog_remind", frameScale: 1.15, verticalOffset: -4)
        case .idle:
            if animator.isHovering {
                return DogSprite(assetName: "dog_hover", frameScale: 1.18, verticalOffset: -3)
            }
            return DogSprite(assetName: "dog_idle", frameScale: 1.14, verticalOffset: -2)
        }
    }

    static func image(named assetName: String) -> NSImage? {
        if let image = NSImage(named: assetName) {
            return image
        }

        let bundle = Bundle.main
        let urls = [
            bundle.url(forResource: assetName, withExtension: "png"),
            bundle.url(forResource: assetName, withExtension: "png", subdirectory: "DogAssets"),
            bundle.url(forResource: assetName, withExtension: "png", subdirectory: "Pet/DogAssets")
        ]

        for url in urls.compactMap({ $0 }) {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }
}

private struct DogSpriteMotion {
    let scaleX: CGFloat
    let scaleY: CGFloat
    let rotation: Double
    let offsetX: CGFloat
    let offsetY: CGFloat

    init(animator: PetAnimator, time: TimeInterval, tapPulse: CGFloat) {
        let idleBob = CGFloat(sin(time * 1.8)) * 1.5
        let dragWiggle = animator.isBeingDragged ? CGFloat(sin(time * 12.0)) * 5.0 : 0
        let happyHop = (animator.state == .happy || animator.state == .celebrate)
            ? -CGFloat(max(0, sin(time * 5.2))) * 5.5
            : 0
        let remindBounce = animator.state == .remind
            ? -CGFloat(max(0, sin(time * 4.0))) * 3.5
            : 0

        if animator.state == .sleep {
            scaleX = 1.0 + tapPulse * 0.04
            scaleY = 1.0 + tapPulse * 0.03
            rotation = Double(dragWiggle) * 0.35
            offsetX = dragWiggle * 0.35
            offsetY = CGFloat(sin(time * 0.9)) * 0.7
            return
        }

        scaleX = 1.0 + tapPulse * 0.10 + (animator.isBeingDragged ? -0.05 : 0)
        scaleY = 1.0 + tapPulse * 0.12 + (animator.isBeingDragged ? 0.08 : 0)
        rotation = (animator.isHovering ? -2.5 : 0) + Double(dragWiggle) * 0.55
        offsetX = dragWiggle
        offsetY = idleBob + happyHop + remindBounce - tapPulse * 4
    }
}

private struct DogSpriteGlow: View {
    @ObservedObject var animator: PetAnimator
    let time: TimeInterval

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<5) { i in
                    let phase = (time + Double(i) * 0.7).truncatingRemainder(dividingBy: 4.6) / 4.6
                    let angle = phase * 2 * .pi + Double(i)
                    let x = geo.size.width * (0.50 + CGFloat(cos(angle)) * 0.28)
                    let y = geo.size.height * (0.46 + CGFloat(sin(angle * 1.15)) * 0.26)

                    DogSpriteSpark()
                        .fill(DogSpriteTheme.glow)
                        .frame(width: 4 + CGFloat(i % 2) * 2, height: 4 + CGFloat(i % 2) * 2)
                        .shadow(color: DogSpriteTheme.glow.opacity(0.75), radius: 4)
                        .position(x: x, y: y)
                        .opacity(glowIntensity * sin(phase * .pi))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var glowIntensity: Double {
        switch animator.state {
        case .celebrate: return 0.95
        case .happy, .remind: return 0.62
        case .sleep: return 0.12
        default: return animator.isHovering ? 0.50 : 0.28
        }
    }
}

private struct DogSpriteShadow: View {
    @ObservedObject var animator: PetAnimator
    let time: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let breathe = 1.0 + 0.08 * sin(time * 1.7 + .pi)
            let sleepScale: CGFloat = animator.state == .sleep ? 1.16 : 1.0

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.30),
                            Color.black.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geo.size.width * 0.34
                    )
                )
                .frame(
                    width: geo.size.width * 0.58 * CGFloat(breathe) * sleepScale,
                    height: geo.size.width * 0.14 * CGFloat(breathe) * sleepScale
                )
                .position(x: geo.size.width * 0.50, y: geo.size.height - 13)
        }
        .allowsHitTesting(false)
    }
}

private struct DogSpriteOverlays: View {
    @ObservedObject var animator: PetAnimator

    var body: some View {
        ZStack {
            DogSpriteSleepZs()
                .opacity(animator.state == .sleep ? 1 : 0)
                .animation(DogSpriteTheme.stateSpring, value: animator.state)

            DogSpriteReminderPing()
                .opacity(animator.state == .remind ? 1 : 0)
                .animation(DogSpriteTheme.stateSpring, value: animator.state)
        }
        .allowsHitTesting(false)
    }
}

private struct DogSpriteSleepZs: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSince1970
            GeometryReader { geo in
                ForEach(0..<3) { i in
                    let phase = (time + Double(i) * 0.9).truncatingRemainder(dividingBy: 3.2) / 3.2
                    Text("z")
                        .font(.system(size: 17 - CGFloat(i) * 3, weight: .bold, design: .rounded))
                        .foregroundColor(DogSpriteTheme.thought)
                        .position(
                            x: geo.size.width * 0.72 + CGFloat(sin(phase * .pi * 2)) * 5,
                            y: geo.size.height * 0.24 - CGFloat(phase) * 30
                        )
                        .opacity(sin(phase * .pi) * 0.9)
                }
            }
        }
    }
}

private struct DogSpriteReminderPing: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let time = context.date.timeIntervalSince1970
            let pulse = 1.0 + sin(time * 5.5) * 0.18

            GeometryReader { geo in
                ZStack {
                    Circle()
                        .stroke(DogSpriteTheme.remind.opacity(0.45), lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .scaleEffect(CGFloat(pulse))
                    Circle()
                        .fill(DogSpriteTheme.remind)
                        .frame(width: 8, height: 8)
                        .shadow(color: DogSpriteTheme.remind.opacity(0.70), radius: 6)
                }
                .position(x: geo.size.width * 0.76, y: geo.size.height * 0.13)
            }
        }
    }
}

private struct DogSpriteSpark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42

        for i in 0..<8 {
            let angle = Double(i) / 8.0 * 2.0 * .pi - .pi / 2
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }

        path.closeSubpath()
        return path
    }
}

#Preview("Image Puppy") {
    ZStack {
        LinearGradient(colors: [.white, .orange.opacity(0.18)], startPoint: .top, endPoint: .bottom)
        ImageDogView(animator: {
            let animator = PetAnimator()
            animator.set(.idle)
            return animator
        }())
        .frame(width: 180, height: 190)
    }
    .frame(width: 360, height: 360)
}
