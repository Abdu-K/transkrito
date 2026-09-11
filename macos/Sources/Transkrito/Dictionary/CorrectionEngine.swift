import Foundation

/// One rule that fired: hear → write, first matched substring, how many times.
struct CorrectionEvent: Equatable, Codable {
    var hear: String
    var write: String
    var matched: String
    var count: Int
}

/// Post-transcription correction pass. Pure, deterministic, identical to the Windows port.
/// Whole-word, case-insensitive, longest hear first, tolerant of glued/hyphenated parts.
/// See shared/SPEC.md "Correction engine".
enum CorrectionEngine {
    private struct Rule {
        let hear: String
        let write: String
        let pattern: NSRegularExpression
        let length: Int
        let created: Date
    }

    static func apply(_ text: String, entries: [DictionaryEntry]) -> (text: String, events: [CorrectionEvent]) {
        if text.isEmpty { return (text, []) }
        var current = text
        var events: [CorrectionEvent] = []

        for rule in buildRules(entries) {
            let ns = current as NSString
            let matches = rule.pattern.matches(in: current, range: NSRange(location: 0, length: ns.length))
            if matches.isEmpty { continue }
            var out = ""
            var cursor = 0
            var firstMatched: String? = nil
            var count = 0
            for m in matches {
                let matched = ns.substring(with: m.range)
                out += ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor))
                // A match that already equals the canonical write is left alone and not counted.
                if matched == rule.write {
                    out += matched
                } else {
                    out += rule.write
                    if firstMatched == nil { firstMatched = matched }
                    count += 1
                }
                cursor = m.range.location + m.range.length
            }
            out += ns.substring(from: cursor)
            current = out
            if count > 0 { events.append(CorrectionEvent(hear: rule.hear, write: rule.write, matched: firstMatched!, count: count)) }
        }
        return (current, events)
    }

    /// Split on whitespace and hyphens; drop empties.
    static func parts(_ hear: String) -> [String] {
        hear.split(whereSeparator: { $0.isWhitespace || $0 == "-" }).map(String.init)
    }

    /// Lowercase, separators removed — used for duplicate/common checks.
    static func normalize(_ hear: String) -> String {
        parts(hear).joined().lowercased()
    }

    static func buildPattern(_ hear: String) -> NSRegularExpression? {
        let p = parts(hear)
        if p.isEmpty { return nil }
        let body = p.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: #"[\s\-]*"#)
        return try? NSRegularExpression(pattern: #"\b"# + body + #"\b"#, options: [.caseInsensitive])
    }

    private static func buildRules(_ entries: [DictionaryEntry]) -> [Rule] {
        var rules: [Rule] = []
        for e in entries {
            let hear = e.hearText.trimmingCharacters(in: .whitespacesAndNewlines)
            let write = e.writeText.trimmingCharacters(in: .whitespacesAndNewlines)
            if hear.isEmpty || write.isEmpty { continue }
            // A correction whose hear == write can never change anything; terms always run (they fix casing).
            if !e.isTerm && hear == write { continue }
            guard let pattern = buildPattern(hear) else { continue }
            rules.append(Rule(hear: hear, write: write, pattern: pattern, length: normalize(hear).count, created: e.created))
        }
        // Longest hear first; ties by creation order so results are stable.
        return rules.sorted { a, b in a.length != b.length ? a.length > b.length : a.created < b.created }
    }
}
