import Foundation
import GRDB

struct Reminder: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    var id: String
    var todoId: String?
    var fireAt: Double
    var repeatRule: String?

    static let databaseTableName = "reminder"

    enum Columns {
        static let id = Column("id")
        static let todoId = Column("todoId")
        static let fireAt = Column("fireAt")
        static let repeatRule = Column("repeatRule")
    }

    var fireDate: Date { Date(timeIntervalSince1970: fireAt) }
}
