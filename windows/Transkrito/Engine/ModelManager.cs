using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using SharpCompress.Common;
using SharpCompress.Readers;
using Transkrito.Storage;

namespace Transkrito.Engine;

public enum EngineKind { NemotronStreaming, ParakeetOffline }

/// <summary>A downloadable sherpa-onnx model. <see cref="Languages"/> lists what it can transcribe; "*" = Auto works.</summary>
public sealed record ModelInfo(string Id, string Name, string Version, EngineKind Kind, string[] Languages, string Url, string Folder, string[] Files, long ApproxMb)
{
    public string Dir => Path.Combine(AppPaths.ModelsDir, Folder);
    public bool IsInstalled => Files.All(f => System.IO.File.Exists(Path.Combine(Dir, f)));
    public string PathTo(string name) => Path.Combine(Dir, name);

    /// <summary>Can this model take the language setting ("auto", "en", "de", "ar")?</summary>
    public bool Supports(string language) => language == Lang.Auto ? Languages.Contains("*") : Languages.Contains(language) || Languages.Contains("*");
    public string LanguageSummary => Languages.Contains("*")
        ? $"{Lang.Display(Lang.En)} · {Lang.Display(Lang.De)} · {Lang.Display(Lang.Ar)} · Auto"
        : string.Join(" · ", Languages.Select(Lang.Display));

    public ISpeechEngine CreateEngine() => Kind switch
    {
        EngineKind.NemotronStreaming => new NemotronEngine(),
        _ => new ParakeetEngine(),
    };
}

/// <summary>Models published by sherpa-onnx (github.com/k2-fsa/sherpa-onnx, release "asr-models").</summary>
public static class ModelCatalog
{
    private const string Base = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/";
    private static readonly string[] TransducerFiles = { "encoder.int8.onnx", "decoder.int8.onnx", "joiner.int8.onnx", "tokens.txt" };

    public const string DefaultId = "nemotron-3.5-asr-streaming-0.6b";

    public static readonly IReadOnlyList<ModelInfo> All = new[]
    {
        // Multilingual (30+ locales incl. en/de/ar) with built-in spoken-language detection. 560 ms chunk balances latency and accuracy.
        new ModelInfo(DefaultId, "Nemotron 3.5 multilingual", "2026-06-11 · 560 ms · int8", EngineKind.NemotronStreaming, new[] { "*", Lang.En, Lang.De, Lang.Ar },
            Base + "sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11.tar.bz2",
            "sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11", TransducerFiles, 475),
        // European-only. Kept as a fast option for English/German; never used for Arabic or Auto.
        new ModelInfo("parakeet-tdt-0.6b-v3", "Parakeet TDT 0.6B v3", "int8", EngineKind.ParakeetOffline, new[] { Lang.En, Lang.De },
            Base + "sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8.tar.bz2",
            "sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8", TransducerFiles, 470),
        new ModelInfo("parakeet-tdt-0.6b-v2", "Parakeet TDT 0.6B v2", "int8", EngineKind.ParakeetOffline, new[] { Lang.En },
            Base + "sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8.tar.bz2",
            "sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8", TransducerFiles, 470),
    };

    public static ModelInfo Default => All[0];
    public static ModelInfo Get(string id) => All.FirstOrDefault(m => m.Id == id) ?? Default;

    /// <summary>The model to actually run: the user's pick when it can handle the language, otherwise the multilingual default.</summary>
    public static ModelInfo Resolve(string selectedId, string language)
    {
        var selected = Get(selectedId);
        return selected.Supports(language) ? selected : Default;
    }
}

/// <summary>Downloads a model archive into %LOCALAPPDATA%\Transkrito\models and extracts it. Resumes partial downloads.</summary>
public static class ModelManager
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromHours(2) };

    public static async Task DownloadAsync(ModelInfo model, IProgress<(long done, long total)> progress, CancellationToken ct)
    {
        if (model.IsInstalled) { progress.Report((1, 1)); return; }
        Directory.CreateDirectory(AppPaths.ModelsDir);
        var archive = Path.Combine(AppPaths.ModelsDir, model.Folder + ".tar.bz2.part");

        // Resume an interrupted download when the server honors ranges; otherwise start over.
        long have = System.IO.File.Exists(archive) ? new FileInfo(archive).Length : 0;
        using (var request = new HttpRequestMessage(HttpMethod.Get, model.Url))
        {
            if (have > 0) request.Headers.Range = new RangeHeaderValue(have, null);
            using var response = await Http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct);
            if (have > 0 && response.StatusCode != System.Net.HttpStatusCode.PartialContent)
            {
                System.IO.File.Delete(archive);
                have = 0;
            }
            response.EnsureSuccessStatusCode();
            var total = (response.Content.Headers.ContentLength ?? -1) + (response.StatusCode == System.Net.HttpStatusCode.PartialContent ? have : 0);
            await using var src = await response.Content.ReadAsStreamAsync(ct);
            await using var dst = new FileStream(archive, have > 0 ? FileMode.Append : FileMode.Create, FileAccess.Write);
            var buffer = new byte[1 << 16];
            long done = have;
            int n;
            while ((n = await src.ReadAsync(buffer, ct)) > 0)
            {
                await dst.WriteAsync(buffer.AsMemory(0, n), ct);
                done += n;
                progress.Report((done, total));
            }
        }

        progress.Report((-1, -1)); // extracting
        await Task.Run(() =>
        {
            using var stream = System.IO.File.OpenRead(archive);
            using var reader = ReaderFactory.Open(stream);
            while (reader.MoveToNextEntry())
            {
                ct.ThrowIfCancellationRequested();
                if (reader.Entry.IsDirectory) continue;
                // Archive entries are "<folder>/<file>"; keep that layout under ModelsDir.
                reader.WriteEntryToDirectory(AppPaths.ModelsDir, new ExtractionOptions { ExtractFullPath = true, Overwrite = true });
            }
        }, ct);

        System.IO.File.Delete(archive);
        if (!model.IsInstalled)
        {
            // Half-extracted folders would pass IsInstalled on the next launch; remove them so the download can be retried.
            try { if (Directory.Exists(model.Dir)) Directory.Delete(model.Dir, recursive: true); } catch { }
            throw new InvalidOperationException("Archive extracted but expected model files are missing.");
        }
        WriteMetadata(model);
    }

    /// <summary>model.json next to the files: which catalog entry and version this folder is.</summary>
    private static void WriteMetadata(ModelInfo model)
    {
        try
        {
            var meta = new { id = model.Id, name = model.Name, version = model.Version, engine = model.Kind.ToString(), languages = model.Languages, source = model.Url, installed = DateTimeOffset.Now };
            System.IO.File.WriteAllText(Path.Combine(model.Dir, "model.json"), JsonSerializer.Serialize(meta, JsonFile.Options));
        }
        catch { /* metadata is informational */ }
    }

    public static void Delete(ModelInfo model)
    {
        if (Directory.Exists(model.Dir)) Directory.Delete(model.Dir, recursive: true);
        var part = Path.Combine(AppPaths.ModelsDir, model.Folder + ".tar.bz2.part");
        if (System.IO.File.Exists(part)) System.IO.File.Delete(part);
    }
}
