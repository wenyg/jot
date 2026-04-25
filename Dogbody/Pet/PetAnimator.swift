import Foundation
import Combine

/// Drives the desktop puppy's high-level mood and direct interaction pulses.
final class PetAnimator: ObservableObject {

    // MARK: - Mood

    @Published private(set) var state: PetState = .idle

    /// Published so views can adjust transient response (e.g. pupils darting
    /// around more while the pet is being dragged).
    @Published var isBeingDragged: Bool = false
    @Published var isHovering: Bool = false

    // MARK: - Discrete events

    /// Incremented on direct pet interaction so renderers can play a one-shot
    /// bounce without changing the app-level mood.
    @Published private(set) var touchTick: Int = 0

    // MARK: - Internals

    private var lastInteraction: Date = Date()
    private var idleWatchdogTimer: Timer?

    init() {
        scheduleIdleWatchdog()
    }

    deinit {
        idleWatchdogTimer?.invalidate()
    }

    // MARK: - Public API (unchanged surface for PetWindowController)

    func set(_ newState: PetState) {
        guard state != newState else { return }
        state = newState
        lastInteraction = Date()
    }

    func touch() {
        touchTick &+= 1
        lastInteraction = Date()
        if state == .sleep { set(.idle) }
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
