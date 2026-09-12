using System.Text.Json.Serialization;
using Transkrito.Storage;

namespace Transkrito.Settings;

public sealed class HotkeySetting
{
    [JsonPropertyName("key")] public string Key { get; set; } = "Space";

    /// <summary>Windows modifiers: control, alt, shift, win.</summary>
    [JsonPropertyName("modifiers")] public List<string> Modifiers { get; set; } = new() { "control", "alt" };

    public string Display()
    {
        var parts = Modifiers.Select(m => m switch
        {
            "control" => "Ctrl",
            "alt" => "Alt",
            "shift" => "Shift",
            "win" => "Win",
            _ => m,
        }).ToList();
        parts.Add(Key);
        return string.Join("+", parts);
    }
}

public sealed class AppSettings
{
    [JsonPropertyName("version")] public int Version { get; set; } = 1;
    [JsonPropertyName("hotkey")] public HotkeySetting Hotkey { get; set; } = new();

    /// <summary>Model id; see Engine/ModelCatalog.</summary>
    [JsonPropertyName("model")] public string Model { get; set; } = Engine.ModelCatalog.DefaultId;

    [JsonPropertyName("insertAtCursor")] public bool InsertAtCursor { get; set; } = true;

    /// <summary>"hold" = push-to-talk (default); "toggle" = press to start, press to stop.</summary>
    [JsonPropertyName("hotkeyMode")] public string HotkeyMode { get; set; } = "hold";
    [JsonIgnore] public bool HoldToTalk => HotkeyMode != "toggle";

    /// <summary>WASAPI endpoint id; empty = system default.</summary>
    [JsonPropertyName("inputDevice")] public string InputDevice { get; set; } = "";

    /// <summary>Spoken language: "auto" (default), "en", "de", "ar". Files written before this field existed load as auto.</summary>
    [JsonPropertyName("language")] public string Language { get; set; } = Engine.Lang.Auto;

    public static AppSettings Load()
    {
        try { return Normalize(JsonFile.Read<AppSettings>(AppPaths.Settings) ?? new AppSettings()); }
        catch { return new AppSettings(); }
    }

    /// <summary>Unknown or missing language values fall back to auto without touching the file.</summary>
    public static AppSettings Normalize(AppSettings s)
    {
        if (s.Language is not (Engine.Lang.Auto or Engine.Lang.En or Engine.Lang.De or Engine.Lang.Ar)) s.Language = Engine.Lang.Auto;
        return s;
    }

    public void Save() => JsonFile.Write(AppPaths.Settings, this);
}
