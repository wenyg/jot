import SwiftUI

@main
struct DogbodyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(petController: appDelegate.petController)
        } label: {
            // The label view is the only piece of SwiftUI we have that
            // (a) lives inside a Scene (so `\.openWindow` is wired up) and
            // (b) is permanently mounted (the menu bar item itself is
            // always-on, unlike the dropdown content). We piggyback a
            // notification listener on it so AppKit-side code (e.g. a
            // right-click on the pet) can ask SwiftUI to open the river.
            MenuBarLabel()
        }
        .menuBarExtraStyle(.menu)

        Window("Jot", id: WindowID.river) {
            RiverView()
        }
        .defaultSize(width: 560, height: 680)

        Window("设置", id: WindowID.settings) {
            SettingsView()
        }
        .defaultSize(width: 420, height: 320)
        .windowResizability(.contentSize)
    }
}

enum WindowID {
    static let river = "window.river"
    static let settings = "window.settings"
}

extension Notification.Name {
    /// Posted whenever something on the AppKit side wants the river window
    /// brought up (e.g. user right-clicks the pet).
    static let dogbodyOpenRiver = Notification.Name("io.github.wenyg.jot.openRiver")
}

private struct MenuBarLabel: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(systemName: "pawprint.fill")
            .onReceive(NotificationCenter.default.publisher(for: .dogbodyOpenRiver)) { _ in
                toggleRiver()
            }
    }

    /// Right-click on the pet is a toggle, mirroring left-click toggling the
    /// quick input panel:
    ///   • visible & frontmost   → close
    ///   • visible but obscured  → bring to front (don't punish the user
    ///                              for clicking through another app)
    ///   • not visible / no win  → open + bring to front
    private func toggleRiver() {
        let existing = NSApp.windows.first(where: { $0.identifier?.rawValue == WindowID.river })
            ?? NSApp.windows.first(where: { $0.title == "Jot" })

        if let win = existing, win.isVisible {
            if win.isKeyWindow {
                win.close()
            } else {
                NSApp.activate(ignoringOtherApps: true)
                win.makeKeyAndOrderFront(nil)
            }
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: WindowID.river)
        // LSUIElement apps don't auto-front their windows when openWindow
        // fires from outside a SwiftUI Scene — nudge it on the next tick.
        DispatchQueue.main.async {
            let win = NSApp.windows.first(where: { $0.identifier?.rawValue == WindowID.river })
                ?? NSApp.windows.first(where: { $0.title == "Jot" })
            win?.makeKeyAndOrderFront(nil)
        }
    }
}
