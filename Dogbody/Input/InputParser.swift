import Foundation

struct ParsedInput: Equatable {
    enum Kind: Equatable { case todo, entry }
    var kind: Kind
    var content: String
    var tags: [String]
    var dueAt: Date?
}

/// Heuristic classifier. No prefix grammar — users just type naturally.
/// Signals that push toward TODO (future / action / obligation):
///   - words like "要 / 记得 / 需要 / 应该 / 得 / todo / 待办"
///   - future time words: "明天 / 后天 / 下周 / 周一..周日 / 今晚"
///   - imperative verbs: "买 / 打 / 发 / 约 / 写 / 改"
/// Signals that push toward ENTRY (past / reflection / done):
///   - past-tense markers: "了 / 完成了 / 做了 / 修了 / 开了 / 发了"
///   - reflection words: "感受 / 想到 / 发现 / 学到 / 意识到"
/// When both sides tie, we default to ENTRY (journaling is the safer default —
/// wrongly classifying a TODO as a log is less harmful than the reverse).
enum InputParser {
    static func parse(_ raw: String) -> ParsedInput {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = extractTags(from: &text)
        let dueAt = extractDue(from: &text)

        let kind = classify(text: text, hasDueDate: dueAt != nil)

        return ParsedInput(
            kind: kind,
            content: text.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
            dueAt: dueAt
        )
    }

    /// Public so the input UI can preview the classification live while typing.
    static func classify(text: String, hasDueDate: Bool) -> ParsedInput.Kind {
        let lower = text.lowercased()

        // Strong explicit signal: if the user still wants the old grammar.
        if lower.hasPrefix("- ") || lower.hasPrefix("todo") || lower.hasPrefix("[]") {
            return .todo
        }

        var todoScore = 0
        var entryScore = 0

        if hasDueDate { todoScore += 3 }

        for kw in todoKeywords where text.contains(kw) {
            todoScore += 2
        }
        for kw in futureTimeKeywords where text.contains(kw) {
            todoScore += 2
        }
        for kw in entryKeywords where text.contains(kw) {
            entryScore += 2
        }
        for kw in reflectionKeywords where text.contains(kw) {
            entryScore += 1
        }

        // Past-tense "了" as a single-char signal (but only when not at the
        // very beginning, to avoid misclassifying "了不起 xxx").
        if let idx = text.firstIndex(of: "了"), idx != text.startIndex {
            entryScore += 1
        }

        if todoScore > entryScore { return .todo }
        return .entry  // tie-breaker: entry is the forgiving default
    }

    // MARK: - Keyword dictionaries (intentionally small; iterate as we learn)

    private static let todoKeywords = [
        "要 ", "记得", "需要", "应该", "得 ", "别忘", "todo", "待办",
        "提醒", "约", "找时间"
    ]

    private static let futureTimeKeywords = [
        "明天", "后天", "下周", "下个月", "今晚", "晚上", "早上要",
        "周一", "周二", "周三", "周四", "周五", "周六", "周日", "周天",
        "tomorrow", "next week"
    ]

    private static let entryKeywords = [
        "完成了", "做完了", "搞定了", "修完了", "写完了", "发完了",
        "做了", "修了", "开了", "写了", "发了", "聊了", "读了", "看了", "想了",
        "finished", "did", "done"
    ]

    private static let reflectionKeywords = [
        "感受", "发现", "意识到", "想到", "学到", "体会", "反思", "感觉",
        "收获", "教训"
    ]

    // MARK: - Tag & due-time extraction (kept from v0.1, still useful)

    private static func extractTags(from text: inout String) -> [String] {
        let pattern = #"#([\p{L}\p{N}_-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { m -> String? in
            guard m.numberOfRanges > 1 else { return nil }
            return ns.substring(with: m.range(at: 1))
        }
    }

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

        var base = now
        var rest = lower
        if rest.hasPrefix("今天") || rest.hasPrefix("today") {
            base = now
            rest.removeFirst(rest.hasPrefix("今天") ? 2 : 5)
        } else if rest.hasPrefix("明天") || rest.hasPrefix("tomorrow") {
            base = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            rest.removeFirst(rest.hasPrefix("明天") ? 2 : 8)
        }

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
            var comps = calendar.dateComponents([.year, .month, .day], from: base)
            comps.hour = 9
            comps.minute = 0
            due = calendar.date(from: comps)
        } else {
            due = nil
        }

        if due != nil {
            let fullToken = "@\(token)"
            if let fullRange = text.range(of: fullToken) {
                text.removeSubrange(fullRange)
            }
        }

        return due
    }
}
