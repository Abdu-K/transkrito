import SwiftUI

// Component styles for the navy/glass world. Every value is a token reference; nothing is literal.

/// Rail navigation item: SF Symbol + label; active = accent.pale fill + ice icon.
struct RailItem: View {
    let title: String
    let symbol: String
    let active: Bool
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Comp.railIconGap) {
                Image(systemName: symbol)
                    .font(.system(size: Tokens.Comp.iconSize, weight: .medium))
                    .foregroundStyle(active ? Tokens.Colors.accentIce : Tokens.Colors.inkSecondary)
                    .frame(width: Tokens.Comp.iconSize)
                Text(title)
                    .textStyle(Tokens.TypeScale.body)
                    .foregroundStyle(active || hover ? Tokens.Colors.inkPrimary : Tokens.Colors.inkSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Tokens.Comp.fieldPaddingH)
            .frame(height: Tokens.Comp.navItemHeight)
            .background(active ? Tokens.Colors.accentPale : hover ? Tokens.Colors.surfaceGlass1 : .clear,
                        in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .animation(Tokens.Motion.easeStandard, value: hover)
    }
}

/// Round glass mic. Press-and-hold in hold mode, click in toggle mode. Listening = ice glow.
struct MicButton: View {
    @Environment(AppController.self) private var app
    @State private var hover = false
    @State private var held = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Tokens.Colors.accentIce)
                .blur(radius: Tokens.Shadow.glow.blur / 2)
                .opacity(app.isListening ? Tokens.Shadow.glow.alpha : 0)
                .padding(-Tokens.Space.s2)
            Circle()
                .fill(app.isListening ? Tokens.Colors.accentBase : held ? Tokens.Colors.accentStrong : Tokens.Colors.surfaceGlass3)
                .overlay(Circle().stroke(app.isListening ? Tokens.Colors.accentIce : hover ? Tokens.Colors.lineGlassStrong : Tokens.Colors.lineGlass2,
                                         lineWidth: Tokens.Border.hairline))
            Image(systemName: "mic.fill")
                .font(.system(size: Tokens.Comp.iconSizeLg, weight: .medium))
                .foregroundStyle(Tokens.Colors.inkPrimary)
        }
        .frame(width: Tokens.Comp.micButton, height: Tokens.Comp.micButton)
        .contentShape(Circle())
        .onHover { hover = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !held { held = true; app.hotkeyDown() } }
                .onEnded { _ in held = false; app.hotkeyUp() }
        )
        .opacity(app.isTranscribing ? 0.4 : 1)
        .disabled(app.isTranscribing)
        .animation(Tokens.Motion.easeStandard, value: app.isListening)
        .help(app.hotkeyHint)
    }
}

/// Glass button with a label (Download, Open folder, Cancel).
struct GlassButtonStyle: ButtonStyle {
    var primary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Tokens.TypeScale.body)
            .fontWeight(primary ? .medium : .regular)
            .foregroundStyle(primary ? Tokens.Colors.inkInverse : Tokens.Colors.inkPrimary)
            .padding(.horizontal, Tokens.Comp.fieldPaddingH)
            .padding(.vertical, Tokens.Comp.fieldPaddingV)
            .background(primary ? (configuration.isPressed ? Tokens.Colors.accentStrong : Tokens.Colors.accentBase)
                        : (configuration.isPressed ? Tokens.Colors.surfaceGlass3 : Tokens.Colors.surfaceGlass1),
                        in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
            .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.sm).stroke(primary ? .clear : Tokens.Colors.lineGlass1, lineWidth: Tokens.Border.hairline))
    }
}

/// Row actions: an SF Symbol on a hover-tinted square.
struct IconButton: View {
    let symbol: String
    let help: String
    var danger = false
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Tokens.Comp.iconSizeMd, weight: .medium))
                .foregroundStyle(hover ? (danger ? Tokens.Colors.stateDanger : Tokens.Colors.inkPrimary) : Tokens.Colors.inkSecondary)
                .padding(Tokens.Space.s2)
                .background(hover ? Tokens.Colors.surfaceGlass2 : .clear, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help(help)
    }
}

/// Text link (Cancel, Remove).
struct TextLinkButtonStyle: ButtonStyle {
    var danger = false
    var accent = false
    func makeBody(configuration: Configuration) -> some View {
        TextLinkLabel(configuration: configuration, danger: danger, accent: accent)
    }
    private struct TextLinkLabel: View {
        let configuration: Configuration
        let danger: Bool
        let accent: Bool
        @State private var hover = false
        var body: some View {
            configuration.label
                .textStyle(accent ? Tokens.TypeScale.body : Tokens.TypeScale.caption)
                .foregroundStyle(hover ? (danger ? Tokens.Colors.stateDanger : Tokens.Colors.accentIce) : (accent ? Tokens.Colors.accentIce : Tokens.Colors.inkSecondary))
                .padding(Tokens.Space.s1)
                .contentShape(Rectangle())
                .onHover { hover = $0 }
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}

/// Segmented text toggle (filters, hold/toggle switch).
struct Segmented<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { option in
                let (value, label) = option
                let active = value == selection
                Button { selection = value } label: {
                    Text(label)
                        .textStyle(Tokens.TypeScale.body)
                        .foregroundStyle(active ? Tokens.Colors.inkPrimary : Tokens.Colors.inkSecondary)
                        .padding(.horizontal, Tokens.Comp.fieldPaddingH)
                        .padding(.vertical, Tokens.Comp.fieldPaddingV)
                        .background(active ? Tokens.Colors.surfaceGlass2 : .clear, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Tokens.Space.s1)
        .background(Tokens.Colors.surfaceGlass1, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.md).stroke(Tokens.Colors.lineGlass1, lineWidth: Tokens.Border.hairline))
        .animation(Tokens.Motion.easeStandard, value: selection)
    }
}

/// Glass field. Apply with `.field(icon:warning:)` on a TextField.
struct FieldModifier: ViewModifier {
    var icon: String? = nil
    var warning = false
    @FocusState private var focused: Bool

