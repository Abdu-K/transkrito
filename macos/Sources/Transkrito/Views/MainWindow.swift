import SwiftUI

enum Page: Hashable { case dictation, dictionary, settings }

/// Shell: rail (wordmark, navigation, status + hotkey) and one of three pages. Mirrors the Windows MainWindow.
struct MainWindow: View {
    @Environment(AppController.self) private var app
    @Binding var page: Page

    var body: some View {
        HStack(spacing: 0) {
            rail
            Rectangle().fill(Tokens.Colors.lineGlass1).frame(width: Tokens.Border.hairline).ignoresSafeArea()
            ZStack {
                if page == .dictation { DeepWash() }
                switch page {
                case .dictation: DictationPage()
                case .dictionary: DictionaryPage()
                case .settings: SettingsPage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(WindowBackground())
        .frame(minWidth: Tokens.Layout.windowMinWidth, minHeight: Tokens.Layout.windowMinHeight)
        .task { await app.loadModel() }
    }

    private var rail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Tokens.Space.s2) {
                Image(systemName: "waveform").font(.system(size: Tokens.Comp.iconSize, weight: .medium)).foregroundStyle(Tokens.Colors.accentIce)
                Text("Transkrito").textStyle(Tokens.TypeScale.body).fontWeight(.medium).foregroundStyle(Tokens.Colors.inkPrimary)
            }
            .padding(.horizontal, Tokens.Comp.fieldPaddingH)
            .padding(.vertical, Tokens.Comp.fieldPaddingV)
            .padding(.top, Tokens.Space.s5) // room under the traffic lights

            VStack(spacing: Tokens.Space.s1) {
                RailItem(title: "Dictation", symbol: "mic", active: page == .dictation) { page = .dictation }
                RailItem(title: "Dictionary", symbol: "book.closed", active: page == .dictionary) { page = .dictionary }
                RailItem(title: "Settings", symbol: "slider.horizontal.3", active: page == .settings) { page = .settings }
            }
            .padding(.top, Tokens.Space.s5)

            Spacer()

            VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                HStack(spacing: Tokens.Space.s2) {
                    Circle().fill(statusColor).frame(width: Tokens.Comp.statusDot, height: Tokens.Comp.statusDot)
                    Text(app.status).textStyle(Tokens.TypeScale.caption).foregroundStyle(statusInk).lineLimit(2)
                }
                KeyCaps()
            }
            .padding(.horizontal, Tokens.Comp.fieldPaddingH)
            .padding(.vertical, Tokens.Comp.fieldPaddingV)
        }
        .padding(Tokens.Space.s4)
        .frame(width: Tokens.Layout.railWidth)
        .frame(maxHeight: .infinity)
        .background(Tokens.Colors.bgRail.ignoresSafeArea())
    }

    private var statusColor: Color {
        if app.statusIsError { return Tokens.Colors.stateDanger }
        if app.isListening { return Tokens.Colors.stateRecording }
        if app.isTranscribing { return Tokens.Colors.accentBase }
        return Tokens.Colors.inkTertiary
    }
    private var statusInk: Color {
        if app.statusIsError { return Tokens.Colors.stateDanger }
        if app.isListening { return Tokens.Colors.stateRecording }
        return Tokens.Colors.inkSecondary
    }
}
