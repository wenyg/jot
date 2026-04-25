import SwiftUI
import AppKit

/// Menu bar dropdown. The pet on the desktop is the *only* place to record;
/// this menu is the calm cabinet where the rest of the app lives.
struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var petController: PetWindowController

    var body: some View {
        Button("回顾今日") { openRiver() }

        Button(petController.isShown ? "隐藏 Jot" : "显示 Jot") {
            petController.toggle()
        }

        Button("设置…") { openSettings() }

        Divider()

        Button("退出 Jot") { NSApp.terminate(nil) }
    }

    /// LSUIElement apps don't auto-front their windows when `openWindow` is
    /// invoked from a menu — the window is created behind whatever the user
    /// was looking at. Activate the app, then nudge the window to the front
    /// once SwiftUI has had a chance to actually create it.
    private func openRiver() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: WindowID.river)
        bringToFront(sceneId: WindowID.river, title: "Jot")
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: WindowID.settings)
        bringToFront(sceneId: WindowID.settings, title: "设置")
    }

    /// Bring the SwiftUI scene window to the front. Done on the next runloop
    /// tick because `openWindow` may schedule the actual NSWindow creation
    /// asynchronously. Match by SwiftUI scene id first (current SwiftUI sets
    /// it as the window identifier) and fall back to window title for safety
    /// across SwiftUI versions.
    private func bringToFront(sceneId: String, title: String) {
        DispatchQueue.main.async {
            let win = NSApp.windows.first(where: { $0.identifier?.rawValue == sceneId })
                ?? NSApp.windows.first(where: { $0.title == title })
            win?.makeKeyAndOrderFront(nil)
        }
    }
}
