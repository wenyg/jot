import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate?

    let petController = PetWindowController()
    let animator = PetAnimator()
    private let reminderScheduler = ReminderScheduler.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Warm up the database so first write is snappy.
        _ = Store.shared

        petController.animator = animator
        petController.onSubmit = { [weak self] text, override in
            self?.handleInput(text, override: override)
        }
        petController.onOpenRequested = { [weak self] in
            self?.animator.set(.thinking)
        }
        petController.onPanelClosed = { [weak self] in
            self?.animator.set(.idle)
        }
        petController.show()

        // Notifications are opt-in (off by default) — the reminder experience
        // is "pet walks to center and waits for you". We only request auth if
        // the user has explicitly turned notifications on in Settings.
        if UserDefaults.standard.bool(forKey: "enableSystemNotifications") {
            NotificationManager.shared.requestAuthorization()
        }

        reminderScheduler.onDailyReminder = { [weak self] in
            self?.fireDailyReminder()
        }
        reminderScheduler.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Input handling

    func handleInput(_ raw: String, override: ParsedInput.Kind? = nil) {
        var parsed = InputParser.parse(raw)
        if let override { parsed.kind = override }
        guard !parsed.content.isEmpty else { return }
        do {
            try Store.shared.save(parsed)
            animator.set(.happy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.animator.state == .happy {
                    self?.animator.set(.idle)
                }
            }
            // Recording during a reminder dismisses it: the pet goes home.
            petController.walkHome()

            // If this is a completion-worthy moment (last todo of the day), celebrate.
            if parsed.kind == .todo, Store.shared.hasNoOpenTodosToday() {
                animator.set(.celebrate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.animator.set(.idle)
                }
            }
        } catch {
            NSLog("Jot save error: \(error)")
        }
    }

    /// Daily reminder: the pet walks to the center and waits. No system
    /// notification unless the user has explicitly opted in.
    private func fireDailyReminder() {
        petController.walkToCenter()

        if UserDefaults.standard.bool(forKey: "enableSystemNotifications") {
            let openCount = Store.shared.openTodoCountToday()
            let body = openCount > 0
                ? "今天还有 \(openCount) 件事没划掉, 要不要记一笔?"
                : "今天辛苦啦, 记点什么吧."
            NotificationManager.shared.showImmediate(title: "Jot", body: body)
        }
    }
}
