import SwiftUI

struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("显示 / 隐藏宠物") {
            AppDelegate.shared?.petController.toggle()
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])

        Divider()

        Button("Todo 列表") { openWindow(id: WindowID.todo) }
        Button("时间线") { openWindow(id: WindowID.timeline) }
        Button("周报") { openWindow(id: WindowID.weekly) }

        Divider()

        Button("设置...") { openWindow(id: WindowID.settings) }
            .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("退出 Dogbody") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
