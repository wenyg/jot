import Foundation
import GRDB

struct Entry: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    var id: String
    var content: String
    var createdAt: Double
    var tags: String?

    static let databaseTableName = "entry"

    enum Columns {
        static let id = Column("id")
        static let content = Column("content")
        static let createdAt = Column("createdAt")
        static let tags = Column("tags")
    }

    var createdDate: Date { Date(timeIntervalSince1970: createdAt) }
    var tagList: [String] {
        (tags ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
