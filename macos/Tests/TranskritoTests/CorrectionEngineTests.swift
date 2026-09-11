import Foundation
import Testing
@testable import Transkrito

/// Runs the shared vectors in shared/correction-tests.json — the same file the Windows tests use.
struct CorrectionEngineTests {
    static let vectors: [String: Any] = {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("shared/correction-tests.json")
        let data = try! Data(contentsOf: url)
        return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }()

    static let iso: ISO8601DateFormatter = { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }()

    static func entry(_ d: [String: Any]) -> DictionaryEntry {
        DictionaryEntry(
            type: d["type"] as! String,
            text: d["text"] as? String,
            hear: d["hear"] as? String,
            write: d["write"] as? String,
            created: (d["created"] as? String).flatMap { iso.date(from: $0) } ?? Date(timeIntervalSince1970: 0)
        )
    }

    static var cases: [[String: Any]] { vectors["cases"] as! [[String: Any]] }
    static var warningCases: [[String: Any]] { vectors["warnings"] as! [[String: Any]] }
    static var biasCases: [[String: Any]] { vectors["bias"] as! [[String: Any]] }

    @Test(arguments: CorrectionEngineTests.cases.map { $0["name"] as! String })
    func applyMatchesSharedVectors(name: String) throws {
        let c = Self.cases.first { $0["name"] as! String == name }!
        let entries = (c["entries"] as! [[String: Any]]).map(Self.entry)
        let input = c["input"] as! String
        let expected = c["expected"] as! String
        let expectedEvents = (c["events"] as! [[String: Any]]).map {
            CorrectionEvent(hear: $0["hear"] as! String, write: $0["write"] as! String, matched: $0["matched"] as! String, count: $0["count"] as! Int)
        }

        let (text, events) = CorrectionEngine.apply(input, entries: entries)
        #expect(text == expected)
        #expect(events == expectedEvents)

        // Idempotence: a second pass changes nothing.
        let (again, againEvents) = CorrectionEngine.apply(text, entries: entries)
        #expect(again == text)
        #expect(againEvents.isEmpty)
    }

    @Test(arguments: CorrectionEngineTests.warningCases.map { $0["name"] as! String })
    func warningsMatchSharedVectors(name: String) {
        let c = Self.warningCases.first { $0["name"] as! String == name }!
        let others = (c["others"] as! [[String: Any]]).map(Self.entry)
        let expect = (c["expect"] as! [String]).sorted()
        let got = Array(Set(DictionaryWarnings.check(hear: c["hear"] as! String, write: c["write"] as? String, others: others)
            .map { $0.kind.rawValue })).sorted()
        #expect(got == expect)
    }

    @Test func biasTermsMatchSharedVectors() {
        for c in Self.biasCases {
            let entries = (c["entries"] as! [[String: Any]]).map(Self.entry)
            let expect = c["expect"] as! [String]
            #expect(Bias.terms(entries, maxTerms: c["maxTerms"] as! Int) == expect)
        }
    }
}
