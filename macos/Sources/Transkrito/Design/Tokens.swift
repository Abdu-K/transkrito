// GENERATED from design/tokens.json by design/gen-tokens.py. Do not edit by hand.
import SwiftUI

/// Design tokens. Every view pulls from here; no literal values in views.
enum Tokens {
    enum Colors {
        /// window gradient start (top)
        static let bgTop = Color(.sRGB, red: 0.8275, green: 0.8902, blue: 0.9569, opacity: 1.0)
        /// window gradient end (bottom)
        static let bgBottom = Color(.sRGB, red: 0.9490, green: 0.9647, blue: 0.9843, opacity: 1.0)
        /// atmospheric radial wash behind the visualization; center (50%, 32%), fades to 0 at radius 55% of window width
        static let bgDeep = Color(.sRGB, red: 0.1176, green: 0.2471, blue: 0.4000, opacity: 0.18)
        /// transcript text, titles
        static let inkPrimary = Color(.sRGB, red: 0.1412, green: 0.2118, blue: 0.3020, opacity: 1.0)
        /// labels, timestamps, hints
        static let inkSecondary = Color(.sRGB, red: 0.3569, green: 0.4314, blue: 0.5255, opacity: 1.0)
        /// placeholders, disabled
        static let inkTertiary = Color(.sRGB, red: 0.5412, green: 0.6078, blue: 0.6902, opacity: 1.0)
        /// text on accent button
        static let inkInverse = Color(.sRGB, red: 0.9569, green: 0.9725, blue: 0.9882, opacity: 1.0)
        /// primary action, active toggle, focus ring, links
        static let accentBase = Color(.sRGB, red: 0.2902, green: 0.5451, blue: 0.8392, opacity: 1.0)
        /// speaking pillar body
        static let accentSoft = Color(.sRGB, red: 0.6118, green: 0.7686, blue: 0.9176, opacity: 1.0)
        /// idle pillar body, selection tint
        static let accentPale = Color(.sRGB, red: 0.8392, green: 0.9020, blue: 0.9686, opacity: 1.0)
        /// non-speaking pillar fill
        static let pillarIdle = Color(.sRGB, red: 0.1412, green: 0.2118, blue: 0.3020, opacity: 0.1)
        /// speaking pillar gradient top
        static let pillarGlassFillTop = Color(.sRGB, red: 0.7255, green: 0.8431, blue: 0.9529, opacity: 0.78)
        /// speaking pillar gradient bottom
        static let pillarGlassFillBottom = Color(.sRGB, red: 0.5608, green: 0.7373, blue: 0.9137, opacity: 0.62)
        /// inner stroke, top 40% of pillar
        static let pillarGlassHighlight = Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.55)
        /// outer refraction edge
        static let pillarGlassEdge = Color(.sRGB, red: 0.4353, green: 0.6510, blue: 0.8745, opacity: 0.35)
        /// search/text inputs
        static let fieldBg = Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.5)
        static let fieldBorder = Color(.sRGB, red: 0.1412, green: 0.2118, blue: 0.3020, opacity: 0.1)
        /// row separators
        static let lineHairline = Color(.sRGB, red: 0.1412, green: 0.2118, blue: 0.3020, opacity: 0.08)
        /// delete, mic/model errors
        static let stateDanger = Color(.sRGB, red: 0.7608, green: 0.3294, blue: 0.2902, opacity: 1.0)
        /// dictionary 'looks common' warning
        static let stateWarning = Color(.sRGB, red: 0.7176, green: 0.4745, blue: 0.1216, opacity: 1.0)
        /// listening indicator (pulses)
        static let stateRecording = Color(.sRGB, red: 0.2902, green: 0.5451, blue: 0.8392, opacity: 1.0)
    }
    enum TypeScale {
        static let caption = TextStyle(size: 11, line: 14, weight: .regular, tracking: 0, design: .default)
        static let body = TextStyle(size: 13, line: 18, weight: .regular, tracking: 0, design: .default)
        static let transcript = TextStyle(size: 15, line: 22, weight: .regular, tracking: 0, design: .default)
        static let status = TextStyle(size: 15, line: 20, weight: .medium, tracking: 0.3, design: .default)
        static let title = TextStyle(size: 20, line: 26, weight: .medium, tracking: -0.2, design: .default)
        static let mono = TextStyle(size: 12, line: 16, weight: .regular, tracking: 0, design: .monospaced)
    }
    enum Space {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 24
        static let s6: CGFloat = 32
        static let s7: CGFloat = 48
        static let s8: CGFloat = 64
    }
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let pill: CGFloat = 999
    }
    enum Border {
        static let hairline: CGFloat = 1
        static let field: CGFloat = 1
        static let focus: CGFloat = 1.5
        static let warning: CGFloat = 1
    }
    enum Shadow {
        static let menu = ShadowStyle(x: 0, y: 2, blur: 8, alpha: 0.08)
        static let glow = ShadowStyle(x: 0, y: 0, blur: 14, alpha: 0.22)
    }
    enum Motion {
        static let fast: Double = 0.12
        static let base: Double = 0.2
        static let slow: Double = 0.32
        static let levelAttack: Double = 0.06
        static let levelRelease: Double = 0.22
        static let pillarSpring = Animation.spring(response: 0.28, dampingFraction: 0.85)
        /// Time constant for the per-frame Canvas lerp (same feel as the spring, used when we step manually).
        static let pillarSpringLerp: Double = 0.12
        static let statusPulse: Double = 1.6
        static let statusPulseMin: Double = 0.55
        static let statusPulseMax: Double = 1.0
        static let easeStandard = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.2)
        static let easeEnter = Animation.timingCurve(0, 0, 0.2, 1, duration: 0.2)
        static let easeExit = Animation.timingCurve(0.4, 0, 1, 1, duration: 0.2)
    }
    enum Pillar {
        static let count = 21
        static let width: CGFloat = 6
        static let gap: CGFloat = 6
        static let minHeight: CGFloat = 8
        static let maxHeight: CGFloat = 120
        static let envelopeFloor: Double = 0.15
        static let jitter: Double = 0.06
        static let speakingThreshold: Double = 0.06
        static let idleLevel: Double = 0.12
        static let highlightWidth: CGFloat = 1
        static let highlightCoverage: CGFloat = 0.4
        static let edgeWidth: CGFloat = 0.5
    }
    enum Bg {
        static let deepCenter = UnitPoint(x: 0.5, y: 0.32)
        static let deepRadius: CGFloat = 0.55
    }
    enum Layout {
        static let windowMinWidth: CGFloat = 560
        static let windowMinHeight: CGFloat = 640
        static let windowDefaultWidth: CGFloat = 640
        static let windowDefaultHeight: CGFloat = 760
        static let settingsWidth: CGFloat = 460
        static let settingsHeight: CGFloat = 360
    }
    enum Comp {
        static let fieldPaddingH: CGFloat = 10
        static let fieldPaddingV: CGFloat = 6
        static let pillHeight: CGFloat = 36
        static let checkSize: CGFloat = 16
        static let chipPaddingH: CGFloat = 8
        static let chipPaddingV: CGFloat = 2
        static let scrollbarWidth: CGFloat = 6
        static let pillarsAreaHeight: CGFloat = 160
        static let iconSize: CGFloat = 14
        static let pillMinWidth: CGFloat = 120
        static let tabGap: CGFloat = 24
        static let trayMenuMinWidth: CGFloat = 180
        static let settingsLabelWidth: CGFloat = 120
    }
    static let biasMaxTerms = 40
}

struct TextStyle {
    let size: CGFloat; let line: CGFloat; let weight: Font.Weight; let tracking: CGFloat; let design: Font.Design
    var font: Font { .system(size: size, weight: weight, design: design) }
    var lineSpacing: CGFloat { max(0, line - size * 1.2) }
}

struct ShadowStyle { let x: CGFloat; let y: CGFloat; let blur: CGFloat; let alpha: Double }

extension View {
    /// Applies a type token: font, tracking and line spacing together.
    func textStyle(_ s: TextStyle) -> some View { self.font(s.font).tracking(s.tracking).lineSpacing(s.lineSpacing) }
}
