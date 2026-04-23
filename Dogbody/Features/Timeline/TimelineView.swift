import SwiftUI

enum TimelineItem: Identifiable {
    case todo(Todo)
    case entry(Entry)

    var id: String {
        switch self {
        case .todo(let t): return "todo-\(t.id)"
        case .entry(let e): return "entry-\(e.id)"
        }
    }

    var date: Date {
        switch self {
        case .todo(let t): return t.doneDate ?? t.createdDate
        case .entry(let e): return e.createdDate
        }
    }

    var content: String {
        switch self {
        case .todo(let t): return t.content
        case .entry(let e): return e.content
        }
    }
}

struct TimelineView: View {
    @ObservedObject private var store = Store.shared
    @State private var daysBack: Int = 14

    private var grouped: [(day: Date, items: [TimelineItem])] {
        let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let todos = store.todos(since: start).map(TimelineItem.todo)
        let entries = store.entries(since: start).map(TimelineItem.entry)
        let all = (todos + entries).sorted { $0.date > $1.date }
        let cal = Calendar.current
        let grouped = Dictionary(grouping: all) { cal.startOfDay(for: $0.date) }
        return grouped
            .map { (day: $0.key, items: $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("范围", selection: $daysBack) {
                    Text("近 7 天").tag(7)
                    Text("近 14 天").tag(14)
                    Text("近 30 天").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            if grouped.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("这段时间还没有记录")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(grouped, id: \.day) { group in
                        Section(header: Text(dayHeader(group.day)).font(.headline)) {
                            ForEach(group.items) { item in
                                TimelineRow(item: item)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 540, minHeight: 500)
        .navigationTitle("时间线")
    }

    private func dayHeader(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            f.dateFormat = "'今天' (M月d日 EEE)"
        } else if cal.isDateInYesterday(date) {
            f.dateFormat = "'昨天' (M月d日 EEE)"
        } else {
            f.dateFormat = "M月d日 EEE"
        }
        return f.string(from: date)
    }
}

struct TimelineRow: View {
    let item: TimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            iconView
                .frame(width: 20, alignment: .center)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.content)
                    .fixedSize(horizontal: false, vertical: true)
                Text(timeString)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var iconView: some View {
        switch item {
        case .todo(let t):
            Image(systemName: t.isDone ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(t.isDone ? .green : .orange)
        case .entry:
            Image(systemName: "square.and.pencil")
                .foregroundStyle(.blue)
        }
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        switch item {
        case .todo(let t):
            if t.isDone { return "完成于 \(f.string(from: t.doneDate ?? t.createdDate))" }
            return "创建于 \(f.string(from: t.createdDate))"
        case .entry(let e):
            return f.string(from: e.createdDate)
        }
    }
}
