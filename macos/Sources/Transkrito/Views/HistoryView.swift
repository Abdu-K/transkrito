import SwiftUI

struct HistoryView: View {
    @Environment(AppController.self) private var app
    @State private var query = ""

    var body: some View {
        VStack(spacing: Tokens.Space.s2) {
            TextField("Search transcriptions", text: $query)
                .field()

            let items = app.history.search(query)
            if items.isEmpty {
                Text(query.isEmpty ? "Nothing yet. Press Start or the hotkey and speak." : "No matches.")
                    .textStyle(Tokens.TypeScale.caption)
                    .foregroundStyle(Tokens.Colors.inkTertiary)
                    .padding(Tokens.Space.s6)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            HistoryRow(item: item)
                            Hairline()
                        }
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    @Environment(AppController.self) private var app
    let item: Transcription
    @State private var hover = false
    @State private var expanded = false

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.Space.s3) {
            VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                Text(item.text)
                    .textStyle(Tokens.TypeScale.transcript)
                    .foregroundStyle(Tokens.Colors.inkPrimary)
                    .textSelection(.enabled)
                HStack(spacing: Tokens.Space.s2) {
                    Text(item.timeLabel).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                    if item.hasCorrections {
                        Chip(label: item.correctionLabel, isOn: $expanded)
                    }
                }
                // What the dictionary changed.
                if expanded {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(item.corrections) { c in
                            Text(c.display).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.accentBase)
                        }
                    }
                    .transition(.opacity)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: Tokens.Space.s2) {
                Button("Copy") { Inserter.copyToClipboard(item.text) }.buttonStyle(TextLinkButtonStyle())
                Button("Delete") { app.history.remove(item) }.buttonStyle(TextLinkButtonStyle(danger: true))
            }
            .opacity(hover ? 1 : 0)
        }
        .padding(.vertical, Tokens.Space.s3)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .animation(Tokens.Motion.easeStandard, value: hover)
        .animation(Tokens.Motion.easeStandard, value: expanded)
    }
}
