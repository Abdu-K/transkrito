namespace Transkrito.Storage;

/// <summary>Where Transkrito keeps its plain files. See shared/SPEC.md "Files".</summary>
public static class AppPaths
{
    public static string DataDir { get; } =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Transkrito");

    public static string ModelsDir { get; } =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Transkrito", "models");

    public static string Dictionary => Path.Combine(DataDir, "dictionary.json");
    public static string History => Path.Combine(DataDir, "history.json");
    public static string Settings => Path.Combine(DataDir, "settings.json");

    public static void EnsureDirs()
    {
        Directory.CreateDirectory(DataDir);
        Directory.CreateDirectory(ModelsDir);
    }
}
