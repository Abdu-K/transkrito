import SwiftUI

// Component styles. Every value here is a token reference; nothing is literal.

/// The single primary action (Start / Stop).
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Tokens.TypeScale.body)
            .fontWeight(Tokens.TypeScale.status.weight)
            .foregroundStyle(Tokens.Colors.inkInverse)
            .frame(minWidth: Tokens.Comp.pillMinWidth, minHeight: Tokens.Comp.pillHeight)
            .padding(.horizontal, Tokens.Space.s5)
            .background(Tokens.Colors.accentBase, in: Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(Tokens.Motion.easeStandard, value: configuration.isPressed)
    }
}

/// Secondary actions: copy, edit, delete, settings. `danger` turns red on hover.
struct TextLinkButtonStyle: ButtonStyle {
    var danger = false
    var accent = false

    func makeBody(configuration: Configuration) -> some View {
        TextLinkLabel(configuration: configuration, danger: danger, accent: accent)
    }

    /// Hover state needs view identity, so it lives in a real View rather than the style.
    private struct TextLinkLabel: View {
        let configuration: Configuration
        let danger: Bool
        let accent: Bool
        @State private var hover = false

        var body: some View {
            configuration.label
                .textStyle(accent ? Tokens.TypeScale.body : Tokens.TypeScale.caption)
                .foregroundStyle(color)
                .padding(Tokens.Space.s1)
                .contentShape(Rectangle())
                .onHover { hover = $0 }
                .opacity(configuration.isPressed ? 0.7 : 1)
        }

        private var color: Color {
            if hover { return danger ? Tokens.Colors.stateDanger : Tokens.Colors.accentBase }
            return accent ? Tokens.Colors.accentBase : Tokens.Colors.inkSecondary
        }
    }
}

/// History | Dictionary. Active = accent + 1pt underline.
struct TextToggle<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var small = false

    var body: some View {
        HStack(spacing: small ? Tokens.Space.s3 : Tokens.Comp.tabGap) {
            ForEach(options, id: \.0) { option in
                let (value, label) = option
                let active = value == selection
                Button { selection = value } label: {
                    VStack(spacing: Tokens.Space.s1) {
                        Text(label)
                            .textStyle(small ? Tokens.TypeScale.caption : Tokens.TypeScale.body)
                            .foregroundStyle(active ? Tokens.Colors.accentBase : Tokens.Colors.inkSecondary)
                        Rectangle()
                            .fill(Tokens.Colors.accentBase)
                            .frame(height: Tokens.Border.hairline)
                            .opacity(active ? 1 : 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(Tokens.Motion.easeStandard, value: active)
            }
        }
    }
}

/// Flat field: search and text inputs. Apply with `.field()` on a TextField.
struct FieldModifier: ViewModifier {
    var warning = false
    @FocusState private var focused: Bool

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .textStyle(Tokens.TypeScale.body)
            .foregroundStyle(Tokens.Colors.inkPrimary)
            .focused($focused)
            .padding(.horizontal, Tokens.Comp.fieldPaddingH)
            .padding(.vertical, Tokens.Comp.fieldPaddingV)
            .background(Tokens.Colors.fieldBg, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md)
                    .stroke(borderColor, lineWidth: focused ? Tokens.Border.focus : Tokens.Border.field)
            )
            .animation(Tokens.Motion.easeStandard, value: focused)
    }

    private var borderColor: Color {
        if focused { return Tokens.Colors.accentBase.opacity(0.6) }
        return warning ? Tokens.Colors.stateWarning.opacity(0.5) : Tokens.Colors.fieldBorder
    }
}

extension View {
    func field(warning: Bool = false) -> some View { modifier(FieldModifier(warning: warning)) }
}

/// "N corrections" chip that toggles the detail list.
struct Chip: View {
    let label: String
    @Binding var isOn: Bool
    @State private var hover = false

    var body: some View {
        Button { isOn.toggle() } label: {
            Text(label)
                .textStyle(Tokens.TypeScale.caption)
                .foregroundStyle(isOn || hover ? Tokens.Colors.accentBase : Tokens.Colors.inkSecondary)
                .padding(.horizontal, Tokens.Comp.chipPaddingH)
                .padding(.vertical, Tokens.Comp.chipPaddingV)
                .background(Tokens.Colors.accentPale, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle().fill(Tokens.Colors.lineHairline).frame(height: Tokens.Border.hairline)
    }
}

/// Window atmosphere: icy gradient plus the deep-blue wash behind the visualization (bg.deep token).
struct WindowBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Tokens.Colors.bgTop, Tokens.Colors.bgBottom], startPoint: .top, endPoint: .bottom)
            GeometryReader { geo in
                RadialGradient(colors: [Tokens.Colors.bgDeep, .clear], center: Tokens.Bg.deepCenter,
                               startRadius: 0, endRadius: geo.size.width * Tokens.Bg.deepRadius)
            }
        }
        .ignoresSafeArea()
    }
}
