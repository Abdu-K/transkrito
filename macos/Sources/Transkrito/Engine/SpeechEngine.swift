import AVFoundation
import Foundation
import Observation
import Speech

/// Apple Speech (macOS 26): `SpeechAnalyzer` + `DictationTranscriber`, streaming while the mic is open so the final
/// text is ready almost immediately after Stop.
///
/// Locales are resolved at runtime from `DictationTranscriber.supportedLocales` for each of the three exposed
/// languages (never assumed). Auto mode is implemented above this engine (see AppController): a local
/// spoken-language ID picks the language, then the matching locale's session is started with the buffered audio.
///
/// Biasing: dictionary terms go in through `AnalysisContext.contextualStrings` and `SpeechAnalyzer.setContext(_:)`.
/// `DictationTranscriber` honors contextual strings; the long-form `SpeechTranscriber` ignores them, which is why
/// this app uses the dictation module. The list is capped (`Bias.maxTerms`) — long context makes the model drift.
@MainActor @Observable
final class SpeechEngine {
    enum AssetState: Equatable {
        case unknown, installed, downloading(Double), notInstalled, unsupported
    }

    /// Locale of the most recent session (what the history "model" column records).
    private(set) var locale: Locale
    /// Per-language asset state ("en" / "de" / "ar").
    private(set) var assetStates: [String: AssetState] = [:]
    private(set) var isSessionOpen = false
    private(set) var lastError: String?
    var biasTerms: [String] = []

    /// Contextual strings are supported by the dictation module.
    let biasSupported = true
    var biasStatus: String {
        "Engine biasing: on \u{00B7} up to \(Bias.maxTerms) dictionary terms are passed as context."
    }

    private var transcriber: DictationTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var supportedLocales: [Locale]?
    /// Shared with the audio thread; lives outside the main-actor state.
    private let box = SessionBox()

    private final class SessionBox: @unchecked Sendable {
        private let lock = NSLock()
        private var value: Session?
        var session: Session? {
            get { lock.lock(); defer { lock.unlock() }; return value }
            set { lock.lock(); value = newValue; lock.unlock() }
        }
    }

    /// Everything the audio thread needs, immutable once created.
    private final class Session: @unchecked Sendable {
        let continuation: AsyncStream<AnalyzerInput>.Continuation
        let format: AVAudioFormat
        var converter: AVAudioConverter?
        var results: Task<String, Error>?
        init(continuation: AsyncStream<AnalyzerInput>.Continuation, format: AVAudioFormat) {
            self.continuation = continuation
            self.format = format
        }
    }

    init(localeIdentifier: String) {
        locale = Locale(identifier: localeIdentifier)
    }

    static var supportedLocales: [Locale] {
        get async { await DictationTranscriber.supportedLocales }
    }

    // MARK: - Locale resolution (runtime, never assumed)

    private func loadSupported() async -> [Locale] {
        if let s = supportedLocales { return s }
        let s = await DictationTranscriber.supportedLocales
        supportedLocales = s
        return s
    }

    /// The locale Apple Speech actually supports for a language on this Mac, or nil.
    /// en: the user's own English region when supported, else en-US, else any en-*. de: de-DE else any de-*. ar: any ar-*.
    func resolveLocale(for language: String) async -> Locale? {
        let all = await loadSupported()
        func matches(_ l: Locale) -> Bool { l.language.languageCode?.identifier == language }
        let candidates = all.filter(matches)
        if candidates.isEmpty { return nil }
        func pick(_ id: String) -> Locale? { candidates.first { $0.identifier.replacingOccurrences(of: "_", with: "-") == id } }
        switch language {
        case Lang.en:
            if matches(Locale.current), let same = candidates.first(where: { $0.identifier == Locale.current.identifier }) { return same }
            return pick("en-US") ?? candidates[0]
        case Lang.de:
            return pick("de-DE") ?? candidates[0]
        default:
            return pick("ar-SA") ?? candidates[0]
        }
    }

    private func makeTranscriber(_ loc: Locale) -> DictationTranscriber {
        DictationTranscriber(locale: loc, contentHints: [.shortForm], transcriptionOptions: [], reportingOptions: [], attributeOptions: [])
    }

    // MARK: - Assets / model

