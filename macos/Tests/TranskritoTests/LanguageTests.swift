import Foundation
import Testing
@testable import Transkrito

/// Language classifier, RTL check, settings migration and history compatibility — same vectors as the Windows tests.
struct LanguageTests {
    static let vectors: [String: Any] = CorrectionEngineTests.vectors

    static var languageCases: [(String, String)] {
        ((vectors["language"] as! [String: Any])["cases"] as! [[String: Any]]).map { ($0["text"] as! String, $0["expect"] as! String) }
    }
    static var rtlCases: [(String, Bool)] {
        ((vectors["rtl"] as! [String: Any])["cases"] as! [[String: Any]]).map { ($0["text"] as! String, $0["rtl"] as! Bool) }
    }

    @Test(arguments: LanguageTests.languageCases.map(\.0))
    func textLanguageMatchesSharedVectors(text: String) {
        let expect = Self.languageCases.first { $0.0 == text }!.1
        #expect(LanguageDetector.forHistory(text) == expect)
    }

    @Test(arguments: LanguageTests.rtlCases.map(\.0))
    func rtlDetectionMatchesSharedVectors(text: String) {
        let expect = Self.rtlCases.first { $0.0 == text }!.1
        #expect(LanguageDetector.isRightToLeft(text) == expect)
    }

    @Test func rtlRenderingNeverAltersTheString() throws {
        let arabic = "\u{0623}\u{0646}\u{0627} \u{0623}\u{0633}\u{062A}\u{062E}\u{062F}\u{0645} Claude Code \u{0644}\u{0644}\u{0639}\u{0645}\u{0644}."
        var t = Transcription()
        t.text = arabic
        #expect(t.isRightToLeft)
        #expect(t.text == arabic)
        let data = try JsonFile.encoder.encode(t)
        let back = try JsonFile.decoder.decode(Transcription.self, from: data)
        #expect(back.text == arabic)
    }

    @Test func settingsWithoutLanguageMigrateToAuto() throws {
        let old = """
        { "version": 1, "hotkey": { "key": "D", "modifiers": ["control","option"] }, "model": "en-US",
          "insertAtCursor": false, "hotkeyMode": "toggle", "inputDevice": "abc" }
        """
        let s = try JsonFile.decoder.decode(AppSettings.self, from: Data(old.utf8))
        #expect(s.language == Lang.auto)
        #expect(s.hotkey.key == "D")
        #expect(s.insertAtCursor == false)
        #expect(s.hotkeyMode == "toggle")
        #expect(s.inputDevice == "abc")
        let bogus = try JsonFile.decoder.decode(AppSettings.self, from: Data("{ \"language\": \"fr\" }".utf8))
        #expect(bogus.language == Lang.auto)
        let de = try JsonFile.decoder.decode(AppSettings.self, from: Data("{ \"language\": \"de\" }".utf8))
        #expect(de.language == Lang.de)
    }

    @Test func historyLoadsWithAndWithoutLanguage() throws {
        let json = """
        { "version": 1, "items": [
          { "id": "a", "date": "2026-09-11T05:40:00+02:00", "raw": "x", "text": "Ich muss morgen zur Schule.", "durationSec": 1, "engine": "apple-speech", "model": "de-DE", "corrections": [] },
          { "id": "b", "date": "2026-09-11T05:41:00+02:00", "raw": "y", "text": "hello", "durationSec": 1, "engine": "apple-speech", "model": "en-US", "corrections": [], "language": "en" },
          { "id": "c", "date": "2026-09-11T05:42:00+02:00", "raw": "z", "text": "?", "durationSec": 1, "engine": "nemotron", "model": "m", "corrections": [], "language": "unknown" } ] }
        """
        let file = try JsonFile.decoder.decode(HistoryFile.self, from: Data(json.utf8))
        #expect(file.items.count == 3)
        #expect(file.items[0].language == nil)
        #expect(file.items[0].languageLabel == "")
        #expect(file.items[1].language == "en")
        #expect(file.items[1].languageLabel == "English")
        #expect(file.items[2].languageLabel == "")
        // Old entries are written back without an invented language key.
        let back = try JsonFile.encoder.encode(file)
        let obj = try JSONSerialization.jsonObject(with: back) as! [String: Any]
        let items = obj["items"] as! [[String: Any]]
        #expect(items[0]["language"] == nil)
        #expect(items[1]["language"] as? String == "en")
    }

    @Test func displayNamesAreInTheirOwnScript() {
        #expect(Lang.display(Lang.en) == "English")
        #expect(Lang.display(Lang.de) == "Deutsch")
        #expect(Lang.display(Lang.ar) == "\u{0627}\u{0644}\u{0639}\u{0631}\u{0628}\u{064A}\u{0629}")
        #expect(Lang.display(Lang.unknown) == "")
    }
}
