import SwiftUI
import AppKit

/// The single unified view. Replaces the old Todo / Timeline / Weekly windows.
/// Structure:
///   - Open TODOs pinned at the top (collapsible)
///   - Everything else (done TODOs + entries) grouped by day in one stream
///   - One segmented control to pick the time scope
///   - One action: export as poster image
struct RiverView: View {
    enum Scope: String, CaseIterable, Identifiable {
        case today, week, month
        var id: String { rawValue }
        var label: String {
            switch self {
            case .today: return "今天"
            case .week: return "本周"
            case .month: return "本月"
            }
        }
    }

    @ObservedObject private var store = Store.shared
    @State private var scope: Scope = .today
    @State private var openCollapsed = false
    @State private var showingPoster = false

    private var startDate: Date {
        let cal = Calendar.current
        let now = Date()
        switch scope {
        case .today:
            return cal.startOfDay(for: now)
        case .week:
            var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            comps.weekday = 2  // Monday
            return cal.date(from: comps) ?? cal.startOfDay(for: now)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: now)
            return cal.date(from: comps) ?? cal.startOfDay(for: now)
        }
    }

    private var openTodos: [Todo] {
        store.allTodos().filter { !$0.isDone }
    }

    private var groupedStream: [(day: Date, items: [StreamItem])] {
        let todos = store.todos(since: startDate).filter { $0.isDone }
            .map { StreamItem.todo($0) }
        let entries = store.entries(since: startDate).map { StreamItem.entry($0) }
        let cal = Calendar.current
        let all = todos + entries
        let grouped = Dictionary(grouping: all) { cal.startOfDay(for: $0.date) }
        return grouped
            .map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !openTodos.isEmpty {
                        openTodoSection
                        Divider().padding(.vertical, 8)
                    }

                    if groupedStream.isEmpty && openTodos.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedStream, id: \.day) { group in
                            daySection(day: group.day, items: group.items)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 520, minHeight: 620)
        .navigationTitle("Jot")
        .sheet(isPresented: $showingPoster) {
            WeeklyPosterSheet(scope: scope, onClose: { showingPoster = false })
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Picker("", selection: $scope) {
                ForEach(Scope.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
            .labelsHidden()

            Spacer()

            Button {
                showingPoster = true
            } label: {
                Label("导出为海报", systemImage: "photo")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Open todos

    private var openTodoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation { openCollapsed.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: openCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("未完成 · \(openTodos.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if !openCollapsed {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(openTodos) { todo in
                        RiverRow(item: .todo(todo))
                    }
                }
                .padding(.leading, 8)
            }
        }
    }

    // MARK: - Day section

    private func daySection(day: Date, items: [StreamItem]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dayHeader(day))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 10)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(items) { item in
                    RiverRow(item: item)
                }
            }
            .padding(.leading, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("这段时间还没记录什么")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("点桌面上的小狗, 或按 ⌘⇧P, 记一笔")
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    private func dayHeader(_ date: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        if cal.isDateInToday(date) {
            f.dateFormat = "'今天' · M月d日 EEEE"
        } else if cal.isDateInYesterday(date) {
            f.dateFormat = "'昨天' · M月d日 EEEE"
        } else {
            f.dateFormat = "M月d日 EEEE"
        }
        return f.string(from: date)
    }
}

// MARK: - StreamItem

enum StreamItem: Identifiable {
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

// MARK: - Row

struct RiverRow: View {
    let item: StreamItem
    @ObservedObject private var store = Store.shared
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            marker
                .frame(width: 16, alignment: .center)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(isCompletedTodo, color: .secondary)
                    .foregroundStyle(isCompletedTodo ? .secondary : .primary)

                if isHovered {
                    Text(timeLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isHovered ? Color.primary.opacity(0.04) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            if case .todo(let t) = item { try? store.toggleDone(t) }
        }
        .contextMenu { contextMenu }
    }

    private var isCompletedTodo: Bool {
        if case .todo(let t) = item { return t.isDone }
        return false
    }

    @ViewBuilder
    private var marker: some View {
        switch item {
        case .todo(let t) where !t.isDone:
            Circle()
                .stroke(Color.orange, lineWidth: 1.5)
                .frame(width: 10, height: 10)
        case .todo:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
        case .entry:
            Rectangle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 2, height: 12)
        }
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: item.date)
    }

    @ViewBuilder
    private var contextMenu: some View {
        switch item {
        case .todo(let t):
            Button(t.isDone ? "标记为未完成" : "标记为已完成") {
                try? store.toggleDone(t)
            }
            Button("转为日志") {
                try? store.convertTodoToEntry(t)
            }
            Divider()
            Button("删除", role: .destructive) {
                try? store.delete(t)
            }
        case .entry(let e):
            Button("转为 TODO") {
                try? store.convertEntryToTodo(e)
            }
            Divider()
            Button("删除", role: .destructive) {
                try? store.delete(e)
            }
        }
    }
}
