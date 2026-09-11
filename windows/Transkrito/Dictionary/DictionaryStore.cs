using System.Collections.ObjectModel;
using Transkrito.Storage;

namespace Transkrito.Dictionary;

/// <summary>
/// Owns dictionary.json. UI edits write atomically; external edits (Notepad, sync) reload via FileSystemWatcher.
/// A malformed file keeps the last good in-memory copy and sets <see cref="LoadError"/>; the file is not
/// overwritten until the user saves from the UI.
/// </summary>
public sealed class DictionaryStore : IDisposable
{
    private readonly string _path;
    private readonly FileSystemWatcher? _watcher;
    private readonly SynchronizationContext? _ui;
    private DateTime _lastWrite;
    private readonly object _gate = new();

    public ObservableCollection<DictionaryEntry> Entries { get; } = new();
    public string? LoadError { get; private set; }
    public event Action? Changed;

    public DictionaryStore(string? path = null, bool watch = true)
    {
        _path = path ?? AppPaths.Dictionary;
        _ui = SynchronizationContext.Current;
        Directory.CreateDirectory(Path.GetDirectoryName(_path)!);
        Load();
        if (!File.Exists(_path)) Save();

        if (!watch) return;
        _watcher = new FileSystemWatcher(Path.GetDirectoryName(_path)!, Path.GetFileName(_path))
        {
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.Size,
            EnableRaisingEvents = true,
        };
        _watcher.Changed += OnExternalChange;
        _watcher.Created += OnExternalChange;
        _watcher.Renamed += OnExternalChange;
    }

    public string FilePath => _path;

    private void OnExternalChange(object sender, FileSystemEventArgs e)
    {
        // Ignore the echo of our own atomic write; debounce editors that write twice.
        Task.Delay(150).ContinueWith(_ =>
        {
            lock (_gate)
            {
                if (!File.Exists(_path)) return;
                var stamp = File.GetLastWriteTimeUtc(_path);
                if (stamp == _lastWrite) return;
                _lastWrite = stamp;
            }
            Post(() => { Load(); Changed?.Invoke(); });
        });
    }

    private void Post(Action a)
    {
        if (_ui is null) a(); else _ui.Post(_ => a(), null);
    }

    private void Load()
    {
        try
        {
            var file = JsonFile.Read<DictionaryFile>(_path) ?? new DictionaryFile();
            Entries.Clear();
            foreach (var e in file.Entries) Entries.Add(e);
            LoadError = null;
            if (File.Exists(_path)) _lastWrite = File.GetLastWriteTimeUtc(_path);
        }
        catch (Exception ex)
        {
            LoadError = $"dictionary.json could not be read: {ex.Message}";
        }
    }

    public void Save()
    {
        lock (_gate)
        {
            JsonFile.Write(_path, new DictionaryFile { Entries = Entries.ToList() });
            _lastWrite = File.GetLastWriteTimeUtc(_path);
            LoadError = null;
        }
        Changed?.Invoke();
    }

    public void Add(DictionaryEntry entry) { Entries.Insert(0, entry); Save(); }
    public void Remove(DictionaryEntry entry) { Entries.Remove(entry); Save(); }
    public void Update() => Save();

    public IEnumerable<DictionaryEntry> Search(string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return Entries;
        return Entries.Where(e =>
            e.HearText.Contains(query, StringComparison.OrdinalIgnoreCase) ||
            e.WriteText.Contains(query, StringComparison.OrdinalIgnoreCase));
    }

    public void Dispose() => _watcher?.Dispose();
}
