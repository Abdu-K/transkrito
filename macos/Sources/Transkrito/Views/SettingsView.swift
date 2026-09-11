import AppKit
import SwiftUI

/// ⌘, — Hotkey, Model (language + on-device asset), Insert at cursor, Files.
struct SettingsView: View {
    @Environment(AppController.self) private var app
    @State private var locales: [Locale] = []

    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: Tokens.Space.s5, verticalSpacing: Tokens.Space.s5) {
            GridRow {
                label("Hotkey")
                VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                    HotkeyRecorder()
                    Text("Press to start listening, press again to stop. Esc cancels.")
                        .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                    if let err = app.hotkeyError {
                        Text(err).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
                    }
                }
            }
            GridRow {
                label("Model")
                VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                    Picker("", selection: Binding(
                        get: { app.settings.model },
                        set: { id in Task { await app.setModel(id) } }
                    )) {
                        ForEach(localeChoices, id: \.0) { choice in Text(choice.1).tag(choice.0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .textStyle(Tokens.TypeScale.body)
                    assetRow
                    Text(app.engine.biasStatus).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                }
            }
            GridRow {
                label("After transcribing")
                VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                    Toggle("Insert at cursor in the app I was using", isOn: Binding(
                        get: { app.settings.insertAtCursor },
                        set: { app.setInsertAtCursor($0) }
                    ))
                    .toggleStyle(.checkbox)
                    .textStyle(Tokens.TypeScale.body)
                    .tint(Tokens.Colors.accentBase)
                    Text("Text is always copied to the clipboard. Inserting needs Accessibility access (asked once).")
                        .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                }
            }
            GridRow {
                label("Files")
                VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                    Text("Dictionary, history and settings are plain JSON you can edit by hand.")
                        .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                    HStack(spacing: Tokens.Space.s3) {
                        Button("Open folder") { NSWorkspace.shared.open(AppPaths.dataDir) }
                            .buttonStyle(TextLinkButtonStyle(accent: true))
                        Text(AppPaths.dataDir.path).textStyle(Tokens.TypeScale.mono).foregroundStyle(Tokens.Colors.inkTertiary)
                            .lineLimit(1).truncationMode(.middle)
                    }
                }
            }
        }
        .padding(Tokens.Space.s6)
        .frame(width: Tokens.Layout.settingsWidth)
        .background(Tokens.Colors.bgBottom.ignoresSafeArea())
        .task {
            locales = await SpeechEngine.supportedLocales
            await app.engine.refreshAssetState()
        }
    }

    private func label(_ s: String) -> some View {
        Text(s).textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkSecondary)
            .frame(minWidth: Tokens.Comp.settingsLabelWidth, alignment: .leading)
            .padding(.vertical, Tokens.Comp.fieldPaddingV)
    }

    private var localeChoices: [(String, String)] {
        var list = locales.map { ($0.identifier.replacingOccurrences(of: "_", with: "-"), Locale.current.localizedString(forIdentifier: $0.identifier) ?? $0.identifier) }
            .sorted { $0.1 < $1.1 }
        if !list.contains(where: { $0.0 == app.settings.model }) { list.insert((app.settings.model, app.settings.model), at: 0) }
        return list
    }

    @ViewBuilder private var assetRow: some View {
        HStack(spacing: Tokens.Space.s3) {
            switch app.engine.assetState {
            case .installed:
                Text("Downloaded \u{00B7} on-device").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
            case .notInstalled:
                Text("Not downloaded").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                Button("Download") { Task { await app.engine.installAsset(); await app.loadModel() } }
                    .buttonStyle(TextLinkButtonStyle(accent: true))
            case .downloading(let p):
                Text("Downloading \(Int(p * 100))%").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
            case .unsupported:
                Text("Not supported by Apple Speech").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
            case .unknown:
                Text("Checking\u{2026}").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkTertiary)
            }
        }
        if case .downloading(let p) = app.engine.assetState {
            GeometryReader { g in
                Rectangle().fill(Tokens.Colors.accentBase).frame(width: max(0, g.size.width * p))
            }
            .frame(height: Tokens.Border.focus)
        }
        if let err = app.engine.lastError {
            Text(err).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
        }
    }
}

/// Click, then press a combination. Esc cancels. Uses a local key monitor while focused.
struct HotkeyRecorder: View {
    @Environment(AppController.self) private var app
    @State private var recording = false
    @State private var monitor: Any?
    @State private var hint: String?

    var body: some View {
        Button {
            recording ? stop() : start()
        } label: {
            HStack {
                Text(recording ? (hint ?? "Press a combination\u{2026}") : app.settings.hotkey.display)
                    .textStyle(Tokens.TypeScale.body)
                    .foregroundStyle(recording ? Tokens.Colors.inkTertiary : Tokens.Colors.inkPrimary)
                Spacer()
            }
            .padding(.horizontal, Tokens.Comp.fieldPaddingH)
            .padding(.vertical, Tokens.Comp.fieldPaddingV)
            .background(Tokens.Colors.fieldBg, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.md)
                .stroke(recording ? Tokens.Colors.accentBase.opacity(0.6) : Tokens.Colors.fieldBorder,
                        lineWidth: recording ? Tokens.Border.focus : Tokens.Border.field))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onDisappear { stop() }
    }

    private func start() {
        recording = true
        hint = nil
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil
        }
    }

    private func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
        recording = false
    }

    private func handle(_ event: NSEvent) {
        if event.keyCode == 53 { stop(); return } // Esc
        guard let key = HotkeySetting.keyName(forCode: event.keyCode) else { hint = "That key is not supported."; return }
        var mods: [String] = []
        let f = event.modifierFlags
        if f.contains(.control) { mods.append("control") }
        if f.contains(.option) { mods.append("option") }
        if f.contains(.shift) { mods.append("shift") }
        if f.contains(.command) { mods.append("command") }
        if mods.isEmpty && !key.hasPrefix("F") {
            hint = "Add a modifier (\u{2303} \u{2325} \u{21E7} \u{2318}), or use a function key."
            return
        }
        app.applyHotkey(HotkeySetting(key: key, modifiers: mods))
        stop()
    }
}
