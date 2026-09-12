using System.Diagnostics;
using Transkrito.Dictionary;
using Transkrito.Engine;
using Xunit;

namespace Transkrito.Tests;

/// <summary>
/// End-to-end smoke: Windows TTS renders a sentence to 16 kHz WAV, Parakeet transcribes it, the correction pass runs.
/// Skipped when the model is not installed (Settings → Download) so `dotnet test` stays green on a fresh machine.
/// </summary>
public class ParakeetEngineTests
{
    private static readonly ModelInfo Model = ModelCatalog.Get("parakeet-tdt-0.6b-v3");

    [SkippableFact]
    public async Task Transcribes_tts_sentence_and_applies_dictionary()
    {
        Skip.IfNot(Model.IsInstalled, "Parakeet model not downloaded");

        var wav = Path.Combine(Path.GetTempPath(), "transkrito-tts.wav");
        WavFile.RenderTts("I use cloud code from anthropic every day.", wav);
        var samples = WavFile.Read16kMono(wav);
        Assert.True(samples.Length > 16000, "TTS produced too little audio");

        using var engine = new ParakeetEngine();
        await engine.LoadAsync(Model);
        var sw = Stopwatch.StartNew();
        var raw = await engine.TranscribeAsync(samples);
        sw.Stop();

        Assert.False(string.IsNullOrWhiteSpace(raw), "empty transcript");
        Assert.Contains("cloud", raw, StringComparison.OrdinalIgnoreCase);

        var entries = new[]
        {
            new DictionaryEntry { Type = EntryType.Correction, Hear = "cloud code", Write = "Claude Code" },
            new DictionaryEntry { Type = EntryType.Term, Text = "Anthropic" },
        };
        var (text, events) = CorrectionEngine.Apply(raw, entries);
        Assert.Contains("Claude Code", text);
        Assert.NotEmpty(events);
        Console.WriteLine($"raw: {raw}\ncorrected: {text}\ndecode: {sw.ElapsedMilliseconds} ms for {samples.Length / 16000.0:F1}s audio");
    }

}
