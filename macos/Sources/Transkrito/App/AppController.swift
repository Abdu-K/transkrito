import AppKit
import AVFoundation
import Foundation
import Observation

enum RecordingState { case idle, listening, transcribing }

/// The one object views observe. Owns the recording state machine (shared/SPEC.md) and wires
/// audio → (language detection) → engine → correction pass → history → clipboard/insert.
///
/// Languages: en/de/ar explicit, or Auto. Explicit modes open the Apple session for that locale straight away.
/// Auto buffers the first second or so of speech, runs the local Whisper-tiny language ID on it, opens the matching
/// pipeline and replays the buffered audio into it — nothing is lost. Arabic uses Apple Speech when this Mac can
/// install its Arabic asset, otherwise the local Nemotron multilingual model (same as the Windows build).
@MainActor @Observable
final class AppController {
    let dictionary: DictionaryStore
    let history: HistoryStore
    var settings: AppSettings
    let engine: SpeechEngine
    let audio = AudioCapture()
    let hotkey = HotkeyManager()
    let languageID = SpokenLanguageID()
    let nemotron = NemotronEngine()

    private(set) var state: RecordingState = .idle
    private(set) var status = "Ready"
    private(set) var statusIsError = false
    private(set) var level: Double = 0
    private(set) var hotkeyError: String?
    /// Sherpa model download progress (0…1, -1 while unpacking) or nil.
    private(set) var sherpaProgress: [String: Double] = [:]
    /// True once Apple Speech proved unable to provide Arabic on this Mac; the Nemotron path is used instead.
    private(set) var arabicFallback = false
    private var arabicFallbackAnnounced = false

    var isListening: Bool { state == .listening }
    var isTranscribing: Bool { state == .transcribing }
    var isIdle: Bool { state == .idle }
    var actionLabel: String { state == .listening ? "Stop" : "Start" }
    var hotkeyLabel: String { settings.hotkey.display }
    var hotkeyHint: String { settings.holdToTalk ? "Hold to dictate" : "Press to start, press to stop" }
    var holdToTalkVerb: String { settings.holdToTalk ? "Hold" : "Press" }
    var holdToTalk: Bool {
        get { settings.holdToTalk }
        set { settings.hotkeyMode = newValue ? "hold" : "toggle"; settings.save() }
    }
    var inputDevice: String {
        get { settings.inputDevice }
        set { settings.inputDevice = newValue; settings.save(); audio.deviceUID = newValue }
    }
    var language: String {
        get { settings.language }
        set {
            guard settings.language != newValue else { return }
            settings.language = newValue; settings.save()
            Task { await loadModel() }
        }
    }
    var languageHint: String {
        settings.language == Lang.auto ? "Automatically detects English, German, or Arabic." : "Always transcribe using this language."
    }

    // MARK: - Utterance pipeline

    private enum Phase { case idle, detecting, apple, nemotron }
    private final class Utterance: @unchecked Sendable {
        let lock = NSLock()
        var phase: Phase = .detecting
        var buffers: [AVAudioPCMBuffer] = []   // preroll in the mic's format (for Apple)
        var pcm: [Float] = []                  // preroll at 16 kHz mono (for language ID / Nemotron)
        var voicedSeconds = 0.0
        var totalSeconds = 0.0
        var decisionRequested = false
        var language: String?                  // decided language
        var uncertain = false
        var inputFormat: AVAudioFormat?
        let converter = PCM16k()
    }
    /// Read from the audio thread, replaced only on the main actor at start/stop.
    private final class UtteranceBox: @unchecked Sendable {
        private let lock = NSLock()
        private var value: Utterance?
        var current: Utterance? {
            get { lock.lock(); defer { lock.unlock() }; return value }
            set { lock.lock(); value = newValue; lock.unlock() }
        }
    }
    private let utteranceBox = UtteranceBox()
    private var utterance: Utterance? {
        get { utteranceBox.current }
        set { utteranceBox.current = newValue }
    }
    private var lastDetected: (language: String, at: Date)?

