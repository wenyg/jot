import Foundation

struct ParsedInput: Equatable {
    enum Kind: Equatable { case todo, entry }
    var kind: Kind
    var content: String
    var tags: [String]
    var dueAt: Date?
}

enum InputParser {
    /// Grammar (kept intentionally small for MVP):
    ///   `- <text>`   or `[] <text>`  -> todo
    ///   `/ <text>`   or `+ <text>`   -> entry (log)
    ///   no prefix                    -> entry
    ///   Any `#tag` tokens are extracted into tags.
    ///   A trailing `@<time>` is extracted verbatim into dueAt when parsable.
    static func parse(_ raw: String) -> ParsedInput {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var kind: ParsedInput.Kind = .entry

        if let stripped = stripPrefix(&text, prefixes: ["- ", "-", "[] ", "[]", "[ ] "]) {
            kind = .todo
            text = stripped
        } else if let stripped = stripPrefix(&text, prefixes: ["/ ", "/", "+ ", "+"]) {
            kind = .entry
            text = stripped
        }

        let tags = extractTags(from: &text)
        let dueAt = extractDue(from: &text)

        return ParsedInput(
            kind: kind,
            content: text.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
            dueAt: dueAt
        )
    }

    @discardableResult
    private static func stripPrefix(_ text: inout String, prefixes: [String]) -> String? {
        for p in prefixes {
            if text.hasPrefix(p) {
                return String(text.dropFirst(p.count))
            }
        }
        return nil
    }

    private static func extractTags(from text: inout String) -> [String] {
        let pattern = #"#([\p{L}\p{N}_-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        let tags = matches.compactMap { m -> String? in
            guard m.numberOfRanges > 1 else { return nil }
            return ns.substring(with: m.range(at: 1))
        }
        return tags
    }

    /// Extremely lightweight time parsing: `@18:30`, `@明天`, `@今天`,
    /// `@tomorrow`, `@HH:MM`. Falls back to nil when unrecognized so UX stays
    /// predictable. Extend as needed.
    private static func extractDue(from text: inout String) -> Date? {
        guard let atRange = text.range(of: "@") else { return nil }
        let tokenStart = atRange.upperBound
        let remainder = text[tokenStart...]
        let token = remainder
            .split(whereSeparator: { $0.isWhitespace })
            .first
            .map(String.init) ?? ""
        guard !token.isEmpty else { return nil }

        let lower = token.lowercased()
        let calendar = Calendar.current
        let now = Date()

        // Day anchor + optional HH:MM.
        var base = now
        var rest = lower
        if rest.hasPrefix("今天") || rest.hasPrefix("today") {
            base = now
            rest.removeFirst(rest.hasPrefix("今天") ? 2 : 5)
        } else if rest.hasPrefix("明天") || rest.hasPrefix("tomorrow") {
            base = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            rest.removeFirst(rest.hasPrefix("明天") ? 2 : 8)
        }

        // HH or HH:MM.
        let timeRegex = try? NSRegularExpression(pattern: #"^(\d{1,2})(?::(\d{1,2}))?"#)
        var hour: Int?
        var minute = 0
        if let r = timeRegex,
           let m = r.firstMatch(in: rest, range: NSRange(location: 0, length: rest.count)) {
            let ns = rest as NSString
            let hRange = m.range(at: 1)
            if hRange.location != NSNotFound {
                hour = Int(ns.substring(with: hRange))
            }
            if m.numberOfRanges > 2, m.range(at: 2).location != NSNotFound {
                minute = Int(ns.substring(with: m.range(at: 2))) ?? 0
            }
        }

        let due: Date?
        if let h = hour {
            var comps = calendar.dateComponents([.year, .month, .day], from: base)
            comps.hour = h
            comps.minute = minute
            due = calendar.date(from: comps)
        } else if rest.isEmpty {
            // Day anchor without time: schedule at 9am.
            var comps = calendar.dateComponents([.year, .month, .day], from: base)
            comps.hour = 9
            comps.minute = 0
            due = calendar.date(from: comps)
        } else {
            due = nil
        }

        if due != nil {
            // Remove the @token from content for cleanliness.
            let fullToken = "@\(token)"
            if let fullRange = text.range(of: fullToken) {
                text.removeSubrange(fullRange)
            }
        }

        return due
    }
}
