import Foundation
import Combine

final class PetAnimator: ObservableObject {
    @Published private(set) var state: PetState = .idle
    @Published private(set) var frame: Int = 0

    private var timer: Timer?
    private var lastInteraction: Date = Date()

    /// Frames per second per state (higher = snappier animation).
    private let stateFPS: [PetState: Double] = [
        .idle: 4,
        .happy: 8,
        .thinking: 4,
        .sleep: 2,
        .celebrate: 10,
        .remind: 8
    ]

    init() {
        scheduleTick()
        scheduleIdleWatchdog()
    }

    deinit { timer?.invalidate() }

    func set(_ newState: PetState) {
        guard state != newState else { return }
        state = newState
        frame = 0
        lastInteraction = Date()
        scheduleTick()
    }

    func touch() {
        lastInteraction = Date()
        if state == .sleep { set(.idle) }
    }

    private func scheduleTick() {
        timer?.invalidate()
        let fps = stateFPS[state] ?? 4
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.frame = (self.frame + 1) % Self.frameCount(for: self.state)
        }
    }

    private func scheduleIdleWatchdog() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.state == .idle,
               Date().timeIntervalSince(self.lastInteraction) > 5 * 60 {
                self.set(.sleep)
            }
        }
    }

    static func frameCount(for state: PetState) -> Int {
        switch state {
        case .idle, .thinking: return 4
        case .happy, .remind: return 6
        case .sleep: return 2
        case .celebrate: return 8
        }
    }
}