    func body(content: Content) -> some View {
        HStack(spacing: Tokens.Space.s2) {
            if let icon {
                Image(systemName: icon).font(.system(size: Tokens.Comp.iconSizeMd)).foregroundStyle(Tokens.Colors.inkTertiary)
            }
            content
                .textFieldStyle(.plain)
                .textStyle(Tokens.TypeScale.body)
                .foregroundStyle(Tokens.Colors.inkPrimary)
                .focused($focused)
        }
        .padding(.horizontal, Tokens.Comp.fieldPaddingH)
        .padding(.vertical, Tokens.Comp.fieldPaddingV)
        .background(focused ? Tokens.Colors.surfaceGlass2 : Tokens.Colors.fieldBg, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.md).stroke(borderColor, lineWidth: Tokens.Border.hairline))
        .animation(Tokens.Motion.easeStandard, value: focused)
    }

    private var borderColor: Color {
        if focused { return Tokens.Colors.accentBase }
        return warning ? Tokens.Colors.stateWarning.opacity(0.6) : Tokens.Colors.fieldBorder
    }
}

extension View {
    func field(icon: String? = nil, warning: Bool = false) -> some View { modifier(FieldModifier(icon: icon, warning: warning)) }
}

/// "N corrections" chip that toggles the detail list.
struct Chip: View {
    let label: String
    @Binding var isOn: Bool
    @State private var hover = false

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: Tokens.Space.s1) {
                Text(label).textStyle(Tokens.TypeScale.caption)
                Image(systemName: "chevron.down").font(.system(size: Tokens.Comp.iconSizeSm * 0.8, weight: .semibold))
                    .rotationEffect(.degrees(isOn ? 180 : 0))
            }
            .foregroundStyle(Tokens.Colors.accentIce)
            .padding(.horizontal, Tokens.Comp.chipPaddingH)
            .padding(.vertical, Tokens.Comp.chipPaddingV)
            .background(hover ? Tokens.Colors.surfaceGlass2 : Tokens.Colors.accentPale, in: Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .animation(Tokens.Motion.easeStandard, value: isOn)
    }
}

/// The hotkey drawn as key caps.
struct KeyCaps: View {
    @Environment(AppController.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
            if let err = app.hotkeyError {
                Text(err).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
            } else {
                HStack(spacing: Tokens.Space.s1) {
                    ForEach(Array(caps.enumerated()), id: \.offset) { _, cap in
                        Text(cap)
                            .textStyle(Tokens.TypeScale.mono)
                            .foregroundStyle(Tokens.Colors.inkPrimary)
                            .padding(.horizontal, Tokens.Comp.chipPaddingH)
                            .padding(.vertical, Tokens.Comp.chipPaddingV)
                            .background(Tokens.Colors.surfaceGlass1, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
                            .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.sm).stroke(Tokens.Colors.lineGlass2, lineWidth: Tokens.Border.hairline))
                    }
                }
                Text(app.hotkeyHint).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkTertiary)
            }
        }
    }

    /// Modifier glyphs each get a cap, then the key.
    private var caps: [String] {
        let hk = app.settings.hotkey
        var list = hk.modifiers.compactMap { m -> String? in
            switch m { case "control": return "\u{2303}"; case "option": return "\u{2325}"; case "shift": return "\u{21E7}"; case "command": return "\u{2318}"; default: return nil }
        }
        list.append(hk.key == "Space" ? "Space" : hk.key.uppercased())
        return list
    }
}

struct Hairline: View {
    var body: some View { Rectangle().fill(Tokens.Colors.lineGlass1).frame(height: Tokens.Border.hairline) }
}

/// Window atmosphere: navy gradient; the icy wash behind the visualization is added by the Dictation page.
struct WindowBackground: View {
    var body: some View {
        LinearGradient(colors: [Tokens.Colors.bgTop, Tokens.Colors.bgBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct DeepWash: View {
    var body: some View {
        GeometryReader { geo in
            RadialGradient(colors: [Tokens.Colors.bgDeep, .clear], center: Tokens.Bg.deepCenter,
                           startRadius: 0, endRadius: geo.size.width * Tokens.Bg.deepRadius)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
