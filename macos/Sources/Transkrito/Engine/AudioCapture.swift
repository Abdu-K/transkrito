import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation

struct InputDevice: Identifiable, Hashable {
    let uid: String   // "" = system default
    let name: String
    var id: String { uid }
    static let systemDefault = InputDevice(uid: "", name: "System default microphone")
}

/// Chosen microphone via AVAudioEngine. Publishes a smoothed level per buffer and hands every buffer to `onBuffer`
/// (the speech engine converts it to its own format). Duration is tracked for the history entry.
final class AudioCapture {
    private var engine = AVAudioEngine()
    private var meter = LevelMeter()
    private var started: Date?
    private(set) var isCapturing = false

    /// Core Audio device UID; "" = system default. Applied on the next start.
    var deviceUID = ""

    /// Smoothed level 0..1, called on the audio thread.
    var onLevel: ((Double) -> Void)?
    /// Raw mic buffers in the input node's native format, called on the audio thread.
    var onBuffer: ((AVAudioPCMBuffer) -> Void)?

    var inputFormat: AVAudioFormat {
        applyDevice()
        return engine.inputNode.outputFormat(forBus: 0)
    }

    static func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .audio)
        default: return false
        }
    }

    // MARK: - Devices (Core Audio)

    static func devices() -> [InputDevice] {
        var list = [InputDevice.systemDefault]
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                              mScope: kAudioObjectPropertyScopeGlobal,
                                              mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr else { return list }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &ids) == noErr else { return list }
        for id in ids where inputChannels(id) > 0 {
            if let uid = stringProperty(id, kAudioDevicePropertyDeviceUID), let name = stringProperty(id, kAudioObjectPropertyName) {
                list.append(InputDevice(uid: uid, name: name))
            }
        }
        return list
    }

    private static func inputChannels(_ id: AudioDeviceID) -> Int {
        var addr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration,
                                              mScope: kAudioDevicePropertyScopeInput,
                                              mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let raw = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, raw) == noErr else { return 0 }
        let list = UnsafeMutableAudioBufferListPointer(raw.assumingMemoryBound(to: AudioBufferList.self))
        return list.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private static func stringProperty(_ id: AudioDeviceID, _ selector: AudioObjectPropertySelector) -> String? {
        var addr = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value: CFString? = nil
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = withUnsafeMutablePointer(to: &value) { AudioObjectGetPropertyData(id, &addr, 0, nil, &size, $0) }
        return status == noErr ? value as String? : nil
    }

    private static func deviceID(forUID uid: String) -> AudioDeviceID? {
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr else { return nil }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &ids) == noErr else { return nil }
        return ids.first { stringProperty($0, kAudioDevicePropertyDeviceUID) == uid }
    }

    /// Points the input node at the chosen device (or leaves the system default). A fresh engine per session
    /// keeps the input node's format in sync with the device.
    private func applyDevice() {
        guard !isCapturing else { return }
        engine = AVAudioEngine()
        guard !deviceUID.isEmpty, let id = Self.deviceID(forUID: deviceUID), let unit = engine.inputNode.audioUnit else { return }
        var dev = id
        AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &dev, UInt32(MemoryLayout<AudioDeviceID>.size))
    }

    // MARK: - Capture

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
