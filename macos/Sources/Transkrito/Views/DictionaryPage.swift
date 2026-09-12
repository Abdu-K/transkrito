import SwiftUI

enum EntryKind: Hashable { case term, correction }
enum DictionaryFilter: Hashable { case all, words, corrections }

/// Editable form state for one entry (add form or inline edit). Recomputes warnings as you type.
struct EntryDraft: Equatable {
    var kind: EntryKind = .term
    var hear = ""
    var write = ""

    init() {}
    init(_ e: DictionaryEntry) {
        kind = e.isTerm ? .term : .correction
        hear = e.hearText
        write = e.isTerm ? "" : e.writeText
    }

    var isCorrection: Bool { kind == .correction }
    var canSave: Bool {
        !hear.trimmingCharacters(in: .whitespaces).isEmpty && (kind == .term || !write.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    func warnings(others: [DictionaryEntry], excludeId: String?) -> [DictionaryWarning] {
        hear.trimmingCharacters(in: .whitespaces).isEmpty ? [] :
            DictionaryWarnings.check(hear: hear, write: isCorrection ? write : nil, others: others, excludeId: excludeId)
    }

    /// Writes the form into a new or existing entry.
    func apply(to entry: DictionaryEntry?) -> DictionaryEntry {
        var e = entry ?? DictionaryEntry()
        e.type = kind == .term ? EntryType.term : EntryType.correction
        let h = hear.trimmingCharacters(in: .whitespacesAndNewlines)
        let w = write.trimmingCharacters(in: .whitespacesAndNewlines)
        if kind == .term { e.text = h; e.hear = nil; e.write = nil } else { e.text = nil; e.hear = h; e.write = w }
        return e
    }
}

struct EntryEditor: View {
    @Environment(AppController.self) private var app
    @Binding var draft: EntryDraft
    var existing: DictionaryEntry?
    var onSave: () -> Void
    var onCancel: (() -> Void)?

    var body: some View {
        let warnings = draft.warnings(others: app.dictionary.entries, excludeId: existing?.id)
        VStack(alignment: .leading, spacing: Tokens.Space.s2) {
            Segmented(options: [(EntryKind.term, "Word or phrase"), (EntryKind.correction, "Correction")], selection: $draft.kind)
            HStack(spacing: Tokens.Space.s2) {
                TextField(draft.isCorrection ? "When it hears, e.g. cloud code" : "Word or phrase, e.g. Anthropic", text: $draft.hear)
                    .field(warning: warnings.contains { $0.kind == .common })
                    .environment(\.layoutDirection, LanguageDetector.isRightToLeft(draft.hear) ? .rightToLeft : .leftToRight)
                    .onSubmit { if draft.canSave { onSave() } }
                if draft.isCorrection {
                    Text("\u{2192}").textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkTertiary)
                    TextField("Write it as", text: $draft.write)
                        .field()
                        .environment(\.layoutDirection, LanguageDetector.isRightToLeft(draft.write) ? .rightToLeft : .leftToRight)
                        .onSubmit { if draft.canSave { onSave() } }
                }
                Button(existing == nil ? "Add" : "Save", action: onSave)
                    .buttonStyle(GlassButtonStyle(primary: true))
                    .disabled(!draft.canSave)
                    .opacity(draft.canSave ? 1 : 0.4)
                if let onCancel {
                    Button("Cancel", action: onCancel).buttonStyle(GlassButtonStyle())
                        .keyboardShortcut(.escape, modifiers: [])
                }
            }
            ForEach(warnings) { w in
                Text(w.message).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateWarning)
            }
        }
        .animation(Tokens.Motion.easeStandard, value: draft.isCorrection)
    }
}

struct DictionaryPage: View {
    @Environment(AppController.self) private var app
    @State private var query = ""
    @State private var filter: DictionaryFilter = .all
    @State private var draft = EntryDraft()

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s5) {
            VStack(alignment: .leading, spacing: Tokens.Space.s1) {
                Text("Dictionary").textStyle(Tokens.TypeScale.title).foregroundStyle(Tokens.Colors.inkPrimary)
                Text("Teach it the words it gets wrong: names, jargon, products, people. Corrections also catch glued forms like CloudCode.")
                    .textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkSecondary)
                if let err = app.dictionary.loadError {
                    Text(err).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
                }
            }

            EntryEditor(draft: $draft, existing: nil, onSave: {
                app.dictionary.add(draft.apply(to: nil))
                draft = EntryDraft()
            })

            HStack(spacing: Tokens.Space.s3) {
                TextField("Search dictionary", text: $query).field(icon: "magnifyingglass")
                Segmented(options: [(DictionaryFilter.all, "All"), (.words, "Words"), (.corrections, "Corrections")], selection: $filter)
            }

            let entries = filtered
            if entries.isEmpty {
                Text(query.isEmpty && filter == .all ? "Nothing here yet. Add the first word above." : "No matches.")
                    .textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.inkTertiary)
                    .padding(Tokens.Space.s7)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Tokens.Comp.rowGap) {
                        ForEach(entries) { e in DictionaryRow(entry: e) }
                    }
                }
            }
        }
        .padding(Tokens.Space.s6)
        .frame(maxWidth: Tokens.Layout.contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var filtered: [DictionaryEntry] {
        let base = app.dictionary.search(query)
        switch filter {
        case .all: return base
        case .words: return base.filter(\.isTerm)
        case .corrections: return base.filter { !$0.isTerm }
        }
    }
}

struct DictionaryRow: View {
    @Environment(AppController.self) private var app
    let entry: DictionaryEntry
    @State private var hover = false
    @State private var editing = false
    @State private var draft = EntryDraft()

    var body: some View {
        Group {
            if editing {
                EntryEditor(draft: $draft, existing: entry, onSave: {
                    app.dictionary.update(draft.apply(to: entry))
                    editing = false
                }, onCancel: { editing = false })
            } else {
                HStack(spacing: Tokens.Space.s2) {
                    Text(entry.hearText).textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkPrimary)
                        .environment(\.layoutDirection, LanguageDetector.isRightToLeft(entry.hearText) ? .rightToLeft : .leftToRight)
                    if !entry.isTerm {
                        Text("\u{2192}").textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkTertiary)
                        Text(entry.writeText).textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkPrimary)
                            .environment(\.layoutDirection, LanguageDetector.isRightToLeft(entry.writeText) ? .rightToLeft : .leftToRight)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: Tokens.Space.s1) {
                        IconButton(symbol: "pencil", help: "Edit") { draft = EntryDraft(entry); editing = true }
                        IconButton(symbol: "trash", help: "Delete", danger: true) { app.dictionary.remove(entry) }
                    }
                    .opacity(hover ? 1 : 0)
                }
            }
        }
        .padding(.horizontal, Tokens.Space.s4)
        .padding(.vertical, Tokens.Space.s3)
        .background(hover && !editing ? Tokens.Colors.surfaceGlass1 : .clear, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .animation(Tokens.Motion.easeStandard, value: hover)
    }
}
