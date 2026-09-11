import SwiftUI

/// Hero (pillars, hotkey line, mic, one stats line) over day-grouped history.
struct DictationPage: View {
    @Environment(AppController.self) private var app
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Tokens.Space.s3) {
                PillarsView(level: app.level)
                HStack(spacing: Tokens.Space.s4) {
                    MicButton()
                    VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                        Text("\(app.holdToTalkVerb) \(app.hotkeyLabel) anywhere")
                            .textStyle(Tokens.TypeScale.status).foregroundStyle(Tokens.Colors.inkPrimary)
                        Text(statsLine).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkSecondary)
                    }
                }
            }
            .padding(Tokens.Space.s6)

            VStack(spacing: Tokens.Space.s3) {
                TextField("Search dictations", text: $query).field(icon: "magnifyingglass")
                let groups = app.history.grouped(query)
                if groups.isEmpty {
                    VStack(spacing: Tokens.Space.s1) {
                        Text(query.isEmpty ? "Nothing dictated yet" : "No matches")
                            .textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkSecondary)
                        Text(query.isEmpty ? "Hold the hotkey in any app, speak, let go. The text lands at your cursor and shows up here."
                                           : "Search looks at the final text and the raw transcript.")
                            .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Tokens.Space.s7)
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: Tokens.Space.s4) {
                            ForEach(groups) { group in
                                VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                                    Text(group.label.uppercased())
                                        .textStyle(Tokens.TypeScale.caption).fontWeight(.medium).tracking(Tokens.Comp.dayHeaderTracking)
                                        .foregroundStyle(Tokens.Colors.inkTertiary)
                                    ForEach(group.items) { item in HistoryRow(item: item) }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Tokens.Space.s6)
            .frame(maxWidth: Tokens.Layout.contentMaxWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var statsLine: String {
        let s = app.history.stats()
        if s.today == 0 { return "Nothing dictated today" }
        var line = "Today \u{00B7} \(s.today) \(s.today == 1 ? "dictation" : "dictations") \u{00B7} \(s.wordsToday) words"
        if s.streak > 1 { line += " \u{00B7} \(s.streak)-day streak" }
        return line
    }
}

struct HistoryRow: View {
    @Environment(AppController.self) private var app
    let item: Transcription
    @State private var hover = false
    @State private var expanded = false

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.Space.s2) {
            Text(item.timeLabel)
                .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkTertiary)
                .frame(width: Tokens.Comp.timeColumn, alignment: .leading)
                .padding(.top, Tokens.Comp.timeBaselineOffset)
            VStack(alignment: .leading, spacing: Tokens.Space.s2) {
                Text(item.text)
                    .textStyle(Tokens.TypeScale.transcript).foregroundStyle(Tokens.Colors.inkPrimary)
                    .textSelection(.enabled)
                if item.hasCorrections {
                    Chip(label: item.correctionLabel, isOn: $expanded)
                    if expanded {
                        VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                            ForEach(item.corrections) { c in
                                Text(c.display).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.accentIce)
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: Tokens.Space.s1) {
                IconButton(symbol: "doc.on.doc", help: "Copy") { Inserter.copyToClipboard(item.text); app.setStatus("Copied") }
                IconButton(symbol: "trash", help: "Delete", danger: true) { app.history.remove(item) }
            }
            .opacity(hover ? 1 : 0)
        }
        .padding(.horizontal, Tokens.Space.s4)
        .padding(.vertical, Tokens.Space.s3)
        .background(rowFill, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .animation(Tokens.Motion.easeStandard, value: hover)
        .animation(Tokens.Motion.easeStandard, value: expanded)
        .animation(Tokens.Motion.easeStandard, value: item.isNew)
    }

    /// A row that just landed stays lit until noticed (direction contract).
    private var rowFill: Color {
        if item.isNew { return Tokens.Colors.accentPale }
        return hover ? Tokens.Colors.surfaceGlass1 : .clear
    }
}
