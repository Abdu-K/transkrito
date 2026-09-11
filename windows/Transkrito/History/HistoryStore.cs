using System.Collections.ObjectModel;
using System.Text.Json.Serialization;
using Transkrito.Dictionary;
using Transkrito.Storage;

namespace Transkrito.History;

public sealed class CorrectionRecord
{
    [JsonPropertyName("hear")] public string Hear { get; set; } = "";
    [JsonPropertyName("write")] public string Write { get; set; } = "";
    [JsonPropertyName("matched")] public string Matched { get; set; } = "";
    [JsonPropertyName("count")] public int Count { get; set; }

    public static CorrectionRecord From(CorrectionEvent e) =>
        new() { Hear = e.Hear, Write = e.Write, Matched = e.Matched, Count = e.Count };

    [JsonIgnore] public string Display => Count > 1 ? $"{Matched} → {Write}  ×{Count}" : $"{Matched} → {Write}";
}

public sealed class Transcription : System.ComponentModel.INotifyPropertyChanged
{
    public event System.ComponentModel.PropertyChangedEventHandler? PropertyChanged;
    private bool _isNew;
    /// <summary>True briefly after the row lands so the list can hold a tint until noticed. Not persisted.</summary>
    [JsonIgnore] public bool IsNew { get => _isNew; set { _isNew = value; PropertyChanged?.Invoke(this, new(nameof(IsNew))); } }
    [JsonIgnore] public int WordCount => Text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries).Length;
    [JsonIgnore] public string DayKey => Date.LocalDateTime.Date.ToString("yyyy-MM-dd");
    [JsonIgnore] public string DayLabel => Date.LocalDateTime.Date == DateTime.Today ? "Today"
        : Date.LocalDateTime.Date == DateTime.Today.AddDays(-1) ? "Yesterday"
        : Date.LocalDateTime.Date.Year == DateTime.Today.Year ? Date.LocalDateTime.ToString("d MMMM") : Date.LocalDateTime.ToString("d MMMM yyyy");

    [JsonPropertyName("id")] public string Id { get; set; } = Guid.NewGuid().ToString();
    [JsonPropertyName("date")] public DateTimeOffset Date { get; set; } = DateTimeOffset.Now;
    [JsonPropertyName("raw")] public string Raw { get; set; } = "";
    [JsonPropertyName("text")] public string Text { get; set; } = "";
    [JsonPropertyName("durationSec")] public double DurationSec { get; set; }
    [JsonPropertyName("engine")] public string Engine { get; set; } = "parakeet";
    [JsonPropertyName("model")] public string Model { get; set; } = "";
    [JsonPropertyName("corrections")] public List<CorrectionRecord> Corrections { get; set; } = new();

    [JsonIgnore] public bool HasCorrections => Corrections.Count > 0;
    [JsonIgnore] public int CorrectionCount => Corrections.Sum(c => c.Count);
    [JsonIgnore] public string CorrectionLabel => CorrectionCount == 1 ? "1 correction" : $"{CorrectionCount} corrections";
    [JsonIgnore] public string TimeLabel => Date.LocalDateTime.ToString("HH:mm");
}

public sealed class HistoryFile
{
    [JsonPropertyName("version")] public int Version { get; set; } = 1;
    [JsonPropertyName("items")] public List<Transcription> Items { get; set; } = new();
}

/// <summary>history.json: newest first, capped.</summary>
public sealed class HistoryStore
{
    public const int Cap = 500;
    private readonly string _path;

    public ObservableCollection<Transcription> Items { get; } = new();

    public HistoryStore(string? path = null)
    {
        _path = path ?? AppPaths.History;
        try
        {
            var file = JsonFile.Read<HistoryFile>(_path) ?? new HistoryFile();
            foreach (var t in file.Items) Items.Add(t);
        }
        catch
        {
            // Unreadable history is not fatal: start empty; the file is rewritten on the next save.
        }
    }

    /// <summary>Today's count, today's words, and the run of consecutive days (ending today) with at least one dictation.</summary>
    public (int Today, int WordsToday, int Streak) Stats()
    {
        var today = DateTime.Today;
        var todays = Items.Where(t => t.Date.LocalDateTime.Date == today).ToList();
        var days = new HashSet<DateTime>(Items.Select(t => t.Date.LocalDateTime.Date));
        var streak = 0;
        for (var d = today; days.Contains(d); d = d.AddDays(-1)) streak++;
        return (todays.Count, todays.Sum(t => t.WordCount), streak);
    }

    public void Add(Transcription t)
    {
        t.IsNew = true;
        Items.Insert(0, t);
        while (Items.Count > Cap) Items.RemoveAt(Items.Count - 1);
        Save();
    }

    public void Remove(Transcription t) { Items.Remove(t); Save(); }

    public IEnumerable<Transcription> Search(string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return Items;
        return Items.Where(t =>
            t.Text.Contains(query, StringComparison.OrdinalIgnoreCase) ||
            t.Raw.Contains(query, StringComparison.OrdinalIgnoreCase));
    }

    private void Save() => JsonFile.Write(_path, new HistoryFile { Items = Items.ToList() });
}
