import Foundation
import AppKit
import Combine

/// Drives the Moji cat. Unlike the previous frame-index-based animator, this
/// one exposes two independent signals:
///
/// 1. `state` — a high-level mood (idle, happy, sleep, …). State changes
///    trigger spring animations in each sub-view.
/// 2. `clock` — a continuously-incrementing time value (seconds since birth)
///    that sub-views read via a `TimelineView` for smooth, phase-aligned
///    cyclic motion (breathing, tail wag, blushing pulse, …).
///
/// Discrete events (blinks, sparkle bursts) are dispatched separately via
/// `blinkTick` / `sparkleTick` so sub-views can react to them.
final class PetAnimator: ObservableObject {

    // MARK: - Mood

    @Published private(set) var state: PetState = .idle

    /// Published so views can adjust transient response (e.g. pupils darting
    /// around more while the pet is being dragged).
    @Published var isBeingDragged: Bool = false
    @Published var isHovering: Bool = false

    /// Cursor position in *screen* coordinates. Set by the containing window
    /// so `CatEyes` can compute where to point the pupils. nil when cursor
    /// is far away / tracking is disabled.
    @Published var cursorScreenPoint: CGPoint? = nil

    // MARK: - Continuous clock

    /// Seconds since the animator was created. Drives all periodic motion.
    /// Sub-views read this inside a `TimelineView(.animation)` so they don't
    /// need to own timers.
    var clock: TimeInterval {
        Date().timeIntervalSince(birth)
    }

    // MARK: - Discrete events

    /// Incremented every time we fire a blink. Views can observe it to run
    /// a one-shot animation.
    @Published private(set) var blinkTick: Int = 0
    /// Incremented every time we fire a sparkle burst during celebration.
    @Published private(set) var sparkleTick: Int = 0

    // MARK: - Internals

    private let birth: Date = Date()
    private var lastInteraction: Date = Date()
    private var blinkTimer: Timer?
    private var idleWatchdogTimer: Timer?
    private var sparkleTimer: Timer?

    init() {
        scheduleBlink()
        scheduleIdleWatchdog()
    }

    deinit {
        blinkTimer?.invalidate()
        idleWatchdogTimer?.invalidate()
        sparkleTimer?.invalidate()
    }

    // MARK: - Public API (unchanged surface for PetWindowController)

    func set(_ newState: PetState) {
        guard state != newState else { return }
        state = newState
        lastInteraction = Date()

        // Celebrate spawns its own periodic sparkle bursts; other states don't.
        sparkleTimer?.invalidate()
        if newState == .celebrate {
            sparkleTick &+= 1
            sparkleTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
                self?.sparkleTick &+= 1
            }
        }
    }

    func touch() {
        lastInteraction = Date()
        if state == .sleep { set(.idle) }
    }

    // MARK: - Blinking

    private func scheduleBlink() {
        let jitter = Double.random(in: -CatTheme.blinkIntervalJitter ... CatTheme.blinkIntervalJitter)
        let delay = max(1.5, CatTheme.blinkIntervalMean + jitter)
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            // Don't blink while sleeping (eyes are already closed) or while
            // the user is actively dragging — stay "alert".
            if self.state != .sleep && !self.isBeingDragged {
                self.blinkTick &+= 1
                // Occasional double-blink for life.
                if Bool.random() && Double.random(in: 0...1) < 0.18 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                        self?.blinkTick &+= 1
                    }
                }
            }
            self.scheduleBlink()
        }
    }

    // MARK: - Idle → Sleep watchdog

    private func scheduleIdleWatchdog() {
        idleWatchdogTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.state == .idle,
               Date().timeIntervalSince(self.lastInteraction) > 5 * 60 {
                self.set(.sleep)
            }
        }
    }
}
