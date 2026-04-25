import SwiftUI

@main
struct DogbodyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(petController: appDelegate.petController)
        } label: {
            Image(systemName: "pawprint.fill")
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
