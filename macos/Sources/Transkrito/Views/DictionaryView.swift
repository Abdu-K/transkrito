import SwiftUI

enum EntryKind: Hashable { case term, correction }

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
            TextToggle(options: [(EntryKind.term, "Word or phrase"), (EntryKind.correction, "Correction")], selection: $draft.kind, small: true)
            HStack(spacing: Tokens.Space.s2) {
                TextField(draft.isCorrection ? "When you hear, e.g. cloud code" : "Word or phrase, e.g. Anthropic", text: $draft.hear)
                    .field(warning: warnings.contains { $0.kind == .common })
                    .onSubmit { if draft.canSave { onSave() } }
                if draft.isCorrection {
                    Text("\u{2192}").textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkTertiary)
                    TextField("Write", text: $draft.write)
                        .field()
                        .onSubmit { if draft.canSave { onSave() } }
                }
            }
            ForEach(warnings) { w in
                Text(w.message).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateWarning)
            }
            HStack(spacing: Tokens.Space.s3) {
                Button(existing == nil ? "Add" : "Save", action: onSave)
                    .buttonStyle(TextLinkButtonStyle(accent: true))
                    .disabled(!draft.canSave)
                    .opacity(draft.canSave ? 1 : 0.4)
                if let onCancel {
                    Button("Cancel", action: onCancel).buttonStyle(TextLinkButtonStyle())
                        .keyboardShortcut(.escape, modifiers: [])
                }
            }
        }
        .animation(Tokens.Motion.easeStandard, value: draft.isCorrection)
    }
}

struct DictionaryView: View {
    @Environment(AppController.self) private var app
    @State private var query = ""
    @State private var draft = EntryDraft()

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s3) {
            EntryEditor(draft: $draft, existing: nil, onSave: {
                app.dictionary.add(draft.apply(to: nil))
                draft = EntryDraft()
            })
            .padding(Tokens.Space.s1)

            TextField("Search dictionary", text: $query)
                .field()
            if let err = app.dictionary.loadError {
                Text(err).textStyle(Tokens.TypeScale.caption).foregroundStyle(Tokens.Colors.stateDanger)
            }

            let entries = app.dictionary.search(query)
            if entries.isEmpty {
                Text(query.isEmpty ? "Teach it the words it gets wrong: names, jargon, products, people." : "No matches.")
                    .textStyle(Tokens.TypeScale.caption)
                    .foregroundStyle(Tokens.Colors.inkTertiary)
                    .padding(Tokens.Space.s6)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { e in
                            DictionaryRow(entry: e)
                            Hairline()
                        }
                    }
                }
            }
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
                    if !entry.isTerm {
                        Text("\u{2192}").textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkTertiary)
                        Text(entry.writeText).textStyle(Tokens.TypeScale.body).foregroundStyle(Tokens.Colors.inkPrimary)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: Tokens.Space.s2) {
                        Button("Edit") { draft = EntryDraft(entry); editing = true }.buttonStyle(TextLinkButtonStyle())
                        Button("Delete") { app.dictionary.remove(entry) }.buttonStyle(TextLinkButtonStyle(danger: true))
                    }
                    .opacity(hover ? 1 : 0)
                }
            }
        }
        .padding(.vertical, Tokens.Space.s3)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .animation(Tokens.Motion.easeStandard, value: hover)
    }
}
