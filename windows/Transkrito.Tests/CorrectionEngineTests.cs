using System.Text.Json;
using Transkrito.Dictionary;
using Xunit;

namespace Transkrito.Tests;

/// <summary>Runs the shared vectors in shared/correction-tests.json (copied next to the test binary).</summary>
public class CorrectionEngineTests
{
    private static readonly JsonDocument Vectors = JsonDocument.Parse(
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "correction-tests.json")));

    private static DictionaryEntry Entry(JsonElement e) => new()
    {
        Type = e.GetProperty("type").GetString()!,
        Text = e.TryGetProperty("text", out var t) ? t.GetString() : null,
        Hear = e.TryGetProperty("hear", out var h) ? h.GetString() : null,
        Write = e.TryGetProperty("write", out var w) ? w.GetString() : null,
        Created = e.TryGetProperty("created", out var c) ? c.GetDateTimeOffset() : DateTimeOffset.UnixEpoch,
    };

    public static IEnumerable<object[]> Cases() =>
        Vectors.RootElement.GetProperty("cases").EnumerateArray().Select(c => new object[] { c.GetProperty("name").GetString()! });

    private static JsonElement Find(string section, string name) =>
        Vectors.RootElement.GetProperty(section).EnumerateArray().First(c => c.GetProperty("name").GetString() == name);

    [Theory]
    [MemberData(nameof(Cases))]
    public void Apply_matches_shared_vectors(string name)
    {
        var c = Find("cases", name);
        var entries = c.GetProperty("entries").EnumerateArray().Select(Entry).ToList();
        var input = c.GetProperty("input").GetString()!;
        var expected = c.GetProperty("expected").GetString()!;

        var (text, events) = CorrectionEngine.Apply(input, entries);

        Assert.Equal(expected, text);
        var expectedEvents = c.GetProperty("events").EnumerateArray().Select(e => new CorrectionEvent(
            e.GetProperty("hear").GetString()!, e.GetProperty("write").GetString()!,
            e.GetProperty("matched").GetString()!, e.GetProperty("count").GetInt32())).ToList();
        Assert.Equal(expectedEvents, events);

        // Idempotence: a second pass changes nothing.
        var (again, againEvents) = CorrectionEngine.Apply(text, entries);
        Assert.Equal(text, again);
        Assert.Empty(againEvents);
    }

    public static IEnumerable<object[]> WarningCases() =>
        Vectors.RootElement.GetProperty("warnings").EnumerateArray().Select(c => new object[] { c.GetProperty("name").GetString()! });

    [Theory]
    [MemberData(nameof(WarningCases))]
    public void Warnings_match_shared_vectors(string name)
    {
        var c = Find("warnings", name);
        var hear = c.GetProperty("hear").GetString()!;
        var write = c.TryGetProperty("write", out var w) ? w.GetString() : null;
        var others = c.GetProperty("others").EnumerateArray().Select(Entry).ToList();
        var expect = c.GetProperty("expect").EnumerateArray().Select(e => e.GetString()!).OrderBy(x => x).ToList();

        var got = DictionaryWarnings.Check(hear, write, others)
            .Select(x => x.Kind.ToString().ToLowerInvariant()).Distinct().OrderBy(x => x).ToList();

        Assert.Equal(expect, got);
    }

    [Fact]
    public void Bias_terms_match_shared_vectors()
    {
        foreach (var c in Vectors.RootElement.GetProperty("bias").EnumerateArray())
        {
            var entries = c.GetProperty("entries").EnumerateArray().Select(Entry).ToList();
            var max = c.GetProperty("maxTerms").GetInt32();
            var expect = c.GetProperty("expect").EnumerateArray().Select(e => e.GetString()!).ToList();
            Assert.Equal(expect, Bias.Terms(entries, max));
        }
    }
}
