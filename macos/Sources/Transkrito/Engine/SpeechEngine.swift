import AVFoundation
import Foundation
import Observation
import Speech

/// Apple Speech (macOS 26): `SpeechAnalyzer` + `DictationTranscriber`, streaming while the mic is open so the final
/// text is ready almost immediately after Stop.
///
/// Biasing: dictionary terms go in through `AnalysisContext.contextualStrings` and `SpeechAnalyzer.setContext(_:)`.
/// `DictationTranscriber` honors contextual strings; the long-form `SpeechTranscriber` ignores them, which is why
/// this app uses the dictation module. The list is capped (`Bias.maxTerms`) — long context makes the model drift.
@MainActor @Observable
final class SpeechEngine {
    enum AssetState: Equatable {
        case unknown, installed, downloading(Double), notInstalled, unsupported
    }

    private(set) var locale: Locale
    private(set) var assetState: AssetState = .unknown
    private(set) var isSessionOpen = false
    private(set) var lastError: String?
    var biasTerms: [String] = []

    /// Contextual strings are supported by the dictation module.
    let biasSupported = true
    var biasStatus: String {
        biasSupported ? "Engine biasing: on \u{00B7} up to \(Bias.maxTerms) dictionary terms are passed as context." : "Engine biasing: unavailable."
    }

    private var transcriber: DictationTranscriber?
    private var analyzer: SpeechAnalyzer?
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

    static var installedLocales: [Locale] {
        get async { await DictationTranscriber.installedLocales }
    }

    // MARK: - Assets / model

    func setLocale(_ identifier: String) async {
        locale = Locale(identifier: identifier)
        await refreshAssetState()
    }

    private func makeTranscriber() -> DictationTranscriber {
        DictationTranscriber(
            locale: locale,
            contentHints: [.shortForm],
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )
    }

    func refreshAssetState() async {
        let t = makeTranscriber()
        transcriber = t
        switch await AssetInventory.status(forModules: [t]) {
        case .installed: assetState = .installed
        case .downloading: assetState = .downloading(0)
        case .supported: assetState = .notInstalled
        case .unsupported: assetState = .unsupported
        @unknown default: assetState = .unknown
        }
    }

    /// Downloads the on-device speech asset for the current locale.
    func installAsset() async {
        let t = makeTranscriber()
        transcriber = t
        do {
            _ = try await AssetInventory.reserve(locale: locale)
            guard let request = try await AssetInventory.assetInstallationRequest(supporting: [t]) else {
                await refreshAssetState()
                return
            }
            assetState = .downloading(0)
            let progress = request.progress
            let poll = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(250))
                    await MainActor.run { self?.assetState = .downloading(progress.fractionCompleted) }
                }
            }
            defer { poll.cancel() }
            try await request.downloadAndInstall()
            lastError = nil
        } catch {
            lastError = "Model download failed: \(error.localizedDescription)"
        }
        await refreshAssetState()
    }

    // MARK: - Session

    var isReady: Bool { assetState == .installed }

    /// Opens a streaming session. Call before `AudioCapture.start()`.
    func startSession(inputFormat: AVAudioFormat) async throws {
        guard !isSessionOpen else { return }
        let t = makeTranscriber()
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

    /// Called on the audio thread with mic buffers in the input node's format.
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
        var errorDescription: String? { "No compatible audio format for the speech model." }
    }
}
