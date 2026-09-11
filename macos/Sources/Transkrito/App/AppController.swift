import AppKit
import Foundation
import Observation

enum RecordingState { case idle, listening, transcribing }

/// The one object views observe. Owns the recording state machine (shared/SPEC.md) and wires
/// audio → engine → correction pass → history → clipboard/insert. Mirrors the Windows AppController.
@MainActor @Observable
final class AppController {
    let dictionary: DictionaryStore
    let history: HistoryStore
    var settings: AppSettings
    let engine: SpeechEngine
    let audio = AudioCapture()
    let hotkey = HotkeyManager()

    private(set) var state: RecordingState = .idle
    private(set) var status = "Ready"
    private(set) var statusIsError = false
    private(set) var level: Double = 0
    private(set) var hotkeyError: String?

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
        audio.onBuffer = { [weak self] b in self?.engine.feed(b) }
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

    func setModel(_ localeIdentifier: String) async {
        settings.model = localeIdentifier
        settings.save()
        await engine.setLocale(localeIdentifier)
        await loadModel()
    }

    func setInsertAtCursor(_ on: Bool) {
        settings.insertAtCursor = on
        settings.save()
    }

    /// Called once at startup and whenever the model (locale) changes.
    func loadModel() async {
        await engine.refreshAssetState()
        switch engine.assetState {
        case .installed: setStatus("Ready")
        case .notInstalled: setStatus("Speech model for \(engine.locale.identifier) not downloaded \u{2014} open Settings", error: true)
        case .downloading: setStatus("Downloading speech model\u{2026}")
        case .unsupported: setStatus("\(engine.locale.identifier) is not supported by Apple Speech. Pick another language in Settings.", error: true)
        case .unknown: setStatus("Ready")
        }
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
        guard engine.isReady else {
            await loadModel()
            if !engine.isReady { return }
            return
        }
        guard await AudioCapture.requestPermission() else {
            setStatus("Microphone access denied. Allow Transkrito in System Settings \u{2192} Privacy & Security \u{2192} Microphone.", error: true)
            return
        }
        do {
            try await engine.startSession(inputFormat: audio.inputFormat)
            try audio.start()
            state = .listening
            setStatus("Listening")
        } catch {
            await engine.cancelSession()
            setStatus("Could not start: \(error.localizedDescription)", error: true)
        }
    }

    func stop() async {
        guard state == .listening else { return }
        let duration = audio.stop()
        state = .transcribing
        setStatus("Transcribing\u{2026}")
        defer { state = .idle; level = 0 }
        do {
            let raw = try await engine.finishSession()
            if raw.isEmpty {
                setStatus(duration < 0.4 ? "Hold the key while you speak" : "Nothing heard")
                return
            }
            let (text, events) = CorrectionEngine.apply(raw, entries: dictionary.entries)
            let item = Transcription(
                raw: raw, text: text, durationSec: (duration * 100).rounded() / 100,
                engine: "apple-speech", model: engine.locale.identifier,
                corrections: events.map(CorrectionRecord.init)
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
