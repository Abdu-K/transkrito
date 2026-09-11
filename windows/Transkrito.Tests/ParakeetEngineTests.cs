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
    private static readonly ModelInfo Model = ModelCatalog.All[0];

    [SkippableFact]
    public async Task Transcribes_tts_sentence_and_applies_dictionary()
    {
        Skip.IfNot(Model.IsInstalled, "Parakeet model not downloaded");

        var wav = Path.Combine(Path.GetTempPath(), "transkrito-tts.wav");
        RenderTts("I use cloud code from anthropic every day.", wav);
        var samples = ReadWav16kMono(wav);
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

    private static void RenderTts(string sentence, string path)
    {
        // System.Speech is Windows-only and ships with the desktop runtime; render at 16 kHz mono 16-bit.
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
        Assert.True(File.Exists(path), "TTS wav not written: " + p.StandardError.ReadToEnd());
    }

    private static float[] ReadWav16kMono(string path)
    {
        using var reader = new NAudio.Wave.WaveFileReader(path);
        Assert.Equal(16000, reader.WaveFormat.SampleRate);
        Assert.Equal(1, reader.WaveFormat.Channels);
        var bytes = new byte[reader.Length];
        _ = reader.Read(bytes, 0, bytes.Length);
        var samples = new float[bytes.Length / 2];
        for (var i = 0; i < samples.Length; i++) samples[i] = BitConverter.ToInt16(bytes, i * 2) / 32768f;
        return samples;
    }
}
