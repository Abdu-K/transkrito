using System.Text.Json.Serialization;

namespace Transkrito.Dictionary;

/// <summary>
/// One dictionary entry. Schema mirrors shared/SPEC.md.
/// type == "term": a word/phrase the engine should know (Text). Canonicalizes casing.
/// type == "correction": when you hear Hear, write Write.
/// </summary>
public sealed class DictionaryEntry
{
    [JsonPropertyName("id")] public string Id { get; set; } = Guid.NewGuid().ToString();
    [JsonPropertyName("type")] public string Type { get; set; } = EntryType.Term;
    [JsonPropertyName("text")][JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? Text { get; set; }
    [JsonPropertyName("hear")][JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? Hear { get; set; }
    [JsonPropertyName("write")][JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? Write { get; set; }
    [JsonPropertyName("created")] public DateTimeOffset Created { get; set; } = DateTimeOffset.UtcNow;

    [JsonIgnore] public bool IsTerm => Type == EntryType.Term;

    /// <summary>What the engine hears (term text or correction hear).</summary>
    [JsonIgnore] public string HearText => (IsTerm ? Text : Hear) ?? string.Empty;

    /// <summary>What gets written (term text or correction write).</summary>
    [JsonIgnore] public string WriteText => (IsTerm ? Text : Write) ?? string.Empty;
}

public static class EntryType
{
    public const string Term = "term";
    public const string Correction = "correction";
}

public sealed class DictionaryFile
{
    [JsonPropertyName("version")] public int Version { get; set; } = 1;
    [JsonPropertyName("entries")] public List<DictionaryEntry> Entries { get; set; } = new();
}
