import AVFoundation
import Foundation

/// Default microphone via AVAudioEngine. Publishes a smoothed level per buffer and hands every buffer to `onBuffer`
/// (the speech engine converts it to its own format). Duration is tracked for the history entry.
final class AudioCapture {
    private let engine = AVAudioEngine()
    private var meter = LevelMeter()
    private var started: Date?
    private(set) var isCapturing = false

    /// Smoothed level 0..1, called on the audio thread.
    var onLevel: ((Double) -> Void)?
    /// Raw mic buffers in the input node's native format, called on the audio thread.
    var onBuffer: ((AVAudioPCMBuffer) -> Void)?

    var inputFormat: AVAudioFormat { engine.inputNode.outputFormat(forBus: 0) }

    static func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .audio)
        default: return false
        }
    }

    func start() throws {
        if isCapturing { return }
        meter.reset()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            if let ch = buffer.floatChannelData?[0] {
                let samples = UnsafeBufferPointer(start: ch, count: Int(buffer.frameLength))
                let level = self.meter.push(samples, dt: Double(buffer.frameLength) / format.sampleRate)
                self.onLevel?(level)
            }
            self.onBuffer?(buffer)
        }
        engine.prepare()
        try engine.start()
        started = Date()
        isCapturing = true
    }

    /// Stops and returns the captured duration in seconds.
    @discardableResult
    func stop() -> Double {
        guard isCapturing else { return 0 }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
        meter.reset()
        onLevel?(0)
        return started.map { Date().timeIntervalSince($0) } ?? 0
    }
}
