import SwiftUI
import AppKit

/// Menu bar dropdown. The pet on the desktop is the *only* place to record;
/// everything else lives here as a small, calm list of verbs.
struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var store = Store.shared

    var body: some View {
        Text(statusLine)

        Divider()

        Button("打开时间流") { openWindow(id: WindowID.river) }
        Button(copyButtonLabel) { copyThisWeek() }

        Divider()

        Button("显示桌面伙伴") {
            AppDelegate.shared?.petController.toggle()
        }
        Button("设置…") { openWindow(id: WindowID.settings) }

        Divider()

        Button("退出 Jot") { NSApp.terminate(nil) }
    }

    // MARK: - Status

    /// "今天 · 3 笔 · 还剩 2 件" — a soft pulse that tells you what your day
    /// looks like before you do anything else.
    private var statusLine: String {
        // Re-read on each open so revisions to `store.revision` keep this fresh.
        _ = store.revision
        let activity = Store.shared.todayActivityCount()
        let open = Store.shared.openTodoCount()

        switch (activity, open) {
        case (0, 0):
            return "今天还没动笔"
        case (let a, 0):
            return "今天 · \(a) 笔"
        case (0, let o):
            return "今天还没动笔 · 还剩 \(o) 件"
        case (let a, let o):
            return "今天 · \(a) 笔 · 还剩 \(o) 件"
        }
    }

    // MARK: - Copy this week

    /// On Mondays, RiverView's `.week` automatically refers to the *previous*
    /// Mon–Sun (since Monday morning's "本周" is empty and what users actually
    /// want is the just-finished week's report). Mirror that label here.
    private var copyButtonLabel: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 2 ? "复制上周" : "复制本周"
    }

    private func copyThisWeek() {
        let summary = WeeklySummary.build(scope: .week)
        guard !summary.markdown.isEmpty else {
            // Nothing to copy — let the pet think for a beat as soft feedback.
            AppDelegate.shared?.animator.set(.thinking)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                AppDelegate.shared?.animator.set(.idle)
            }
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary.markdown, forType: .string)

        // Pet wags its tail as a wordless "done".
        AppDelegate.shared?.animator.set(.happy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            AppDelegate.shared?.animator.set(.idle)
        }
    }
}
