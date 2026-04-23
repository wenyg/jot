import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A shareable visual summary of the past week (or custom range).
/// Rendered via SwiftUI's `ImageRenderer` so "what you see is what you share".
struct WeeklyPosterSheet: View {
    let scope: RiverView.Scope
    let onClose: () -> Void

    @State private var posterImage: NSImage?

    private var summary: WeeklySummary { WeeklySummary.build(scope: scope) }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("导出海报")
                    .font(.headline)
                Spacer()
                Button("关闭") { onClose() }
                    .keyboardShortcut(.escape, modifiers: [])
            }

            // Preview (scaled down from real export size)
            PosterCanvas(summary: summary)
                .frame(width: 320, height: 568)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

            HStack(spacing: 12) {
                Button {
                    copyImage()
                } label: {
                    Label("复制到剪贴板", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    saveImage()
                } label: {
                    Label("保存为 PNG", systemImage: "square.and.arrow.down")
                }

                Button {
                    copyMarkdown()
                } label: {
                    Label("复制 Markdown", systemImage: "text.alignleft")
                }
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    // MARK: - Actions

    private func renderedImage(scale: CGFloat = 2) -> NSImage? {
        let view = PosterCanvas(summary: summary)
            .frame(width: 540, height: 960)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.nsImage
    }

    private func copyImage() {
        guard let img = renderedImage() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
    }

    private func saveImage() {
        guard let img = renderedImage(), let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:])
        else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "jot-\(scope.rawValue)-\(df.string(from: Date())).png"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    private func copyMarkdown() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary.markdown, forType: .string)
    }
}

// MARK: - Poster canvas

/// The actual visual. Kept simple and typographic — the design is the
/// typography. This view is used both for the preview and the exported PNG.
private struct PosterCanvas: View {
    let summary: WeeklySummary

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.10),
                         Color(red: 0.13, green: 0.14, blue: 0.17)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("JOT")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .kerning(4)
                        .foregroundStyle(Color.white.opacity(0.5))
                    Spacer()
                    Text(summary.rangeLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 6) {
                    Text("完成了")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(summary.completedCount)")
                            .font(.system(size: 96, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text("件事")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    if summary.entryCount > 0 {
                        Text("记下了 \(summary.entryCount) 条日志")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 28)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(summary.dayHighlights, id: \.day) { highlight in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(highlight.dayLabel)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .kerning(1.5)
                                .foregroundStyle(Color.white.opacity(0.4))
                            ForEach(highlight.items, id: \.self) { line in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("·")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                    Text(line)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.92))
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                HStack {
                    Spacer()
                    Text("jotted this week.")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Summary builder

struct WeeklySummary {
    struct DayHighlight {
        let day: Date
        let dayLabel: String
        let items: [String]
    }

    let rangeLabel: String
    let completedCount: Int
    let entryCount: Int
    let dayHighlights: [DayHighlight]
    let markdown: String

    static func build(scope: RiverView.Scope) -> WeeklySummary {
        let (start, _) = range(for: scope)
        let cal = Calendar.current
        let now = Date()

        let todos = Store.shared.todos(since: start)
        let entries = Store.shared.entries(since: start)
        let completed = todos.filter { $0.isDone }

        let titleFmt = DateFormatter()
        titleFmt.locale = Locale(identifier: "zh_CN")
        titleFmt.dateFormat = "M月d日"
        let rangeLabel = "\(titleFmt.string(from: start)) — \(titleFmt.string(from: now))"

        // Group by day, take up to 3 items per day as highlights.
        let dayFmt = DateFormatter()
        dayFmt.locale = Locale(identifier: "zh_CN")
        dayFmt.dateFormat = "M.d EEE"

        struct Row {
            let content: String
            let date: Date
            let isTodo: Bool
        }

        let rows = entries.map { Row(content: $0.content, date: $0.createdDate, isTodo: false) }
            + completed.map { Row(content: $0.content, date: $0.doneDate ?? $0.createdDate, isTodo: true) }

        let grouped = Dictionary(grouping: rows) { cal.startOfDay(for: $0.date) }
        let sortedDays = grouped.keys.sorted(by: >)

        let highlights = sortedDays.prefix(5).map { day -> DayHighlight in
            let items = (grouped[day] ?? [])
                .sorted { $0.date < $1.date }
                .prefix(3)
                .map { $0.content }
            return DayHighlight(
                day: day,
                dayLabel: dayFmt.string(from: day).uppercased(),
                items: Array(items)
            )
        }

        let md = buildMarkdown(
            range: rangeLabel,
            completed: completed,
            entries: entries,
            scope: scope
        )

        return WeeklySummary(
            rangeLabel: rangeLabel,
            completedCount: completed.count,
            entryCount: entries.count,
            dayHighlights: Array(highlights),
            markdown: md
        )
    }

    private static func range(for scope: RiverView.Scope) -> (Date, Date) {
        let cal = Calendar.current
        let now = Date()
        let start: Date
        switch scope {
        case .today:
            start = cal.startOfDay(for: now)
        case .week:
            var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            comps.weekday = 2
            start = cal.date(from: comps) ?? cal.startOfDay(for: now)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: now)
            start = cal.date(from: comps) ?? cal.startOfDay(for: now)
        }
        return (start, now)
    }

    private static func buildMarkdown(range: String, completed: [Todo], entries: [Entry], scope: RiverView.Scope) -> String {
        let scopeLabel: String
        switch scope {
        case .today: scopeLabel = "今天"
        case .week: scopeLabel = "本周"
        case .month: scopeLabel = "本月"
        }
        var md = "# \(scopeLabel)小结 (\(range))\n\n"
        md += "- 完成 **\(completed.count)** 件事\n"
        md += "- 日志 \(entries.count) 条\n\n"

        if !completed.isEmpty {
            md += "## 完成的\n\n"
            for t in completed.sorted(by: { $0.createdAt > $1.createdAt }) {
                md += "- ✅ \(t.content)\n"
            }
            md += "\n"
        }

        if !entries.isEmpty {
            md += "## 日志\n\n"
            for e in entries.sorted(by: { $0.createdAt > $1.createdAt }) {
                md += "- \(e.content)\n"
            }
            md += "\n"
        }

        md += "---\n_jotted this week._\n"
        return md
    }
}
