using System.Text;
using System.Text.RegularExpressions;

namespace Transkrito.Dictionary;

/// <summary>One rule that fired: hear → write, first matched substring, how many times.</summary>
public sealed record CorrectionEvent(string Hear, string Write, string Matched, int Count);

/// <summary>
/// Post-transcription correction pass. Pure, deterministic, identical to the macOS port.
/// Whole-word, case-insensitive, longest hear first, tolerant of glued/hyphenated parts.
/// See shared/SPEC.md "Correction engine".
/// </summary>
public static class CorrectionEngine
{
    private sealed record Rule(string Hear, string Write, Regex Pattern, int Length, DateTimeOffset Created);

    public static (string Text, IReadOnlyList<CorrectionEvent> Events) Apply(string text, IEnumerable<DictionaryEntry> entries)
    {
        if (string.IsNullOrEmpty(text)) return (text, Array.Empty<CorrectionEvent>());

        var rules = BuildRules(entries);
        var events = new List<CorrectionEvent>();
        var current = text;

        foreach (var rule in rules)
        {
            string? firstMatched = null;
            var count = 0;
            current = rule.Pattern.Replace(current, m =>
            {
                // A match that already equals the canonical write is left alone and not counted.
                if (string.Equals(m.Value, rule.Write, StringComparison.Ordinal)) return m.Value;
                firstMatched ??= m.Value;
                count++;
                return rule.Write;
            });
            if (count > 0) events.Add(new CorrectionEvent(rule.Hear, rule.Write, firstMatched!, count));
        }

        return (current, events);
    }

    /// <summary>Split on whitespace and hyphens; drop empties.</summary>
    public static string[] Parts(string hear) =>
        hear.Split(new[] { ' ', '\t', '\n', '\r', '-' }, StringSplitOptions.RemoveEmptyEntries);

    /// <summary>Lowercase, separators removed — used for duplicate/common checks.</summary>
    public static string Normalize(string hear) => string.Concat(Parts(hear)).ToLowerInvariant();

    public const string WordChar = @"[\p{L}\p{M}\p{N}_]";
    public const string WordStart = "(?<!" + WordChar + ")";
    public const string WordEnd = "(?!" + WordChar + ")";

    public static Regex? BuildPattern(string hear)
    {
        var parts = Parts(hear);
        if (parts.Length == 0) return null;
        // Explicit Unicode word boundaries instead of \b: letters, marks (Arabic harakat), digits and _ are word
        // characters on both .NET and ICU, so Arabic, German umlauts/ß and Latin behave the same on both platforms.
        var sb = new StringBuilder(WordStart);
        for (var i = 0; i < parts.Length; i++)
        {
            if (i > 0) sb.Append(@"[\s\-]*");
            sb.Append(Regex.Escape(parts[i]));
        }
        sb.Append(WordEnd);
        return new Regex(sb.ToString(), RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }

    private static List<Rule> BuildRules(IEnumerable<DictionaryEntry> entries)
    {
        var rules = new List<Rule>();
        foreach (var e in entries)
        {
            var hear = e.HearText.Trim();
            var write = e.WriteText.Trim();
            if (hear.Length == 0 || write.Length == 0) continue;
            // Correction whose hear == write can never change anything; terms always run (they fix casing).
            if (!e.IsTerm && string.Equals(hear, write, StringComparison.Ordinal)) continue;
            var pattern = BuildPattern(hear);
            if (pattern is null) continue;
            rules.Add(new Rule(hear, write, pattern, Normalize(hear).Length, e.Created));
        }
        // Longest hear first; ties by creation order so results are stable.
        return rules.OrderByDescending(r => r.Length).ThenBy(r => r.Created).ToList();
    }
}
