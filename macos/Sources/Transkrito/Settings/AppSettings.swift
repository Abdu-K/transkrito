import Foundation
import Carbon.HIToolbox

/// macOS modifiers: control, option, shift, command. Default ⌃⌥Space.
struct HotkeySetting: Codable, Equatable {
    var key: String = "Space"
    var modifiers: [String] = ["control", "option"]

    var display: String {
        let mods = modifiers.map { m -> String in
            switch m {
            case "control": return "\u{2303}"
            case "option": return "\u{2325}"
            case "shift": return "\u{21E7}"
            case "command": return "\u{2318}"
            default: return m
            }
        }.joined()
        return mods + keyGlyph
    }

    private var keyGlyph: String {
        switch key {
        case "Space": return "Space"
        case "Return": return "\u{21A9}"
        case "Escape": return "\u{238B}"
        case "Tab": return "\u{21E5}"
        default: return key.uppercased()
        }
    }

    /// Carbon modifier flags for RegisterEventHotKey.
    var carbonModifiers: UInt32 {
        var m: UInt32 = 0
        for mod in modifiers {
            switch mod {
            case "control": m |= UInt32(controlKey)
            case "option": m |= UInt32(optionKey)
            case "shift": m |= UInt32(shiftKey)
            case "command": m |= UInt32(cmdKey)
            default: break
            }
        }
        return m
    }

    /// Virtual key code for RegisterEventHotKey (US layout names).
    var carbonKeyCode: UInt32? {
        Self.keyCodes[key] ?? Self.keyCodes[key.uppercased()]
    }

    static let keyCodes: [String: UInt32] = [
        "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04, "G": 0x05, "Z": 0x06, "X": 0x07, "C": 0x08, "V": 0x09,
        "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E, "R": 0x0F, "Y": 0x10, "T": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
        "4": 0x15, "6": 0x16, "5": 0x17, "9": 0x19, "7": 0x1A, "8": 0x1C, "0": 0x1D, "O": 0x1F, "U": 0x20, "I": 0x22,
        "P": 0x23, "L": 0x25, "J": 0x26, "K": 0x28, "N": 0x2D, "M": 0x2E, "Return": 0x24, "Tab": 0x30, "Space": 0x31,
        "Escape": 0x35, "F1": 0x7A, "F2": 0x78, "F3": 0x63, "F4": 0x76, "F5": 0x60, "F6": 0x61, "F7": 0x62, "F8": 0x64,
        "F9": 0x65, "F10": 0x6D, "F11": 0x67, "F12": 0x6F,
    ]

    static func keyName(forCode code: UInt16) -> String? {
        keyCodes.first { $0.value == UInt32(code) }?.key
    }
}

struct AppSettings: Codable, Equatable {
    var version = 1
    var hotkey = HotkeySetting()
    /// Locale identifier for the speech model, e.g. "en-US".
    var model: String = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    var insertAtCursor = true

    static func load() -> AppSettings {
        ((try? JsonFile.read(AppSettings.self, from: AppPaths.settings)) ?? nil) ?? AppSettings()
    }

    func save() { try? JsonFile.write(self, to: AppPaths.settings) }
}
