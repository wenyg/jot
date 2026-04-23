import SwiftUI

@main
struct DogbodyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
        } label: {
            Image(systemName: "pawprint.fill")
        }
        .menuBarExtraStyle(.menu)

        Window("Todo", id: WindowID.todo) {
            TodoListView()
        }
        .defaultSize(width: 520, height: 600)

        Window("时间线", id: WindowID.timeline) {
            TimelineView()
        }
        .defaultSize(width: 640, height: 720)

        Window("周报", id: WindowID.weekly) {
            WeeklyReportView()
        }
        .defaultSize(width: 680, height: 760)

        Window("设置", id: WindowID.settings) {
            SettingsView()
        }
        .defaultSize(width: 420, height: 320)
        .windowResizability(.contentSize)
    }
}

enum WindowID {
    static let todo = "window.todo"
    static let timeline = "window.timeline"
    static let weekly = "window.weekly"
    static let settings = "window.settings"
}
