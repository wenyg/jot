import SwiftUI

struct TodoListView: View {
    @ObservedObject private var store = Store.shared
    @State private var showDone = true

    private var todos: [Todo] {
        let all = store.allTodos()
        return showDone ? all : all.filter { !$0.isDone }
    }

    private var openCount: Int { store.allTodos().filter { !$0.isDone }.count }
    private var doneCount: Int { store.allTodos().filter { $0.isDone }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if todos.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(todos) { todo in
                        TodoRow(todo: todo)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    try? store.delete(todo)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 420, minHeight: 400)
        .navigationTitle("Todo")
    }

    private var header: some View {
        HStack(spacing: 12) {
            Label("\(openCount) 未完成", systemImage: "circle")
                .foregroundStyle(.orange)
            Label("\(doneCount) 已完成", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Spacer()
            Toggle("显示已完成", isOn: $showDone)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("还没有 todo")
                .font(.headline)
            Text("点宠物,输入 `- 买咖啡豆` 试试")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TodoRow: View {
    let todo: Todo
    @ObservedObject private var store = Store.shared

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                try? store.toggleDone(todo)
            } label: {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(todo.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.content)
                    .strikethrough(todo.isDone, color: .secondary)
                    .foregroundStyle(todo.isDone ? .secondary : .primary)

                HStack(spacing: 8) {
                    Text(relativeCreated)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if let due = todo.dueDate {
                        Label(dueString(due), systemImage: "bell")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                    ForEach(todo.tagList, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var relativeCreated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: todo.createdDate, relativeTo: Date())
    }

    private func dueString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: date)
    }
}
