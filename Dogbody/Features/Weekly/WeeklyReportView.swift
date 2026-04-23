import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct WeeklyReportView: View {
    @ObservedObject private var store = Store.shared
    @State private var daysBack: Int = 7
    @State private var showCopied = false

    private var markdown: String {
        WeeklyReportBuilder.build(daysBack: daysBack)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("范围", selection: $daysBack) {
                    Text("近 7 天").tag(7)
                    Text("本周").tag(-1)
                    Text("近 30 天").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(markdown, forType: .string)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                } label: {
                    Label(showCopied ? "已复制" : "复制 Markdown", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    exportToFile()
                } label: {
                    Label("导出 .md", systemImage: "square.and.arrow.up")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                Text(markdown)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .frame(minWidth: 540, minHeight: 500)
        .navigationTitle("周报")
    }

    private func exportToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "dogbody-weekly-\(f.string(from: Date())).md"
        if panel.runModal() == .OK, let url = panel.url {
            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

enum WeeklyReportBuilder {
    /// A unified row used for per-day grouping in the weekly report.
    struct Row {
        let content: String
        let date: Date
        let kind: Kind
        enum Kind { case entry, completedTodo }
    }

    static func build(daysBack: Int) -> String {
        let now = Date()
        let cal = Calendar.current

        let start: Date
        if daysBack == -1 {
            var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            comps.weekday = 2 // Monday
            start = cal.date(from: comps) ?? now
        } else {
            start = cal.date(byAdding: .day, value: -daysBack, to: cal.startOfDay(for: now)) ?? now
        }

        let todos = Store.shared.todos(since: start)
        let entries = Store.shared.entries(since: start)
        let doneTodos = todos.filter { $0.isDone }
        let openTodos = todos.filter { !$0.isDone }

        let titleFmt = DateFormatter()
        titleFmt.locale = Locale(identifier: "zh_CN")
        titleFmt.dateFormat = "M月d日"
        let dayFmt = DateFormatter()
        dayFmt.locale = Locale(identifier: "zh_CN")
        dayFmt.dateFormat = "M月d日 EEE"

        var md = "# 工作周报 (\(titleFmt.string(from: start)) - \(titleFmt.string(from: now)))\n\n"
        md += "## 概览\n\n"
        md += "- 完成 todo: **\(doneTodos.count)** 项\n"
        md += "- 未完成 todo: \(openTodos.count) 项\n"
        md += "- 日志条目: \(entries.count) 条\n\n"

        let entryRows = entries.map { Row(content: $0.content, date: $0.createdDate, kind: .entry) }
        let doneRows = doneTodos.map {
            Row(content: $0.content, date: $0.doneDate ?? $0.createdDate, kind: .completedTodo)
        }
        let grouped = Dictionary(grouping: entryRows + doneRows) {
            cal.startOfDay(for: $0.date)
        }
        let sortedDays = grouped.keys.sorted(by: >)

        md += "## 按日明细\n\n"
        if sortedDays.isEmpty {
            md += "_这段时间没有记录_\n\n"
        } else {
            for day in sortedDays {
                md += "### \(dayFmt.string(from: day))\n\n"
                let items = (grouped[day] ?? []).sorted { $0.date < $1.date }
                for item in items {
                    let prefix = item.kind == .completedTodo ? "- ✅ " : "- "
                    md += "\(prefix)\(item.content)\n"
                }
                md += "\n"
            }
        }

        if !openTodos.isEmpty {
            md += "## 未完成的 todo\n\n"
            for t in openTodos {
                md += "- [ ] \(t.content)\n"
            }
            md += "\n"
        }

        md += "---\n_由 Dogbody 自动生成_\n"
        return md
    }
}
