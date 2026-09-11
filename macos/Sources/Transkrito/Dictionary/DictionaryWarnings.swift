import Foundation

enum WarningKind: String { case common, noop, duplicate, shadowed }

struct DictionaryWarning: Identifiable, Equatable {
    let kind: WarningKind
    let message: String
    var id: String { kind.rawValue + message }
}

/// Small list of common English words (shared/common-words.txt, bundled as a resource).
enum CommonWords {
    static let words: Set<String> = {
        guard let url = AppResources.url(forResource: "common-words", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return Set(text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty })
    }()
    static func contains(_ normalized: String) -> Bool { words.contains(normalized) }
}

/// Checks an entry the user is about to save. Warnings never block saving.
enum DictionaryWarnings {
    static let shortWordMax = 3

    static func check(hear: String, write: String?, others: [DictionaryEntry], excludeId: String? = nil) -> [DictionaryWarning] {
        var result: [DictionaryWarning] = []
        let parts = CorrectionEngine.parts(hear)
        if parts.isEmpty { return result }
        let normalized = CorrectionEngine.normalize(hear)
        let trimmed = hear.trimmingCharacters(in: .whitespacesAndNewlines)

        if CommonWords.contains(normalized) || (parts.count == 1 && parts[0].count <= shortWordMax) {
            result.append(.init(kind: .common, message: "\u{201C}\(trimmed)\u{201D} is a common word \u{2014} this will rewrite it everywhere."))
        }
        if let w = write, trimmed == w.trimmingCharacters(in: .whitespacesAndNewlines) {
            result.append(.init(kind: .noop, message: "Hear and write are the same."))
        }

        let mine = parts.map { $0.lowercased() }
        for other in others {
            if let ex = excludeId, other.id == ex { continue }
            let otherHear = other.hearText
            if otherHear.isEmpty { continue }
            if CorrectionEngine.normalize(otherHear) == normalized {
                result.append(.init(kind: .duplicate, message: "Already in the dictionary."))
                continue
            }
            let theirs = CorrectionEngine.parts(otherHear).map { $0.lowercased() }
            if isStrictSubsequence(mine, in: theirs) || isStrictSubsequence(theirs, in: mine) {
                result.append(.init(kind: .shadowed, message: "Overlaps with \u{201C}\(otherHear)\u{201D} \u{2014} longest match wins."))
            }
        }
        return result
    }

    /// true if `small` appears as a contiguous run inside `big` and is shorter than it.
    private static func isStrictSubsequence(_ small: [String], in big: [String]) -> Bool {
        if small.isEmpty || small.count >= big.count { return false }
        for start in 0...(big.count - small.count) where Array(big[start..<(start + small.count)]) == small { return true }
        return false
    }
}

/// Builds the short list of strings handed to the speech engine as context.
enum Bias {
    /// Cap: long context makes speech models drift and invent text on quiet audio. Mirrors tokens.json bias.maxTerms.
    static let maxTerms = Tokens.biasMaxTerms

    static func terms(_ entries: [DictionaryEntry], maxTerms: Int = Bias.maxTerms) -> [String] {
        var seen = Set<String>()
        var list: [String] = []
        for e in entries.sorted(by: { $0.created > $1.created }) {
            let w = e.writeText.trimmingCharacters(in: .whitespacesAndNewlines)
            if w.isEmpty || !seen.insert(w.lowercased()).inserted { continue }
            list.append(w)
            if list.count >= maxTerms { break }
        }
        return list
    }
}
