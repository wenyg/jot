import Foundation
import GRDB

struct Todo: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    var id: String
    var content: String
    /// Unix timestamp (seconds).
    var createdAt: Double
    var dueAt: Double?
    var doneAt: Double?
    /// Comma-separated tag list for simplicity.
    var tags: String?
    var priority: Int

    static let databaseTableName = "todo"

    enum Columns {
        static let id = Column("id")
        static let content = Column("content")
        static let createdAt = Column("createdAt")
        static let dueAt = Column("dueAt")
        static let doneAt = Column("doneAt")
        static let tags = Column("tags")
        static let priority = Column("priority")
    }

    var isDone: Bool { doneAt != nil }
    var createdDate: Date { Date(timeIntervalSince1970: createdAt) }
    var doneDate: Date? { doneAt.map(Date.init(timeIntervalSince1970:)) }
    var dueDate: Date? { dueAt.map(Date.init(timeIntervalSince1970:)) }
    var tagList: [String] {
        (tags ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
