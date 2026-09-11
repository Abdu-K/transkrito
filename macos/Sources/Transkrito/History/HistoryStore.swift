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
    var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "d MMM HH:mm"
        return f.string(from: date)
    }
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

    func add(_ t: Transcription) {
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