    init() {
        AppPaths.ensureDirs()
        settings = AppSettings.load()
        dictionary = DictionaryStore()
        history = HistoryStore()
        engine = SpeechEngine(localeIdentifier: settings.model)
        engine.biasTerms = Bias.terms(dictionary.entries)
        dictionary.onChange = { [weak self] in
            guard let self else { return }
            self.engine.biasTerms = Bias.terms(self.dictionary.entries)
        }
        audio.deviceUID = settings.inputDevice
        audio.onLevel = { [weak self] l in Task { @MainActor in self?.level = l } }
        audio.onBuffer = { [weak self] b in self?.onBuffer(b) }
        nemotron.onPartial = { [weak self] text in Task { @MainActor in self?.onPartial(text) } }
        hotkey.onPressed = { [weak self] in self?.hotkeyDown() }
        hotkey.onReleased = { [weak self] in self?.hotkeyUp() }
        applyHotkey(settings.hotkey)
    }

    func setStatus(_ text: String, error: Bool = false) { status = text; statusIsError = error }

    // MARK: - Settings

    func applyHotkey(_ hk: HotkeySetting) {
        settings.hotkey = hk
        settings.save()
        hotkeyError = hotkey.register(hk) ? nil : hotkey.lastError
    }

    func setInsertAtCursor(_ on: Bool) {
        settings.insertAtCursor = on
        settings.save()
    }

    // MARK: - Models

    /// Makes sure everything the current language setting needs is present: Apple assets (installing on demand),
    /// the language detector for Auto, and the Nemotron fallback when Apple cannot do Arabic here.
    func loadModel() async {
        await engine.refreshAllAssetStates()
        let needed = settings.language == Lang.auto ? Lang.supported : [settings.language]
        for l in needed where l != Lang.ar {
            if engine.assetState(for: l) == .notInstalled {
                setStatus("Downloading \(Lang.display(l)) speech model\u{2026}")
                await engine.installAsset(for: l)
            }
        }
        if needed.contains(Lang.ar) { await ensureArabic() }
        if settings.language == Lang.auto { await ensureLanguageID() }

        let missing = needed.filter { l in l == Lang.ar ? !(engine.isReady(for: Lang.ar) || (arabicFallback && nemotron.isLoaded)) : !engine.isReady(for: l) }
        if !missing.isEmpty {
            setStatus("\(missing.map(Lang.display).joined(separator: ", ")) speech model unavailable \u{2014} open Settings", error: true)
        } else if settings.language == Lang.auto && !languageID.isLoaded {
            setStatus("Language detector unavailable \u{2014} open Settings", error: true)
        } else if arabicFallback && !arabicFallbackAnnounced && needed.contains(Lang.ar) {
            arabicFallbackAnnounced = true
            setStatus("Apple Arabic speech model unavailable \u{2014} using local multilingual model")
        } else {
            setStatus("Ready")
        }
    }

    /// Arabic is tested at runtime: resolve a locale, install its asset, and only fall back when that truly fails.
    private func ensureArabic() async {
        if engine.isReady(for: Lang.ar) { arabicFallback = false; return }
        if engine.assetState(for: Lang.ar) == .notInstalled {
            setStatus("Downloading Arabic speech model\u{2026}")
            if await engine.installAsset(for: Lang.ar) { arabicFallback = false; return }
        }
        arabicFallback = true
        if !nemotron.isLoaded {
            if !SherpaCatalog.nemotron.isInstalled { await downloadSherpa(SherpaCatalog.nemotron, label: "Arabic speech model") }
            if SherpaCatalog.nemotron.isInstalled {
                setStatus("Loading Arabic speech model\u{2026}")
                do { try await Task.detached { [nemotron] in try nemotron.load() }.value } catch { setStatus("Arabic model unavailable", error: true) }
            }
        }
    }

    private func ensureLanguageID() async {
        if languageID.isLoaded { return }
        if !SherpaCatalog.languageID.isInstalled { await downloadSherpa(SherpaCatalog.languageID, label: "language detector") }
        if SherpaCatalog.languageID.isInstalled {
            do { try await Task.detached { [languageID] in try languageID.load() }.value } catch { setStatus("Language detector unavailable", error: true) }
        }
    }

