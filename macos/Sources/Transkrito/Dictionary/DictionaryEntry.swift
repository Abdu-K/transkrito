import Foundation

/// One dictionary entry. Schema mirrors shared/SPEC.md and the Windows port.
/// `term`: a word/phrase the engine should know (text); canonicalizes casing.
/// `correction`: when you hear `hear`, write `write`.
struct DictionaryEntry: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var type: String = EntryType.term
    var text: String?
    var hear: String?
    var write: String?
    var created: Date = Date()

    var isTerm: Bool { type == EntryType.term }
    /// What the engine hears (term text or correction hear).
    var hearText: String { (isTerm ? text : hear) ?? "" }
    /// What gets written (term text or correction write).
    var writeText: String { (isTerm ? text : write) ?? "" }

    static func term(_ text: String, created: Date = Date()) -> DictionaryEntry {
        DictionaryEntry(type: EntryType.term, text: text, created: created)
    }
    static func correction(hear: String, write: String, created: Date = Date()) -> DictionaryEntry {
        DictionaryEntry(type: EntryType.correction, hear: hear, write: write, created: created)
    }
}

enum EntryType {
    static let term = "term"
    static let correction = "correction"
}

struct DictionaryFile: Codable {
    var version = 1
    var entries: [DictionaryEntry] = []
}
