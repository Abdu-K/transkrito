import Foundation
import Observation

struct CorrectionRecord: Codable, Identifiable, Equatable {
    var hear: String
    var write: String
    var matched: String
    var count: Int
    var id: String { hear + "\u{1F}" + matched }

    init(_ e: CorrectionEvent) { hear = e.hear; write = e.write; matched = e.matched; count = e.count }

    var display: String { count > 1 ? "\(matched) \u{2192} \(write)  \u{00D7}\(count)" : "\(matched) \u{2192} \(write)" }
}

struct Transcription: Codable, Identifiable, Equatable {
    enum CodingKeys: String, CodingKey { case id, date, raw, text, durationSec, engine, model, corrections }

    /// True briefly after the row lands so the list can hold a tint until noticed. Not persisted.
    var isNew = false
    var id: String = UUID().uuidString
    var date: Date = Date()
    var raw: String = ""
    var text: String = ""
    var durationSec: Double = 0
    var engine: String = "apple-speech"
    var model: String = ""
    var corrections: [CorrectionRecord] = []

    var hasCorrections: Bool { !corrections.isEmpty }
    var correctionCount: Int { corrections.reduce(0) { $0 + $1.count } }
    var correctionLabel: String { correctionCount == 1 ? "1 correction" : "\(correctionCount) corrections" }
    var timeLabel: String { Self.time.string(from: date) }
    var wordCount: Int { text.split(whereSeparator: \.isWhitespace).count }
    var dayKey: String { Self.dayKeyFormatter.string(from: date) }
    var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = cal.component(.year, from: date) == cal.component(.year, from: Date()) ? "d MMMM" : "d MMMM yyyy"
        return f.string(from: date)
    }
    private static let time: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()
    private static let dayKeyFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f }()
}

struct HistoryFile: Codable {
    var version = 1
    var items: [Transcription] = []
}

/// history.json: newest first, capped.
@MainActor @Observable
final class HistoryStore {
    static let cap = 500
    private(set) var items: [Transcription] = []
    let fileURL: URL

    init(fileURL: URL = AppPaths.history) {
        self.fileURL = fileURL
        // Unreadable history is not fatal: start empty; the file is rewritten on the next save.
        items = ((try? JsonFile.read(HistoryFile.self, from: fileURL)) ?? nil)?.items ?? []
    }

    struct DayGroup: Identifiable { let label: String; let items: [Transcription]; var id: String { label } }

    func grouped(_ query: String) -> [DayGroup] {
        var order: [String] = []
        var buckets: [String: [Transcription]] = [:]
        for t in search(query) {
            if buckets[t.dayKey] == nil { order.append(t.dayKey) }
            buckets[t.dayKey, default: []].append(t)
        }
        return order.map { DayGroup(label: buckets[$0]![0].dayLabel, items: buckets[$0]!) }
    }

    /// Today's count, today's words, and the run of consecutive days (ending today) with at least one dictation.
    func stats() -> (today: Int, wordsToday: Int, streak: Int) {
        let cal = Calendar.current
        let todays = items.filter { cal.isDateInToday($0.date) }
        let days = Set(items.map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var d = cal.startOfDay(for: Date())
        while days.contains(d) { streak += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return (todays.count, todays.reduce(0) { $0 + $1.wordCount }, streak)
    }

    func markSeen(_ id: String) {
        if let i = items.firstIndex(where: { $0.id == id }) { items[i].isNew = false }
    }

    func add(_ t: Transcription) {
        var t = t
        t.isNew = true
        items.insert(t, at: 0)
        if items.count > Self.cap { items.removeLast(items.count - Self.cap) }
        save()
    }

    func remove(_ t: Transcription) { items.removeAll { $0.id == t.id }; save() }

    func search(_ query: String) -> [Transcription] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return items }
        return items.filter { $0.text.localizedCaseInsensitiveContains(q) || $0.raw.localizedCaseInsensitiveContains(q) }
    }

    private func save() { try? JsonFile.write(HistoryFile(items: items), to: fileURL) }
}