    func downloadSherpa(_ model: SherpaModel, label: String) async {
        setStatus("Downloading \(label)\u{2026}")
        sherpaProgress[model.id] = 0
        do {
            try await SherpaModelManager.download(model) { [weak self] p in Task { @MainActor in self?.sherpaProgress[model.id] = p } }
        } catch {
            setStatus("\(label.capitalized) download failed: \(error.localizedDescription)", error: true)
        }
        sherpaProgress[model.id] = nil
    }

    // MARK: - Recording

    /// Chord pressed. Hold mode: start. Toggle mode: start or stop.
    func hotkeyDown() {
        if settings.holdToTalk { Task { await start() } } else { toggle() }
    }

    /// Chord released. Hold mode: stop.
    func hotkeyUp() {
        guard settings.holdToTalk, state == .listening else { return }
        Task { await stop() }
    }

    func toggle() {
        switch state {
        case .idle: Task { await start() }
        case .listening: Task { await stop() }
        case .transcribing: break
        }
    }

    func start() async {
        guard state == .idle else { return }
        guard await AudioCapture.requestPermission() else {
            setStatus("Microphone access denied. Allow Transkrito in System Settings \u{2192} Privacy & Security \u{2192} Microphone.", error: true)
            return
        }
        let u = Utterance()
        let format = audio.inputFormat
        u.inputFormat = format
        utterance = u
        do {
            if settings.language == Lang.auto {
                if !languageID.isLoaded { await loadModel() }
                guard languageID.isLoaded else { utterance = nil; return }
                u.phase = .detecting
                try audio.start()
                state = .listening
                setStatus("Detecting language\u{2026}")
            } else {
                try await openPipeline(u, language: settings.language, uncertain: false)
                try audio.start()
                state = .listening
                setStatus("Listening \u{00B7} \(Lang.display(settings.language))")
            }
        } catch {
            utterance = nil
            await engine.cancelSession()
            setStatus("Could not start: \(error.localizedDescription)", error: true)
        }
    }

