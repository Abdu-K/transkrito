using System.Reflection;

namespace Transkrito.Dictionary;

/// <summary>Small list of common English words (shared/common-words.txt) embedded at build time.</summary>
public static class CommonWords
{
    private static readonly Lazy<HashSet<string>> Words = new(Load);

    public static bool Contains(string normalized) => Words.Value.Contains(normalized);

    private static HashSet<string> Load()
    {
        var set = new HashSet<string>(StringComparer.Ordinal);
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("common-words.txt");
        if (stream is null) return set;
        using var reader = new StreamReader(stream);
        while (reader.ReadLine() is { } line)
        {
            var w = line.Trim().ToLowerInvariant();
            if (w.Length > 0) set.Add(w);
        }
        return set;
    }
}
