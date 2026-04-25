import SwiftUI

struct SettingsView: View {
    @AppStorage("enableDailyReminder") private var enabled: Bool = true
    @AppStorage("dailyReminderHour") private var hour: Int = 18
    @AppStorage("dailyReminderMinute") private var minute: Int = 0
    @AppStorage("enableSystemNotifications") private var systemNotifications: Bool = false

    var body: some View {
        Form {
            Section("宠物提醒") {
                Toggle("到点让宠物走到屏幕中间等你", isOn: $enabled)
                    .onChange(of: enabled) { _ in notifyChange() }

                HStack {
                    Text("提醒时间")
                    Spacer()
                    Picker("小时", selection: $hour) {
                        ForEach(0..<24) { h in
                            Text(String(format: "%02d", h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80)
                    .onChange(of: hour) { _ in notifyChange() }

                    Text(":")

                    Picker("分钟", selection: $minute) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80)
                    .onChange(of: minute) { _ in notifyChange() }
                }
                .disabled(!enabled)

                Toggle("同时发系统通知", isOn: $systemNotifications)
                    .disabled(!enabled)
                    .onChange(of: systemNotifications) { on in
                        if on { NotificationManager.shared.requestAuthorization() }
                    }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.2.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("数据位置")
                    Spacer()
                    Button("在 Finder 中打开") { openDataFolder() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 360)
        .navigationTitle("设置")
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .dogbodyDailyReminderChanged, object: nil)
    }

    private func openDataFolder() {
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }
        let dir = appSupport.appendingPathComponent("Jot", isDirectory: true)
        NSWorkspace.shared.open(dir)
    }
}
