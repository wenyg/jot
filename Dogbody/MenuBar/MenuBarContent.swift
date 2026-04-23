import SwiftUI

struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开 Jot") { openWindow(id: WindowID.river) }
            .keyboardShortcut("j", modifiers: [.command, .shift])

        Button("显示 / 隐藏宠物") {
            AppDelegate.shared?.petController.toggle()
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])

        Divider()

        Button("设置...") { openWindow(id: WindowID.settings) }
            .keyboardShortcut(",", modifiers: .command)

        Button("退出 Jot") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
