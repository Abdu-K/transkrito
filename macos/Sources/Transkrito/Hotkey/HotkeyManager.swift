import Carbon.HIToolbox
import Foundation

/// Global hotkey via Carbon `RegisterEventHotKey`. Works while any app is in front and needs no Accessibility grant.
@MainActor
final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private static let signature: OSType = 0x54524B54 // "TRKT"
    private static let id: UInt32 = 1

    var onPressed: (() -> Void)?
    private(set) var lastError: String?

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            guard hk.signature == HotkeyManager.signature, let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in manager.onPressed?() }
            return noErr
        }, 1, &spec, selfPtr, &handlerRef)
    }

    @discardableResult
    func register(_ hk: HotkeySetting) -> Bool {
        unregister()
        guard let code = hk.carbonKeyCode else {
            lastError = "Unknown key \u{201C}\(hk.key)\u{201D}."
            return false
        }
        let id = EventHotKeyID(signature: Self.signature, id: Self.id)
        let status = RegisterEventHotKey(code, hk.carbonModifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            hotKeyRef = nil
            lastError = status == OSStatus(eventHotKeyExistsErr)
                ? "\(hk.display) is taken by another app \u{2014} pick a different hotkey in Settings."
                : "Hotkey \(hk.display) could not be registered (error \(status))."
            return false
        }
        lastError = nil
        return true
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        hotKeyRef = nil
    }
}
