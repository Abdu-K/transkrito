using System.Diagnostics;
using Transkrito.Dictionary;
using Transkrito.Engine;
using Xunit;
using Xunit.Abstractions;

namespace Transkrito.Tests;

/// <summary>
/// Real-audio tests for the multilingual streaming engine. Skipped until the Nemotron model is downloaded
/// (Settings → Download, or run once with TRANSKRITO_DOWNLOAD=1 to fetch it through ModelManager).
/// Audio: the model archive's own test_wavs (de/es/...), Windows TTS for English, and any user-provided
/// tests/audio/{en,de,ar}.wav next to the repo (16 kHz mono).
/// </summary>
public class NemotronEngineTests
{
    private static readonly ModelInfo Model = ModelCatalog.Get(ModelCatalog.DefaultId);
    private readonly ITestOutputHelper _out;
    public NemotronEngineTests(ITestOutputHelper o) => _out = o;

    private static string RepoAudio(string name)
    {
        var dir = AppContext.BaseDirectory;
        for (var i = 0; i < 8 && dir is not null; i++, dir = Path.GetDirectoryName(dir))
        {
            var p = Path.Combine(dir, "tests", "audio", name);
            if (File.Exists(p)) return p;
        }
        return "";
    }

    [SkippableFact]
    public async Task Model_downloads_verifies_and_writes_metadata()
    {
        Skip.If(Environment.GetEnvironmentVariable("TRANSKRITO_DOWNLOAD") != "1", "set TRANSKRITO_DOWNLOAD=1 to exercise the download path");
        var sw = Stopwatch.StartNew();
        long last = 0;
        var progress = new Progress<(long done, long total)>(p => { if (p.done - last > 50_000_000) { last = p.done; _out.WriteLine($"{p.done / 1048576} / {p.total / 1048576} MB"); } });
        await ModelManager.DownloadAsync(Model, progress, CancellationToken.None);
        _out.WriteLine($"downloaded in {sw.Elapsed}");
        Assert.True(Model.IsInstalled);
        Assert.True(File.Exists(Model.PathTo("model.json")));
        // A second call must not download again.
        sw.Restart();
        await ModelManager.DownloadAsync(Model, progress, CancellationToken.None);
        Assert.True(sw.ElapsedMilliseconds < 2000, "re-download happened for an installed model");
    }

    private static async Task<NemotronEngine> LoadAsync()
    {
        var e = new NemotronEngine();
        await e.LoadAsync(Model);
        return e;
    }

    private static async Task<string> RunAsync(NemotronEngine engine, float[] samples, string? language)
    {
        engine.BeginUtterance(language);
        // Feed in 20 ms chunks like the capture does.
        const int chunk = 320;
        for (var i = 0; i < samples.Length; i += chunk)
            engine.Feed(samples.Skip(i).Take(chunk).ToArray());
        return await engine.EndUtteranceAsync();
    }

    [SkippableFact]
    public async Task Auto_detects_german_from_the_models_own_sample()
    {
        Skip.IfNot(Model.IsInstalled, "Nemotron model not downloaded");
        var wav = Model.PathTo(Path.Combine("test_wavs", "de.wav"));
        Skip.IfNot(File.Exists(wav), "archive has no de.wav");
        using var engine = await LoadAsync();
        var sw = Stopwatch.StartNew();
        var text = await RunAsync(engine, WavFile.Read16kMono(wav), null);
        _out.WriteLine($"de auto: {text} ({sw.ElapsedMilliseconds} ms)");
        Assert.False(string.IsNullOrWhiteSpace(text));
        Assert.Equal(Lang.De, LanguageDetector.ForHistory(text));
    }

    [SkippableFact]
    public async Task Auto_detects_english_from_tts_and_dictionary_corrects_it()
    {
        Skip.IfNot(Model.IsInstalled, "Nemotron model not downloaded");
        var wav = Path.Combine(Path.GetTempPath(), "transkrito-tts-en.wav");
        WavFile.RenderTts("Please open Claude Code and update the project.", wav);
        using var engine = await LoadAsync();
        var sw = Stopwatch.StartNew();
        var raw = await RunAsync(engine, WavFile.Read16kMono(wav), null);
        _out.WriteLine($"en auto: {raw} ({sw.ElapsedMilliseconds} ms)");
        Assert.Equal(Lang.En, LanguageDetector.ForHistory(raw));
        var (text, events) = CorrectionEngine.Apply(raw, new[] { new DictionaryEntry { Type = EntryType.Correction, Hear = "cloud code", Write = "Claude Code" } });
        Assert.Contains("Claude Code", text);
        _out.WriteLine($"corrected: {text} ({events.Count} events)");
    }

