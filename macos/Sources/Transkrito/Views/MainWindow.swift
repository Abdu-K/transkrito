import SwiftUI

enum MainTab: Hashable { case history, dictionary }

/// status → pillars → Start pill + hotkey hint → History | Dictionary → content. No sidebar, cards or panels.
struct MainWindow: View {
    @Environment(AppController.self) private var app
    @Environment(\.openSettings) private var openSettings
    @State private var tab: MainTab = .history
    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WindowBackground()

            VStack(spacing: 0) {
                statusText
                PillarsView(level: app.level)
                    .padding(Tokens.Space.s4)

                VStack(spacing: Tokens.Space.s2) {
                    Button(app.actionLabel) { app.toggle() }
                        .buttonStyle(PillButtonStyle())
                        .disabled(app.isTranscribing)
                    Text(app.hotkeyLabel)
                        .textStyle(Tokens.TypeScale.mono)
                        .foregroundStyle(app.hotkeyError == nil ? Tokens.Colors.inkTertiary : Tokens.Colors.stateDanger)
                        .multilineTextAlignment(.center)
                }

                TextToggle(options: [(MainTab.history, "History"), (MainTab.dictionary, "Dictionary")], selection: $tab)
                    .padding(.top, Tokens.Space.s5)
                    .padding(.bottom, Tokens.Space.s3)

                Group {
                    switch tab {
                    case .history: HistoryView()
                    case .dictionary: DictionaryView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(Tokens.Space.s6)

            Button("Settings") { openSettings() }
                .buttonStyle(TextLinkButtonStyle())
                .padding(Tokens.Space.s3)
        }
        .frame(minWidth: Tokens.Layout.windowMinWidth, minHeight: Tokens.Layout.windowMinHeight)
        .task { await app.loadModel() }
    }

    private var statusText: some View {
        Text(app.status)
            .textStyle(Tokens.TypeScale.status)
            .foregroundStyle(app.statusIsError ? Tokens.Colors.stateDanger
                             : app.isListening ? Tokens.Colors.stateRecording : Tokens.Colors.inkSecondary)
            .multilineTextAlignment(.center)
            .opacity(app.isListening ? (pulse ? Tokens.Motion.statusPulseMin : Tokens.Motion.statusPulseMax) : 1)
            .animation(app.isListening
                       ? .easeInOut(duration: Tokens.Motion.statusPulse / 2).repeatForever(autoreverses: true)
                       : Tokens.Motion.easeStandard, value: pulse)
            .onChange(of: app.isListening, initial: true) { _, listening in pulse = listening }
    }
}
