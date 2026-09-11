namespace Transkrito.Dictionary;

/// <summary>Builds the short list of strings handed to the speech engine as context.</summary>
public static class Bias
{
    /// <summary>Cap: long context makes speech models drift and invent text on quiet audio. Mirrors design/tokens.json bias.maxTerms.</summary>
    public const int MaxTerms = 40;

    public static IReadOnlyList<string> Terms(IEnumerable<DictionaryEntry> entries, int maxTerms = MaxTerms)
    {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var list = new List<string>();
        foreach (var e in entries.OrderByDescending(e => e.Created))
        {
            var w = e.WriteText.Trim();
            if (w.Length == 0 || !seen.Add(w)) continue;
            list.Add(w);
            if (list.Count >= maxTerms) break;
        }
        return list;
    }
}
