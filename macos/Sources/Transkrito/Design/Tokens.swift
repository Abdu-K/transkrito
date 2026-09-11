// GENERATED from design/tokens.json by design/gen-tokens.py. Do not edit by hand.
import SwiftUI

/// Design tokens. Every view pulls from here; no literal values in views.
enum Tokens {
    enum Colors {
        /// window gradient start (top) — blue.900 Midnight
        static let bgTop = Color(.sRGB, red: 0.0431, green: 0.1176, blue: 0.2392, opacity: 1.0)
        /// window gradient end (bottom) — blue.950 Deep Navy
        static let bgBottom = Color(.sRGB, red: 0.0196, green: 0.0392, blue: 0.0784, opacity: 1.0)
        /// icy wash behind the pillars; center (50%, 28%), fades to 0 at radius 55% of content width
        static let bgDeep = Color(.sRGB, red: 0.4902, green: 0.8275, blue: 0.9882, opacity: 0.14)
        /// sidebar rail fill over the gradient
        static let bgRail = Color(.sRGB, red: 0.0196, green: 0.0392, blue: 0.0784, opacity: 0.55)
        /// transcript text, titles — ice.100
        static let inkPrimary = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.92)
        /// labels, timestamps, hints
        static let inkSecondary = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.64)
        /// placeholders, disabled, day headers
        static let inkTertiary = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.4)
        /// text on accent
        static let inkInverse = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 1.0)
        /// primary action, active nav, focus, links — blue.500 Sky
        static let accentBase = Color(.sRGB, red: 0.2314, green: 0.5098, blue: 0.9647, opacity: 1.0)
        /// pressed, pillar core — blue.700 Cobalt
        static let accentStrong = Color(.sRGB, red: 0.1098, green: 0.3059, blue: 0.8471, opacity: 1.0)
        /// recording state, glow, highlights — ice.300
        static let accentIce = Color(.sRGB, red: 0.4902, green: 0.8275, blue: 0.9882, opacity: 1.0)
        /// selection tint, chip fill, active nav fill
        static let accentPale = Color(.sRGB, red: 0.2314, green: 0.5098, blue: 0.9647, opacity: 0.18)
        /// glass fill: fields, hovered rows, secondary buttons
        static let surfaceGlass1 = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.06)
        /// glass fill: raised (popovers, pressed)
        static let surfaceGlass2 = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.1)
        /// glass fill: strong (mic button rest)
        static let surfaceGlass3 = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.16)
        /// border.glass.1 — hairlines, field edges
        static let lineGlass1 = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.1)
        /// border.glass.2 — hovered / raised edges
        static let lineGlass2 = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.2)
        /// border.glass.strong — focused / active edges
        static let lineGlassStrong = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.4)
        /// resting pillar fill
        static let pillarIdle = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.18)
        /// speaking pillar gradient top — ice
        static let pillarGlassFillTop = Color(.sRGB, red: 0.4902, green: 0.8275, blue: 0.9882, opacity: 0.95)
        /// speaking pillar gradient bottom — cobalt
        static let pillarGlassFillBottom = Color(.sRGB, red: 0.1098, green: 0.3059, blue: 0.8471, opacity: 0.95)
        /// inner highlight stroke, top 40% of pillar, left edge
        static let pillarGlassHighlight = Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.7)
        /// outer refraction edge
        static let pillarGlassEdge = Color(.sRGB, red: 0.4902, green: 0.8275, blue: 0.9882, opacity: 0.45)
        static let fieldBg = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.06)
        static let fieldBorder = Color(.sRGB, red: 0.9412, green: 0.9725, blue: 1.0000, opacity: 0.1)
        /// delete, errors
        static let stateDanger = Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0)
        /// dictionary 'looks common' warning
        static let stateWarning = Color(.sRGB, red: 0.9843, green: 0.7490, blue: 0.1412, opacity: 1.0)
        /// listening indicator
        static let stateRecording = Color(.sRGB, red: 0.4902, green: 0.8275, blue: 0.9882, opacity: 1.0)
        /// copied confirmation
        static let stateSuccess = Color(.sRGB, red: 0.4902, green: 0.8275, blue: 0.9882, opacity: 1.0)
    }
    enum TypeScale {
        static let caption = TextStyle(size: 12, line: 16, weight: .regular, tracking: 0, design: .default)
        static let body = TextStyle(size: 13, line: 18, weight: .regular, tracking: 0, design: .default)
        static let transcript = TextStyle(size: 15, line: 22, weight: .regular, tracking: 0, design: .default)
        static let status = TextStyle(size: 14, line: 20, weight: .medium, tracking: 0.2, design: .default)
        static let title = TextStyle(size: 28, line: 34, weight: .medium, tracking: -0.5, design: .default)
        static let mono = TextStyle(size: 12, line: 16, weight: .medium, tracking: 0.4, design: .monospaced)
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
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999
    }
    enum Border {
        static let hairline: CGFloat = 1
        static let field: CGFloat = 1
        static let raised: CGFloat = 1
        static let focus: CGFloat = 1.5
        static let warning: CGFloat = 1
    }
    enum Shadow {
        static let menu = ShadowStyle(x: 0, y: 4, blur: 12, alpha: 0.45)
        static let soft = ShadowStyle(x: 0, y: 1, blur: 2, alpha: 0.3)
        static let glow = ShadowStyle(x: 0, y: 0, blur: 24, alpha: 0.45)
    }
    enum Motion {
        static let fast: Double = 0.15
        static let base: Double = 0.2
        static let slow: Double = 0.3
        static let levelAttack: Double = 0.06
        static let levelRelease: Double = 0.22
        static let pillarSpring = Animation.spring(response: 0.3, dampingFraction: 0.85)
        /// Time constant for the per-frame Canvas lerp (same feel as the spring, used when we step manually).
        static let pillarSpringLerp: Double = 0.12
        static let statusPulse: Double = 1.6
        static let statusPulseMin: Double = 0.55
        static let statusPulseMax: Double = 1.0
        static let breathing: Double = 3.0
        static let breathingAmplitude: Double = 0.05
        static let rowHighlight: Double = 1.6
        static let easeStandard = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.2)
        static let easeEnter = Animation.timingCurve(0, 0, 0.2, 1, duration: 0.2)
        static let easeExit = Animation.timingCurve(0.4, 0, 1, 1, duration: 0.2)
    }
    enum Pillar {
        static let count = 21
        static let width: CGFloat = 8
        static let gap: CGFloat = 7
        static let minHeight: CGFloat = 12
        static let maxHeight: CGFloat = 140
        static let envelopeFloor: Double = 0.15
        static let jitter: Double = 0.06
        static let speakingThreshold: Double = 0.06
        static let idleLevel: Double = 0.3
        static let highlightWidth: CGFloat = 1.5
        static let highlightCoverage: CGFloat = 0.4
        static let edgeWidth: CGFloat = 0.75
    }
    enum Bg {
        static let deepCenter = UnitPoint(x: 0.5, y: 0.28)
        static let deepRadius: CGFloat = 0.55
    }
    enum Layout {
        static let windowMinWidth: CGFloat = 880
        static let windowMinHeight: CGFloat = 600
        static let windowDefaultWidth: CGFloat = 1040
        static let windowDefaultHeight: CGFloat = 720
        static let settingsWidth: CGFloat = 560
        static let settingsHeight: CGFloat = 520
        static let railWidth: CGFloat = 220
        static let contentMaxWidth: CGFloat = 760
    }
    enum Comp {
        static let fieldPaddingH: CGFloat = 12
        static let fieldPaddingV: CGFloat = 8
        static let pillHeight: CGFloat = 36
        static let pillMinWidth: CGFloat = 120
        static let checkSize: CGFloat = 16
        static let chipPaddingH: CGFloat = 8
        static let chipPaddingV: CGFloat = 2
        static let scrollbarWidth: CGFloat = 6
        static let pillarsAreaHeight: CGFloat = 180
        static let iconSize: CGFloat = 16
        static let tabGap: CGFloat = 24
        static let trayMenuMinWidth: CGFloat = 180
        static let settingsLabelWidth: CGFloat = 140
        static let navItemHeight: CGFloat = 36
        static let micButton: CGFloat = 48
        static let railIconGap: CGFloat = 10
        static let iconSizeLg: CGFloat = 20
        static let iconSizeMd: CGFloat = 14
        static let iconSizeSm: CGFloat = 12
        static let iconStroke: CGFloat = 1.75
        static let popupMaxHeight: CGFloat = 280
        static let checkRadius: CGFloat = 4
        static let tickSize: CGFloat = 11
        static let timeColumn: CGFloat = 56
        static let timeBaselineOffset: CGFloat = 3
        static let rowGap: CGFloat = 2
        static let statusDot: CGFloat = 8
        static let dayHeaderTracking: CGFloat = 0.6
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
