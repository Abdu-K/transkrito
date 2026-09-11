namespace Transkrito.Dictionary;

public enum WarningKind { Common, Noop, Duplicate, Shadowed }

public sealed record DictionaryWarning(WarningKind Kind, string Message);

/// <summary>Checks an entry the user is about to save. Warnings never block saving.</summary>
public static class DictionaryWarnings
{
    public const int ShortWordMax = 3;

    public static IReadOnlyList<DictionaryWarning> Check(string hear, string? write, IEnumerable<DictionaryEntry> others, string? excludeId = null)
    {
        var result = new List<DictionaryWarning>();
        var parts = CorrectionEngine.Parts(hear);
        if (parts.Length == 0) return result;
        var normalized = CorrectionEngine.Normalize(hear);

        if (CommonWords.Contains(normalized) || (parts.Length == 1 && parts[0].Length <= ShortWordMax))
            result.Add(new DictionaryWarning(WarningKind.Common, $"\u201c{hear.Trim()}\u201d is a common word \u2014 this will rewrite it everywhere."));

        if (write is not null && string.Equals(hear.Trim(), write.Trim(), StringComparison.Ordinal))
            result.Add(new DictionaryWarning(WarningKind.Noop, "Hear and write are the same."));

        var mine = parts.Select(p => p.ToLowerInvariant()).ToArray();
        foreach (var other in others)
        {
            if (excludeId is not null && other.Id == excludeId) continue;
            var otherHear = other.HearText;
            if (otherHear.Length == 0) continue;
            if (CorrectionEngine.Normalize(otherHear) == normalized)
            {
                result.Add(new DictionaryWarning(WarningKind.Duplicate, "Already in the dictionary."));
                continue;
            }
            var theirs = CorrectionEngine.Parts(otherHear).Select(p => p.ToLowerInvariant()).ToArray();
            if (IsStrictSubsequence(mine, theirs) || IsStrictSubsequence(theirs, mine))
                result.Add(new DictionaryWarning(WarningKind.Shadowed, $"Overlaps with \u201c{otherHear}\u201d \u2014 longest match wins."));
        }
        return result;
    }

    /// <summary>true if `small` appears as a contiguous run inside `big` and is shorter than it.</summary>
    private static bool IsStrictSubsequence(string[] small, string[] big)
    {
        if (small.Length == 0 || small.Length >= big.Length) return false;
        for (var start = 0; start + small.Length <= big.Length; start++)
        {
            var ok = true;
            for (var i = 0; i < small.Length; i++)
                if (big[start + i] != small[i]) { ok = false; break; }
            if (ok) return true;
        }
        return false;
    }
}
