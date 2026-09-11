import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Clipboard + optional ⌘V into whatever app is in front (the one the hotkey was pressed in).
enum Inserter {
    static func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    /// Posting ⌘V needs Accessibility. Returns false (and prompts once) when it is not granted.
    static var canInsert: Bool {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
    }

    /// Sends ⌘V. Skipped when Transkrito itself is in front (nothing sensible to paste into).
    @discardableResult
    static func pasteIntoForegroundApp() -> Bool {
        if NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier { return false }
        guard canInsert else { return false }
        let src = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else { return false }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }
}