    /// Audio thread. Preroll while detecting; otherwise feed the active pipeline.
    nonisolated private func onBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let u = utteranceBox.current else { return }
        u.lock.lock()
        switch u.phase {
        case .detecting:
            let pcm = u.converter.convert(buffer)
            u.buffers.append(buffer)
            u.pcm.append(contentsOf: pcm)
            let dt = Double(buffer.frameLength) / buffer.format.sampleRate
            u.totalSeconds += dt
            if audio.currentLevel >= Tokens.Pillar.speakingThreshold { u.voicedSeconds += dt }
            let ready = u.voicedSeconds >= AutoDetect.minVoicedSeconds || u.totalSeconds >= AutoDetect.maxWaitSeconds
            let request = ready && !u.decisionRequested
            if request { u.decisionRequested = true }
            u.lock.unlock()
            if request { Task { @MainActor in await self.decide() } }
        case .apple:
            u.lock.unlock()
            engine.feed(buffer)
        case .nemotron:
            let pcm = u.converter.convert(buffer)
            u.lock.unlock()
            nemotron.feed(pcm)
        case .idle:
            u.lock.unlock()
        }
    }

    /// Runs the language ID on the preroll, opens the pipeline, replays the preroll into it.
    private func decide() async {
        guard let u = utterance else { return }
        u.lock.lock()
        guard u.phase == .detecting else { u.lock.unlock(); return }
        let sample = u.pcm
        u.lock.unlock()

        let detected = await Task.detached { [languageID] in languageID.detect(sample) }.value
        let (lang, uncertain) = detected.map { ($0, false) } ?? fallbackLanguage()
        do {
            try await openPipeline(u, language: lang, uncertain: uncertain)
        } catch {
            await engine.cancelSession()
            setStatus("Could not start: \(error.localizedDescription)", error: true)
            return
        }
        if state == .listening { setStatus("Listening \u{00B7} \(Lang.display(lang))") }
    }

    /// Opens Apple (or Nemotron for Arabic-without-Apple) for `language`, then flushes any preroll — under the lock so
    /// the audio thread cannot slip a buffer past the switch.
    private func openPipeline(_ u: Utterance, language: String, uncertain: Bool) async throws {
        let useNemotron = language == Lang.ar && (arabicFallback || !engine.isReady(for: Lang.ar))
        if useNemotron {
            guard nemotron.isLoaded else { throw SpeechEngine.EngineError.languageUnsupported(Lang.ar) }
            nemotron.begin()
        } else {
            guard let format = u.inputFormat else { return }
            try await engine.startSession(inputFormat: format, language: language)
        }
        u.lock.lock()
        let buffers = u.buffers, pcm = u.pcm
        u.buffers = []; u.pcm = []
        u.language = language; u.uncertain = uncertain
        u.phase = useNemotron ? .nemotron : .apple
        u.lock.unlock()
        if useNemotron { if !pcm.isEmpty { nemotron.feed(pcm) } } else { for b in buffers { engine.feed(b) } }
    }

    /// When the detector is unsure: the last recent detection, else the system language if exposed, else English.
    private func fallbackLanguage() -> (String, Bool) {
        if let last = lastDetected, Date().timeIntervalSince(last.at) < AutoDetect.recentSeconds { return (last.language, true) }
        if let sys = Locale.current.language.languageCode?.identifier, Lang.isSupported(sys) { return (sys, true) }
        return (Lang.en, true)
    }

    private func onPartial(_ text: String) { /* Nemotron partials: nothing to show beyond the language line */ }

    func stop() async {
        guard state == .listening, let u = utterance else { return }
        let duration = audio.stop()
        state = .transcribing
        setStatus("Transcribing\u{2026}")
        defer { state = .idle; level = 0; utterance = nil }
        do {
            // Released before the detector had enough audio: decide on what we have.
            u.lock.lock(); let stillDetecting = u.phase == .detecting; u.lock.unlock()
            if stillDetecting { await decide() }
            u.lock.lock(); let phase = u.phase; let chosen = u.language; let uncertain = u.uncertain; u.lock.unlock()

            let raw: String
            switch phase {
            case .apple: raw = try await engine.finishSession()
            case .nemotron: raw = await nemotron.end()
            default: raw = ""
            }
            if raw.isEmpty {
                setStatus(duration < 0.4 ? "Hold the key while you speak" : "Nothing heard")
                return
            }
            let (text, events) = CorrectionEngine.apply(raw, entries: dictionary.entries)
            let language: String
            if settings.language != Lang.auto {
                language = settings.language
            } else {
                let textGuess = LanguageDetector.detect(raw)
                if let chosen, !uncertain { language = chosen }
                else if textGuess.isConfident { language = textGuess.language }
                else { language = Lang.unknown }
            }
            if language != Lang.unknown { lastDetected = (language, Date()) }
            let item = Transcription(
                raw: raw, text: text, durationSec: (duration * 100).rounded() / 100,
                engine: phase == .nemotron ? "nemotron" : "apple-speech",
                model: phase == .nemotron ? SherpaCatalog.nemotron.id : engine.locale.identifier,
                corrections: events.map(CorrectionRecord.init),
                language: language
            )
            history.add(item)
            let id = item.id
            Task { try? await Task.sleep(for: .seconds(Tokens.Motion.rowHighlight)); history.markSeen(id) }
            Inserter.copyToClipboard(text)
            if settings.insertAtCursor { Inserter.pasteIntoForegroundApp() }
            setStatus(events.isEmpty ? "Copied" : "Copied \u{00B7} \(item.correctionLabel)")
        } catch {
            setStatus("Transcription failed: \(error.localizedDescription)", error: true)
        }
    }
}

/// Auto-detection timing (seconds). Enough voiced audio for a meaningful decision, bounded so silence cannot stall.
enum AutoDetect {
    static let minVoicedSeconds = 1.2
    static let maxWaitSeconds = 3.0
    static let recentSeconds = 600.0
}