    [SkippableFact]
    public async Task Explicit_language_pins_the_stream()
    {
        Skip.IfNot(Model.IsInstalled, "Nemotron model not downloaded");
        var wav = Model.PathTo(Path.Combine("test_wavs", "de.wav"));
        Skip.IfNot(File.Exists(wav), "archive has no de.wav");
        using var engine = await LoadAsync();
        var samples = WavFile.Read16kMono(wav);
        var pinnedDe = await RunAsync(engine, samples, Lang.De);
        _out.WriteLine($"de pinned: {pinnedDe}");
        Assert.Equal(Lang.De, LanguageDetector.ForHistory(pinnedDe));
    }

    [SkippableFact]
    public async Task Switches_language_between_consecutive_utterances_without_reload()
    {
        Skip.IfNot(Model.IsInstalled, "Nemotron model not downloaded");
        var de = Model.PathTo(Path.Combine("test_wavs", "de.wav"));
        Skip.IfNot(File.Exists(de), "archive has no de.wav");
        var en = Path.Combine(Path.GetTempPath(), "transkrito-tts-en2.wav");
        WavFile.RenderTts("I need to update the project tomorrow.", en);
        using var engine = await LoadAsync();

        var first = await RunAsync(engine, WavFile.Read16kMono(en), null);
        var second = await RunAsync(engine, WavFile.Read16kMono(de), null);
        var third = await RunAsync(engine, WavFile.Read16kMono(en), null);
        _out.WriteLine($"1: {first}\n2: {second}\n3: {third}");
        Assert.Equal(Lang.En, LanguageDetector.ForHistory(first));
        Assert.Equal(Lang.De, LanguageDetector.ForHistory(second));
        Assert.Equal(Lang.En, LanguageDetector.ForHistory(third));
    }

    [SkippableFact]
    public async Task Auto_detects_arabic_from_repo_sample()
    {
        Skip.IfNot(Model.IsInstalled, "Nemotron model not downloaded");
        var wav = Model.PathTo(Path.Combine("test_wavs", "ar.wav"));
        if (!File.Exists(wav)) wav = RepoAudio("ar.wav");
        Skip.IfNot(File.Exists(wav), "no Arabic sample available (archive test_wavs/ar.wav or tests/audio/ar.wav)");
        using var engine = await LoadAsync();
        var sw = Stopwatch.StartNew();
        var text = await RunAsync(engine, WavFile.Read16kMono(wav), null);
        _out.WriteLine($"ar auto: {text} ({sw.ElapsedMilliseconds} ms)");
        Assert.Equal(Lang.Ar, LanguageDetector.ForHistory(text));
        Assert.True(LanguageDetector.IsRightToLeft(text));
    }
}

/// <summary>WAV helpers: read any PCM/float WAV as 16 kHz mono, render Windows TTS.</summary>
public static class WavFile
{
    public static float[] Read16kMono(string path)
    {
        using var reader = new NAudio.Wave.AudioFileReader(path); // float32, any rate/channels
        var mono = reader.WaveFormat.Channels == 1 ? (NAudio.Wave.ISampleProvider)reader : new NAudio.Wave.SampleProviders.StereoToMonoSampleProvider(reader);
        var resampled = reader.WaveFormat.SampleRate == 16000 ? mono : new NAudio.Wave.SampleProviders.WdlResamplingSampleProvider(mono, 16000);
        var list = new List<float>();
        var buf = new float[16000];
        int n;
        while ((n = resampled.Read(buf, 0, buf.Length)) > 0) list.AddRange(buf.Take(n));
        return list.ToArray();
    }

    public static void RenderTts(string sentence, string path)
    {
        var script = $@"
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$fmt = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(16000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$s.SetOutputToWaveFile('{path.Replace("'", "''")}', $fmt)
$s.Speak('{sentence.Replace("'", "''")}')
$s.Dispose()";
        var psi = new ProcessStartInfo("powershell", $"-NoProfile -NonInteractive -Command \"{script.Replace("\"", "\\\"")}\"")
        { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true };
        using var p = Process.Start(psi)!;
        p.WaitForExit(60_000);
        if (!File.Exists(path)) throw new InvalidOperationException("TTS wav not written: " + p.StandardError.ReadToEnd());
    }
}
