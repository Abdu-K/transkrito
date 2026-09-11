import Foundation
import Observation

/// Owns dictionary.json. UI edits write atomically; external edits (TextEdit, sync) reload via a DispatchSource
/// watching the directory. A malformed file keeps the last good in-memory copy and sets `loadError`; the file is
/// not overwritten until the user saves from the UI.
@MainActor @Observable
final class DictionaryStore {
    private(set) var entries: [DictionaryEntry] = []
    private(set) var loadError: String?
    var onChange: (() -> Void)?

    let fileURL: URL
    private var lastWrite: Date?
    private var watcher: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1

    init(fileURL: URL = AppPaths.dictionary, watch: Bool = true) {
        self.fileURL = fileURL
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        load()
        if !FileManager.default.fileExists(atPath: fileURL.path) { save() }
        if watch { startWatching() }
    }

    private func startWatching() {
        let dir = fileURL.deletingLastPathComponent()
        dirFD = open(dir.path, O_EVTONLY)
        guard dirFD >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: dirFD, eventMask: [.write, .rename, .extend], queue: .main)
        src.setEventHandler { [weak self] in Task { @MainActor in self?.externalChange() } }
        src.setCancelHandler { [dirFD] in close(dirFD) }
        src.resume()
        watcher = src
    }

    private func externalChange() {
        // Debounce editors that write twice, and ignore the echo of our own atomic write.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self else { return }
            let stamp = (try? FileManager.default.attributesOfItem(atPath: self.fileURL.path)[.modificationDate]) as? Date
            if stamp == self.lastWrite { return }
            self.lastWrite = stamp
            self.load()
            self.onChange?()
        }
    }

    private func load() {
        do {
            let file = try JsonFile.read(DictionaryFile.self, from: fileURL) ?? DictionaryFile()
            entries = file.entries
            loadError = nil
            lastWrite = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate]) as? Date
        } catch {
            loadError = "dictionary.json could not be read: \(error.localizedDescription)"
        }
    }

    func save() {
        do {
            try JsonFile.write(DictionaryFile(entries: entries), to: fileURL)
            lastWrite = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate]) as? Date
            loadError = nil
        } catch {
            loadError = "dictionary.json could not be written: \(error.localizedDescription)"
        }
        onChange?()
    }

    func add(_ entry: DictionaryEntry) { entries.insert(entry, at: 0); save() }
    func remove(_ entry: DictionaryEntry) { entries.removeAll { $0.id == entry.id }; save() }
    func update(_ entry: DictionaryEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry }
        save()
    }

    func search(_ query: String) -> [DictionaryEntry] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return entries }
        return entries.filter { $0.hearText.localizedCaseInsensitiveContains(q) || $0.writeText.localizedCaseInsensitiveContains(q) }
    }
}
