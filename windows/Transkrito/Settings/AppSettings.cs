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
    [JsonPropertyName("model")] public string Model { get; set; } = "parakeet-tdt-0.6b-v3";

    [JsonPropertyName("insertAtCursor")] public bool InsertAtCursor { get; set; } = true;

    public static AppSettings Load()
    {
        try { return JsonFile.Read<AppSettings>(AppPaths.Settings) ?? new AppSettings(); }
        catch { return new AppSettings(); }
    }

    public void Save() => JsonFile.Write(AppPaths.Settings, this);
}
