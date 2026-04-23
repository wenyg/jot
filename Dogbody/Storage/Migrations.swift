import Foundation
import GRDB

enum Migrations {
    static func register(in migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1_initial_schema") { db in
            try db.create(table: "todo") { t in
                t.column("id", .text).primaryKey()
                t.column("content", .text).notNull()
                t.column("createdAt", .double).notNull().indexed()
                t.column("dueAt", .double)
                t.column("doneAt", .double)
                t.column("tags", .text)
                t.column("priority", .integer).notNull().defaults(to: 0)
            }
            try db.create(table: "entry") { t in
                t.column("id", .text).primaryKey()
                t.column("content", .text).notNull()
                t.column("createdAt", .double).notNull().indexed()
                t.column("tags", .text)
            }
            try db.create(table: "reminder") { t in
                t.column("id", .text).primaryKey()
                t.column("todoId", .text).references("todo", onDelete: .cascade)
                t.column("fireAt", .double).notNull().indexed()
                t.column("repeatRule", .text)
            }
        }
    }
}
