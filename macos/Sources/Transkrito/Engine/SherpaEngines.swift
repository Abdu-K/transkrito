import AVFoundation
import Foundation
import SherpaOnnx

/// Converts mic buffers (any format) to 16 kHz mono Float32 for the sherpa-onnx models.
final class PCM16k {
    static let rate: Double = 16000
    private var converter: AVAudioConverter?
    private var from: AVAudioFormat?
    private let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: rate, channels: 1, interleaved: false)!

    func convert(_ buffer: AVAudioPCMBuffer) -> [Float] {
        if from != buffer.format { from = buffer.format; converter = AVAudioConverter(from: buffer.format, to: target) }
        guard let converter else { return [] }
        let ratio = rate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return [] }
        var consumed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if consumed { status.pointee = .noDataNow; return nil }
            consumed = true; status.pointee = .haveData; return buffer
        }
        guard error == nil, let ch = out.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: ch, count: Int(out.frameLength)))
    }
}

/// Whisper-tiny spoken-language identification restricted to the three exposed languages.
/// Kept warm once loaded (~100 MB); one call takes a few hundred ms on Apple silicon.
final class SpokenLanguageID: @unchecked Sendable {
    private var slid: SherpaOnnxSpokenLanguageIdentificationWrapper?
    private let lock = NSLock()
    var isLoaded: Bool { lock.lock(); defer { lock.unlock() }; return slid != nil }

    func load() throws {
        let m = SherpaCatalog.languageID
        guard m.isInstalled else { throw CocoaError(.fileNoSuchFile) }
        var config = sherpaOnnxSpokenLanguageIdentificationConfig(
            whisper: sherpaOnnxSpokenLanguageIdentificationWhisperConfig(encoder: m.path("tiny-encoder.int8.onnx"), decoder: m.path("tiny-decoder.int8.onnx")),
            numThreads: 2)
        let wrapper = SherpaOnnxSpokenLanguageIdentificationWrapper(config: &config)
        lock.lock(); slid = wrapper; lock.unlock()
    }

    /// Returns "en" | "de" | "ar", or nil when Whisper heard some other language (the caller applies its fallback).
    func detect(_ samples16k: [Float]) -> String? {
        lock.lock(); let s = slid; lock.unlock()
        guard let s, samples16k.count > Int(PCM16k.rate / 2) else { return nil }
        let lang = s.decode(samples: samples16k, sampleRate: Int(PCM16k.rate)).lang.lowercased()
        return Lang.isSupported(lang) ? lang : nil
    }

    func unload() { lock.lock(); slid = nil; lock.unlock() }
}

/// Nemotron 3.5 multilingual streaming ASR through sherpa-onnx — the Arabic path when Apple Speech has no Arabic
/// asset for this Mac (and the Windows engine's twin). Decodes as audio arrives; the transcript is ready right after
/// the key is released.
final class NemotronEngine: @unchecked Sendable {
    private var recognizer: SherpaOnnxRecognizer?
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "transkrito.nemotron", qos: .userInitiated)
    private var partial = ""
    var onPartial: ((String) -> Void)?
    var isLoaded: Bool { lock.lock(); defer { lock.unlock() }; return recognizer != nil }

    func load() throws {
        let m = SherpaCatalog.nemotron
        guard m.isInstalled else { throw CocoaError(.fileNoSuchFile) }
        let model = sherpaOnnxOnlineModelConfig(
            tokens: m.path("tokens.txt"),
            transducer: sherpaOnnxOnlineTransducerModelConfig(encoder: m.path("encoder.int8.onnx"), decoder: m.path("decoder.int8.onnx"), joiner: m.path("joiner.int8.onnx")),
            numThreads: max(2, min(8, ProcessInfo.processInfo.activeProcessorCount / 2)))
        var config = sherpaOnnxOnlineRecognizerConfig(
            featConfig: sherpaOnnxFeatureConfig(sampleRate: Int(PCM16k.rate), featureDim: 128),
            modelConfig: model, enableEndpoint: false, decodingMethod: "greedy_search")
        let r = SherpaOnnxRecognizer(config: &config)
        lock.lock(); recognizer = r; lock.unlock()
    }

    func begin() {
        lock.lock(); recognizer?.reset(); partial = ""; lock.unlock()
    }

    /// Audio thread: enqueue a 16 kHz chunk; decoding happens on the engine queue.
    func feed(_ samples16k: [Float]) {
        queue.async { [self] in
            lock.lock(); let r = recognizer; lock.unlock()
            guard let r else { return }
            r.acceptWaveform(samples: samples16k, sampleRate: Int(PCM16k.rate))
            var decoded = false
            while r.isReady() { r.decode(); decoded = true }
            if decoded {
                let text = r.getResult().text
                if text != partial { partial = text; onPartial?(text) }
            }
        }
    }

    func end() async -> String {
        await withCheckedContinuation { cont in
            queue.async { [self] in
                lock.lock(); let r = recognizer; lock.unlock()
                guard let r else { cont.resume(returning: ""); return }
                r.acceptWaveform(samples: [Float](repeating: 0, count: Int(PCM16k.rate * 0.4)), sampleRate: Int(PCM16k.rate))
                r.inputFinished()
                while r.isReady() { r.decode() }
                let text = r.getResult().text.trimmingCharacters(in: .whitespacesAndNewlines)
                r.reset()
                cont.resume(returning: text)
            }
        }
    }

    func unload() { lock.lock(); recognizer = nil; lock.unlock() }
}
