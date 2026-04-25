import Foundation
import GRDB

/// A tiny singleton wrapper over GRDB providing all app-level queries.
/// Writes are synchronous and serialized by `DatabaseQueue`, which is
/// sufficient for the write volume of a personal journaling app.
final class Store: ObservableObject {
    static let shared = Store()

    let dbQueue: DatabaseQueue

    /// Bumped after every write so views can auto-refresh.
    @Published private(set) var revision: Int = 0

    private init() {
        let fm = FileManager.default
        let appSupport = try! fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("Jot", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbURL = dir.appendingPathComponent("jot.sqlite")

        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        self.dbQueue = try! DatabaseQueue(path: dbURL.path, configuration: config)

        var migrator = DatabaseMigrator()
        Migrations.register(in: &migrator)
        try! migrator.migrate(dbQueue)
    }

    // MARK: - Writes

    /// Save a parsed input as either a Todo or an Entry.
    @discardableResult
    func save(_ parsed: ParsedInput) throws -> String {
        let now = Date().timeIntervalSince1970
        let id = UUID().uuidString
        let tagsString = parsed.tags.isEmpty ? nil : parsed.tags.joined(separator: ",")

        try dbQueue.write { db in
            switch parsed.kind {
            case .todo:
                var todo = Todo(
                    id: id,
                    content: parsed.content,
                    createdAt: now,
                    dueAt: parsed.dueAt?.timeIntervalSince1970,
                    doneAt: nil,
                    tags: tagsString,
                    priority: 0
                )
                try todo.insert(db)
                if let due = parsed.dueAt {
                    var rem = Reminder(
                        id: UUID().uuidString,
                        todoId: todo.id,
                        fireAt: due.timeIntervalSince1970,
                        repeatRule: nil
                    )
                    try rem.insert(db)
                    NotificationManager.shared.schedule(
                        id: rem.id,
                        title: "Jot 提醒",
                        body: todo.content,
                        fireAt: due
                    )
                }
            case .entry:
                var entry = Entry(
                    id: id,
                    content: parsed.content,
                    createdAt: now,
                    tags: tagsString
                )
                try entry.insert(db)
            }
        }
        bumpRevision()
        return id
    }

    func toggleDone(_ todo: Todo) throws {
        var copy = todo
        copy.doneAt = todo.doneAt == nil ? Date().timeIntervalSince1970 : nil
        try dbQueue.write { db in
            try copy.update(db)
        }
        bumpRevision()
    }

    func delete(_ todo: Todo) throws {
        _ = try dbQueue.write { db in
            try Todo.deleteOne(db, id: todo.id)
        }
        bumpRevision()
    }

    func delete(_ entry: Entry) throws {
        _ = try dbQueue.write { db in
            try Entry.deleteOne(db, id: entry.id)
        }
        bumpRevision()
    }

    /// Reclassify a mis-parsed todo as a log entry.
    func convertTodoToEntry(_ todo: Todo) throws {
        try dbQueue.write { db in
            var entry = Entry(
                id: UUID().uuidString,
                content: todo.content,
                createdAt: todo.createdAt,
                tags: todo.tags
            )
            try entry.insert(db)
            _ = try Todo.deleteOne(db, id: todo.id)
        }
        bumpRevision()
    }

    /// Reclassify a log entry as a todo (useful when the heuristic mis-classifies).
    func convertEntryToTodo(_ entry: Entry) throws {
        try dbQueue.write { db in
            var todo = Todo(
                id: UUID().uuidString,
                content: entry.content,
                createdAt: entry.createdAt,
                dueAt: nil,
                doneAt: nil,
                tags: entry.tags,
                priority: 0
            )
            try todo.insert(db)
            _ = try Entry.deleteOne(db, id: entry.id)
        }
        bumpRevision()
    }

    // MARK: - Reads

    func allTodos() -> [Todo] {
        (try? dbQueue.read { db in
            try Todo
                .order(Todo.Columns.doneAt.asc, Todo.Columns.createdAt.desc)
                .fetchAll(db)
        }) ?? []
    }

    func openTodos() -> [Todo] {
        (try? dbQueue.read { db in
            try Todo
                .filter(Todo.Columns.doneAt == nil)
                .order(Todo.Columns.createdAt.desc)
                .fetchAll(db)
        }) ?? []
    }

    func entries(since: Date) -> [Entry] {
        (try? dbQueue.read { db in
            try Entry
                .filter(Entry.Columns.createdAt >= since.timeIntervalSince1970)
                .order(Entry.Columns.createdAt.desc)
                .fetchAll(db)
        }) ?? []
    }

    func entries(since: Date, until: Date) -> [Entry] {
        (try? dbQueue.read { db in
            try Entry
                .filter(Entry.Columns.createdAt >= since.timeIntervalSince1970)
                .filter(Entry.Columns.createdAt < until.timeIntervalSince1970)
                .order(Entry.Columns.createdAt.desc)
                .fetchAll(db)
        }) ?? []
    }

    func todos(since: Date) -> [Todo] {
        (try? dbQueue.read { db in
            try Todo
                .filter(Todo.Columns.createdAt >= since.timeIntervalSince1970)
                .order(Todo.Columns.createdAt.desc)
                .fetchAll(db)
        }) ?? []
    }

    func todos(since: Date, until: Date) -> [Todo] {
        (try? dbQueue.read { db in
            try Todo
                .filter(Todo.Columns.createdAt >= since.timeIntervalSince1970)
                .filter(Todo.Columns.createdAt < until.timeIntervalSince1970)
                .order(Todo.Columns.createdAt.desc)
                .fetchAll(db)
        }) ?? []
    }

    func futureReminders() -> [Reminder] {
        let now = Date().timeIntervalSince1970
        return (try? dbQueue.read { db in
            try Reminder
                .filter(Reminder.Columns.fireAt > now)
                .order(Reminder.Columns.fireAt.asc)
                .fetchAll(db)
        }) ?? []
    }

    func todo(id: String) -> Todo? {
        try? dbQueue.read { db in
            try Todo.fetchOne(db, key: id)
        }
    }

    // MARK: - Aggregations

    func openTodoCountToday() -> Int {
        let start = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return (try? dbQueue.read { db in
            try Todo
                .filter(Todo.Columns.doneAt == nil)
                .filter(Todo.Columns.createdAt >= start)
                .fetchCount(db)
        }) ?? 0
    }

    func hasNoOpenTodosToday() -> Bool {
        openTodoCountToday() == 0
    }

    private func bumpRevision() {
        DispatchQueue.main.async { [weak self] in
            self?.revision &+= 1
        }
    }
}