    func refreshAssetState(for language: String) async {
        guard let loc = await resolveLocale(for: language) else { assetStates[language] = .unsupported; return }
        let t = makeTranscriber(loc)
        switch await AssetInventory.status(forModules: [t]) {
        case .installed: assetStates[language] = .installed
        case .downloading: assetStates[language] = .downloading(0)
        case .supported: assetStates[language] = .notInstalled
        case .unsupported: assetStates[language] = .unsupported
        @unknown default: assetStates[language] = .unknown
        }
    }

    func refreshAllAssetStates() async {
        for l in Lang.supported { await refreshAssetState(for: l) }
    }

    func assetState(for language: String) -> AssetState { assetStates[language] ?? .unknown }
    func isReady(for language: String) -> Bool { assetState(for: language) == .installed }

    /// Downloads the on-device speech asset for a language. Returns false when Apple cannot provide it here.
    @discardableResult
    func installAsset(for language: String) async -> Bool {
        guard let loc = await resolveLocale(for: language) else { assetStates[language] = .unsupported; return false }
        let t = makeTranscriber(loc)
        do {
            _ = try await AssetInventory.reserve(locale: loc)
            guard let request = try await AssetInventory.assetInstallationRequest(supporting: [t]) else {
                await refreshAssetState(for: language)
                return isReady(for: language)
            }
            assetStates[language] = .downloading(0)
            let progress = request.progress
            let poll = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(250))
                    await MainActor.run { self?.assetStates[language] = .downloading(progress.fractionCompleted) }
                }
            }
            defer { poll.cancel() }
            try await request.downloadAndInstall()
            lastError = nil
        } catch {
            lastError = "Speech model download failed: \(error.localizedDescription)"
        }
        await refreshAssetState(for: language)
        return isReady(for: language)
    }

    // MARK: - Session

    /// Opens a streaming session for a language. Call before feeding audio. Throws when the locale is unavailable.
    func startSession(inputFormat: AVAudioFormat, language: String) async throws {
        guard !isSessionOpen else { return }
        guard let loc = await resolveLocale(for: language) else { throw EngineError.languageUnsupported(language) }
        locale = loc
        let t = makeTranscriber(loc)
        transcriber = t
        let analyzer = SpeechAnalyzer(modules: [t])
        self.analyzer = analyzer

        // Contextual biasing (dictionary terms + correction targets), capped.
        let context = AnalysisContext()
        if !biasTerms.isEmpty {
            context.contextualStrings = [.general: biasTerms]
        }
        try await analyzer.setContext(context)

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [t]) else {
            throw EngineError.noAudioFormat
        }
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        let session = Session(continuation: continuation, format: format)
        session.converter = AVAudioConverter(from: inputFormat, to: format)
        session.results = Task {
            var text = ""
            for try await result in t.results where result.isFinal {
                text += String(result.text.characters)
            }
            return text
        }
        box.session = session
        try await analyzer.start(inputSequence: stream)
        isSessionOpen = true
    }

    /// Called on the audio thread with mic buffers in the input node's format (or with buffered preroll).
    nonisolated func feed(_ buffer: AVAudioPCMBuffer) {
        guard let session = box.session, let converter = session.converter else { return }

        let ratio = session.format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
        guard let out = AVAudioPCMBuffer(pcmFormat: session.format, frameCapacity: capacity) else { return }
        var consumed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if consumed { status.pointee = .noDataNow; return nil }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        if error == nil, out.frameLength > 0 {
            session.continuation.yield(AnalyzerInput(buffer: out))
        }
    }

    /// Closes the input, waits for the analyzer to finalize, returns the full text.
    func finishSession() async throws -> String {
        guard isSessionOpen, let analyzer else { return "" }
        let session = box.session
        box.session = nil
        isSessionOpen = false
        session?.continuation.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        let text = try await session?.results?.value ?? ""
        self.analyzer = nil
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cancelSession() async {
        let session = box.session
        box.session = nil
        isSessionOpen = false
        session?.continuation.finish()
        session?.results?.cancel()
        await analyzer?.cancelAndFinishNow()
        analyzer = nil
    }

    enum EngineError: LocalizedError {
        case noAudioFormat
        case languageUnsupported(String)
        var errorDescription: String? {
            switch self {
            case .noAudioFormat: return "No compatible audio format for the speech model."
            case .languageUnsupported(let l): return "Apple Speech has no \(Lang.display(l)) model on this Mac."
            }
        }
    }
}
