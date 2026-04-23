import Foundation

/// Fires the "time to write your EOD log" reminder at a user-configured hour
/// every day, and re-registers any stored per-todo reminders when the app
/// launches.
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    var onDailyReminder: (() -> Void)?

    private var dailyTimer: Timer?

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleSettingsChange),
            name: .dogbodyDailyReminderChanged, object: nil
        )
    }

    func start() {
        scheduleDaily()
        scheduleStoredReminders()
    }

    @objc private func handleSettingsChange() {
        scheduleDaily()
    }

    private func scheduleDaily() {
        dailyTimer?.invalidate()
        let defaults = UserDefaults.standard
        let enabled = (defaults.object(forKey: "enableDailyReminder") as? Bool) ?? true
        guard enabled else { return }
        let hour = (defaults.object(forKey: "dailyReminderHour") as? Int) ?? 18
        let minute = (defaults.object(forKey: "dailyReminderMinute") as? Int) ?? 0

        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = hour
        comps.minute = minute
        var next = cal.date(from: comps) ?? now
        if next <= now {
            next = cal.date(byAdding: .day, value: 1, to: next) ?? next
        }
        let interval = next.timeIntervalSinceNow

        dailyTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.onDailyReminder?()
            // Chain the next day.
            self?.scheduleDaily()
        }
    }

    private func scheduleStoredReminders() {
        let reminders = Store.shared.futureReminders()
        for r in reminders {
            let body: String
            if let todoId = r.todoId, let todo = Store.shared.todo(id: todoId) {
                body = todo.content
            } else {
                body = "你有一个待办"
            }
            NotificationManager.shared.schedule(
                id: r.id,
                title: "Dogbody 提醒",
                body: body,
                fireAt: r.fireDate
            )
        }
    }
}

extension Notification.Name {
    static let dogbodyDailyReminderChanged = Notification.Name("dogbodyDailyReminderChanged")
}
