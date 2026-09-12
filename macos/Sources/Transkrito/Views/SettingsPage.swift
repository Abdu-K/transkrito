import AppKit
import SwiftUI

/// Hotkey + mode, microphone, model (language + on-device asset), insert at cursor, files.
struct SettingsPage: View {
    @Environment(AppController.self) private var app
    @State private var devices: [InputDevice] = [.systemDefault]

    private static let languages: [(String, String)] = [
        (Lang.auto, "Auto \u{2014} Recommended"), (Lang.en, Lang.display(Lang.en)), (Lang.de, Lang.display(Lang.de)), (Lang.ar, Lang.display(Lang.ar)),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.s5) {
                Text("Settings").textStyle(Tokens.TypeScale.title).foregroundStyle(Tokens.Colors.inkPrimary)

                Grid(alignment: .topLeading, horizontalSpacing: Tokens.Space.s5, verticalSpacing: Tokens.Space.s5) {
                    GridRow {
                        label("Hotkey")
                        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                            HotkeyRecorder()
                            Text("Works in any app. Esc cancels.").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                            if let err = app.hotkeyError {
                                Text(err).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
                            }
                            Segmented(options: [(true, "Hold to talk"), (false, "Press to toggle")],
                                      selection: Binding(get: { app.holdToTalk }, set: { app.holdToTalk = $0 }))
                                .padding(.top, Tokens.Space.s1)
                            Text(app.holdToTalk ? "Hold the keys while you speak; let go and the text is pasted." : "Press once to start, press again to stop.")
                                .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                        }
                    }
                    GridRow {
                        label("Microphone")
                        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                            Picker("", selection: Binding(get: { app.inputDevice }, set: { app.inputDevice = $0 })) {
                                ForEach(deviceChoices) { d in Text(d.name).tag(d.uid) }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .tint(Tokens.Colors.accentBase)
                            Text("Any input works; audio is converted for the model.").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                        }
                    }
                    GridRow {
                        label("Language")
                        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                            Picker("", selection: Binding(get: { app.language }, set: { app.language = $0 })) {
                                ForEach(Self.languages, id: \.0) { choice in Text(choice.1).tag(choice.0) }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .tint(Tokens.Colors.accentBase)
                            Text(app.languageHint).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                        }
                    }
                    GridRow {
                        label("Speech models")
                        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                            ForEach(Lang.supported, id: \.self) { l in appleRow(l) }
                            sherpaRow(SherpaCatalog.languageID, purpose: "Language detector for Auto", needed: app.language == Lang.auto)
                            if app.arabicFallback || SherpaCatalog.nemotron.isInstalled {
                                sherpaRow(SherpaCatalog.nemotron, purpose: "Arabic fallback (Apple has no Arabic asset here)", needed: app.arabicFallback)
                            }
                            Text(app.engine.biasStatus).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                            if let err = app.engine.lastError {
                                Text(err).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
                            }
                        }
                    }
                    GridRow {
                        label("After transcribing")
                        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                            Toggle("Insert at the cursor in the app I was using", isOn: Binding(get: { app.settings.insertAtCursor }, set: { app.setInsertAtCursor($0) }))
                                .toggleStyle(.checkbox)
                                .textStyle(Tokens.TypeScale.body)
                                .foregroundStyle(Tokens.Colors.inkPrimary)
                                .tint(Tokens.Colors.accentBase)
                            Text("Text is always copied to the clipboard as well. Inserting needs Accessibility access (asked once).")
                                .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                        }
                    }
                    GridRow {
                        label("Files")
                        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                            Text("Dictionary, history and settings are plain JSON you can edit by hand. The app picks up changes immediately.")
                                .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                            HStack(spacing: Tokens.Space.s3) {
                                Button { NSWorkspace.shared.open(AppPaths.dataDir) } label: {
                                    Label("Open folder", systemImage: "folder")
                                }
                                .buttonStyle(GlassButtonStyle())
                                Text(AppPaths.dataDir.path).textStyle(Tokens.TypeScale.mono).foregroundStyle(Tokens.Colors.inkTertiary)
                                    .lineLimit(1).truncationMode(.middle)
                            }
                        }
                    }
                }
            }
            .padding(Tokens.Space.s6)
            .frame(maxWidth: Tokens.Layout.contentMaxWidth, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            devices = AudioCapture.devices()
            await app.engine.refreshAllAssetStates()
        }
    }

    private func label(_ s: String) -> some View {
        Text(s).textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkSecondary)
            .frame(minWidth: Tokens.Comp.settingsLabelWidth, alignment: .leading)
            .padding(.vertical, Tokens.Comp.fieldPaddingV)
    }

    private var deviceChoices: [InputDevice] {
        var list = devices
        if !list.contains(where: { $0.uid == app.inputDevice }) { list.append(InputDevice(uid: app.inputDevice, name: "Unplugged device")) }
        return list
    }

    /// One Apple Speech language: state + Download. Arabic that Apple cannot provide says so and points at the fallback.
    @ViewBuilder private func appleRow(_ l: String) -> some View {
        HStack(spacing: Tokens.Space.s3) {
            Text(Lang.display(l)).textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkPrimary)
                .frame(width: Tokens.Comp.timeColumn, alignment: .leading)
            switch app.engine.assetState(for: l) {
            case .installed:
                Text("Apple Speech \u{00B7} on this Mac").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
            case .notInstalled:
                Text("Not downloaded").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                Button { Task { await app.engine.installAsset(for: l); await app.loadModel() } } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
                .buttonStyle(GlassButtonStyle())
            case .downloading(let p):
                Text("Downloading \(Int(p * 100))%").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
            case .unsupported:
                Text(l == Lang.ar ? "Apple Speech unavailable \u{2014} uses the local multilingual model" : "Not supported by Apple Speech on this Mac")
                    .textStyle(Tokens.TypeScale.caption).foregroundStyle(l == Lang.ar ? Tokens.Colors.inkSecondary : Tokens.Colors.stateDanger)
            case .unknown:
                Text("Checking\u{2026}").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkTertiary)
            }
        }
    }

    /// One sherpa-onnx model: state, progress, Download.
    @ViewBuilder private func sherpaRow(_ m: SherpaModel, purpose: String, needed: Bool) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
            HStack(spacing: Tokens.Space.s3) {
                Text(m.name).textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkPrimary)
                if let p = app.sherpaProgress[m.id] {
                    Text(p < 0 ? "Unpacking\u{2026}" : "Downloading \(Int(p * 100))%").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                } else if m.isInstalled {
                    Text("Downloaded \u{00B7} on this Mac").textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                } else {
                    Text("Not downloaded (about \(m.approxMB) MB)").textStyle(Tokens.TypeScale.caption).foregroundStyle(needed ? Tokens.Colors.stateWarning : Tokens.Colors.inkSecondary)
                    Button { Task { await app.downloadSherpa(m, label: m.name.lowercased()); await app.loadModel() } } label: {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
            Text(purpose).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkTertiary)
            if let p = app.sherpaProgress[m.id], p >= 0 {
                GeometryReader { g in
                    Capsule().fill(Tokens.Colors.lineGlass1)
                    Capsule().fill(Tokens.Colors.accentIce).frame(width: max(0, g.size.width * p))
                }
                .frame(height: Tokens.Border.focus)
            }
        }
    }
}

/// Click, then press a combination. Esc cancels. Uses a local key monitor while recording.
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
            .background(recording ? Tokens.Colors.surfaceGlass2 : Tokens.Colors.fieldBg, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.md)
                .stroke(recording ? Tokens.Colors.accentBase : Tokens.Colors.fieldBorder, lineWidth: Tokens.Border.hairline))
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
