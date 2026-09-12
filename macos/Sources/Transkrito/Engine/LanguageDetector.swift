import Foundation

/// Spoken-language ids used everywhere: "en", "de", "ar", "auto" (setting only), "unknown" (history only).
enum Lang {
    static let auto = "auto", en = "en", de = "de", ar = "ar", unknown = "unknown"
    static let supported = [en, de, ar]

    /// Display name in the language's own script; the UI stays in English.
    static func display(_ id: String) -> String {
        switch id {
        case en: return "English"
        case de: return "Deutsch"
        case ar: return "\u{0627}\u{0644}\u{0639}\u{0631}\u{0628}\u{064A}\u{0629}"
        case auto: return "Auto"
        default: return ""
        }
    }

    static func isSupported(_ id: String?) -> Bool { id == en || id == de || id == ar }
}

struct LanguageGuess: Equatable {
    let language: String
    let confidence: Double
    var isConfident: Bool { language != Lang.unknown && confidence >= LanguageDetector.confidentAt }
}

/// Text-based classifier for the three exposed languages. Script decides Arabic; a function-word lexicon plus
/// umlaut/ß evidence separates German from English. Used to stamp history and to confirm what an engine produced.
/// Mirrors windows/.../Engine/LanguageDetector.cs; shared vectors in shared/correction-tests.json "language".
enum LanguageDetector {
    static let confidentAt = 0.6

    private static let german: Set<String> = [
        "der","die","das","und","ich","nicht","ist","zu","ein","eine","mit","auf","für","von","den","dem","des","sich","auch",
        "es","an","er","wir","sie","im","nach","bei","aus","morgen","heute","muss","kann","wird","sind","haben","hat","war",
        "noch","wie","schon","nur","mehr","sehr","zur","zum","dann","wenn","aber","oder","was","mir","mich","dir","uns",
        "bitte","öffne","neu","neue","projekt","gehe","fahre","fahren","schule","arbeit","jetzt","hier","dort","über","unter",
        "diese","dieser","dieses","kein","keine","meine","mein","dein","seine","ihre","wichtig","getroffen","besprochen",
    ]

    private static let english: Set<String> = [
        "the","and","to","of","a","in","is","it","you","that","he","was","for","on","are","with","as","i","his","they","be",
        "at","one","have","this","from","or","had","by","not","but","what","some","we","can","out","other","were","all",
        "there","when","up","use","uses","your","how","said","an","each","she","which","do","their","if","will","way",
        "about","many","then","them","would","like","so","these","her","make","thing","see","him","two","has","look",
        "more","day","could","go","come","did","no","most","my","over","know","than","call","first","who","may","down",
        "been","now","find","please","open","close","new","update","project","need","want","going","just","fine","works",
        "app","me","our","also","into","should","after","before","because","very","much","get","got",
    ]

    static func detect(_ text: String?) -> LanguageGuess {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return LanguageGuess(language: Lang.unknown, confidence: 0) }

        var arabic = 0, latin = 0
        for scalar in text.unicodeScalars {
            if isArabicLetter(scalar) { arabic += 1 }
            else if scalar.properties.isAlphabetic { latin += 1 }
        }
        let letters = arabic + latin
        if letters == 0 { return LanguageGuess(language: Lang.unknown, confidence: 0) }

        let arabicShare = Double(arabic) / Double(letters)
        if arabicShare >= 0.5 { return LanguageGuess(language: Lang.ar, confidence: min(1, 0.6 + arabicShare * 0.4)) }
        if arabicShare >= 0.3 { return LanguageGuess(language: Lang.ar, confidence: 0.5) }

        var de = 0, en = 0
        let punctuation = CharacterSet(charactersIn: ".,;:!?\"'()\u{201C}\u{201D}\u{2018}\u{2019}")
        for raw in text.split(whereSeparator: \.isWhitespace) {
            let w = raw.trimmingCharacters(in: punctuation).lowercased()
            if w.isEmpty { continue }
            if german.contains(w) { de += 1 }
            if english.contains(w) { en += 1 }
        }
        if text.contains(where: { "äöüßÄÖÜ".contains($0) }) { de += 1 }

        if de == 0 && en == 0 { return LanguageGuess(language: Lang.unknown, confidence: 0) }
        if de == en { return LanguageGuess(language: Lang.unknown, confidence: 0.3) }
        let winner = de > en ? Lang.de : Lang.en
        let hi = max(de, en), lo = min(de, en)
        let confidence: Double = hi >= 2 && hi >= 2 * lo ? min(1, 0.6 + 0.1 * Double(hi - lo)) : (hi == 1 && lo == 0 ? 0.5 : 0.4)
        return LanguageGuess(language: winner, confidence: confidence)
    }

    /// Language to store for a finished transcription: the confident guess, else "unknown".
    static func forHistory(_ text: String?) -> String {
        let g = detect(text)
        return g.isConfident ? g.language : Lang.unknown
    }

    static func isArabicLetter(_ s: Unicode.Scalar) -> Bool {
        let v = s.value
        let inBlock = (0x0600...0x06FF).contains(v) || (0x0750...0x077F).contains(v) || (0x08A0...0x08FF).contains(v)
            || (0xFB50...0xFDFF).contains(v) || (0xFE70...0xFEFF).contains(v)
        guard inBlock else { return false }
        switch s.properties.generalCategory {
        case .otherLetter, .nonspacingMark: return true
        default: return false
        }
    }

    /// True when the text's dominant script is right-to-left. Rendering only: the string is never touched.
    static func isRightToLeft(_ text: String?) -> Bool {
        guard let text, !text.isEmpty else { return false }
        var rtl = 0, ltr = 0
        for s in text.unicodeScalars {
            if isArabicLetter(s) || (0x0590...0x05FF).contains(s.value) { rtl += 1 }
            else if s.properties.isAlphabetic { ltr += 1 }
        }
        return rtl > 0 && rtl * 2 >= ltr
    }
}
