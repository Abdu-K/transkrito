using System.Text.Json;
using Transkrito.Engine;
using Transkrito.History;
using Transkrito.Settings;
using Transkrito.Storage;
using Xunit;

namespace Transkrito.Tests;

/// <summary>Language classifier, RTL check, settings migration and history compatibility. Vectors from shared/correction-tests.json.</summary>
public class LanguageTests
{
    private static readonly JsonDocument Vectors = JsonDocument.Parse(
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "correction-tests.json")));

    public static IEnumerable<object[]> LanguageCases() =>
        Vectors.RootElement.GetProperty("language").GetProperty("cases").EnumerateArray()
            .Select(c => new object[] { c.GetProperty("text").GetString()!, c.GetProperty("expect").GetString()! });

    [Theory]
    [MemberData(nameof(LanguageCases))]
    public void Text_language_matches_shared_vectors(string text, string expect)
    {
        Assert.Equal(expect, LanguageDetector.ForHistory(text));
    }

    public static IEnumerable<object[]> RtlCases() =>
        Vectors.RootElement.GetProperty("rtl").GetProperty("cases").EnumerateArray()
            .Select(c => new object[] { c.GetProperty("text").GetString()!, c.GetProperty("rtl").GetBoolean() });

    [Theory]
    [MemberData(nameof(RtlCases))]
    public void Rtl_detection_matches_shared_vectors(string text, bool rtl)
    {
        Assert.Equal(rtl, LanguageDetector.IsRightToLeft(text));
    }

    [Fact]
    public void Rtl_rendering_never_alters_the_string()
    {
        const string arabic = "أنا أستخدم Claude Code للعمل.";
        var t = new Transcription { Text = arabic };
        Assert.True(t.IsRightToLeft);
        Assert.Equal(arabic, t.Text); // logical order preserved; direction is a rendering property only
        var roundTrip = JsonSerializer.Deserialize<Transcription>(JsonSerializer.Serialize(t, JsonFile.Options), JsonFile.Options)!;
        Assert.Equal(arabic, roundTrip.Text);
    }

    [Fact]
    public void Settings_without_language_migrate_to_auto_without_losing_other_fields()
    {
        const string old = """
        { "version": 1, "hotkey": { "key": "D", "modifiers": ["control","alt"] }, "model": "parakeet-tdt-0.6b-v3",
          "insertAtCursor": false, "hotkeyMode": "toggle", "inputDevice": "abc" }
        """;
        var s = AppSettings.Normalize(JsonSerializer.Deserialize<AppSettings>(old, JsonFile.Options)!);
        Assert.Equal(Lang.Auto, s.Language);
        Assert.Equal("D", s.Hotkey.Key);
        Assert.False(s.InsertAtCursor);
        Assert.Equal("toggle", s.HotkeyMode);
        Assert.Equal("abc", s.InputDevice);
        Assert.Equal("parakeet-tdt-0.6b-v3", s.Model);

        var bogus = AppSettings.Normalize(JsonSerializer.Deserialize<AppSettings>("""{ "language": "fr" }""", JsonFile.Options)!);
        Assert.Equal(Lang.Auto, bogus.Language);
        var explicitDe = AppSettings.Normalize(JsonSerializer.Deserialize<AppSettings>("""{ "language": "de" }""", JsonFile.Options)!);
        Assert.Equal(Lang.De, explicitDe.Language);
    }

    [Fact]
    public void History_loads_with_and_without_language()
    {
        const string json = """
        { "version": 1, "items": [
          { "id": "a", "date": "2026-09-11T05:40:00+02:00", "raw": "x", "text": "Ich muss morgen zur Schule.", "durationSec": 1, "engine": "parakeet", "model": "m", "corrections": [] },
          { "id": "b", "date": "2026-09-11T05:41:00+02:00", "raw": "y", "text": "hello", "durationSec": 1, "engine": "nemotron", "model": "m", "corrections": [], "language": "en" },
          { "id": "c", "date": "2026-09-11T05:42:00+02:00", "raw": "z", "text": "?", "durationSec": 1, "engine": "nemotron", "model": "m", "corrections": [], "language": "unknown" } ] }
        """;
        var file = JsonSerializer.Deserialize<HistoryFile>(json, JsonFile.Options)!;
        Assert.Equal(3, file.Items.Count);
        Assert.Null(file.Items[0].Language);
        Assert.Equal("", file.Items[0].LanguageLabel);
        Assert.Equal("en", file.Items[1].Language);
        Assert.Equal("English", file.Items[1].LanguageLabel);
        Assert.Equal("unknown", file.Items[2].Language);
        Assert.Equal("", file.Items[2].LanguageLabel);

        // Old entries stay untouched when written back: no language key is invented for them.
        var back = JsonSerializer.Serialize(file, JsonFile.Options);
        using var doc = JsonDocument.Parse(back);
        var items = doc.RootElement.GetProperty("items").EnumerateArray().ToList();
        Assert.False(items[0].TryGetProperty("language", out _));
        Assert.Equal("en", items[1].GetProperty("language").GetString());
    }

    [Fact]
    public void Display_names_are_in_their_own_script()
    {
        Assert.Equal("English", Lang.Display(Lang.En));
        Assert.Equal("Deutsch", Lang.Display(Lang.De));
        Assert.Equal("العربية", Lang.Display(Lang.Ar));
        Assert.Equal("", Lang.Display(Lang.Unknown));
    }
}
