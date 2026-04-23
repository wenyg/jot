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
        petController.onSubmit = { [weak self] text in
            self?.handleInput(text)
        }
        petController.onOpenRequested = { [weak self] in
            self?.animator.set(.thinking)
        }
        petController.onPanelClosed = { [weak self] in
            self?.animator.set(.idle)
        }
        petController.show()

        NotificationManager.shared.requestAuthorization()

        reminderScheduler.onDailyReminder = { [weak self] in
            self?.fireDailyReminder()
        }
        reminderScheduler.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Input handling

    func handleInput(_ raw: String) {
        let parsed = InputParser.parse(raw)
        guard !parsed.content.isEmpty else { return }
        do {
            try Store.shared.save(parsed)
            animator.set(.happy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.animator.state == .happy {
                    self?.animator.set(.idle)
                }
            }
            // If this is a completion-worthy moment (last todo of the day), celebrate.
            if parsed.kind == .todo, Store.shared.hasNoOpenTodosToday() {
                animator.set(.celebrate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.animator.set(.idle)
                }
            }
        } catch {
            NSLog("Dogbody save error: \(error)")
        }
    }

    private func fireDailyReminder() {
        let openCount = Store.shared.openTodoCountToday()
        if openCount > 0 {
            animator.set(.remind)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.animator.set(.idle)
            }
            NotificationManager.shared.showImmediate(
                title: "写日报时间到",
                body: "今天还有 \(openCount) 个 todo 未完成,要不要记一下?"
            )
        } else {
            NotificationManager.shared.showImmediate(
                title: "今天辛苦啦",
                body: "今天的 todo 都完成了,给自己点个赞 🐾"
            )
        }
    }
}
