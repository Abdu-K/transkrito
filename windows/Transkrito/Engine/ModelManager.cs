using System.Net.Http;
using SharpCompress.Common;
using SharpCompress.Readers;
using Transkrito.Storage;

namespace Transkrito.Engine;

public sealed record ModelInfo(string Id, string Name, string Language, string Url, string Folder, string[] Files)
{
    public string Dir => Path.Combine(AppPaths.ModelsDir, Folder);
    public bool IsInstalled => Files.All(f => System.IO.File.Exists(Path.Combine(Dir, f)));
    public string PathTo(string name) => Path.Combine(Dir, name);
}

/// <summary>Parakeet variants published by sherpa-onnx. All are NeMo transducers (TDT), greedy decoding.</summary>
public static class ModelCatalog
{
    private static readonly string[] Tdt = { "encoder.int8.onnx", "decoder.int8.onnx", "joiner.int8.onnx", "tokens.txt" };

    public static readonly IReadOnlyList<ModelInfo> All = new[]
    {
        new ModelInfo("parakeet-tdt-0.6b-v3", "Parakeet TDT 0.6B v3", "25 European languages",
            "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8.tar.bz2",
            "sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8", Tdt),
        new ModelInfo("parakeet-tdt-0.6b-v2", "Parakeet TDT 0.6B v2", "English",
            "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8.tar.bz2",
            "sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8", Tdt),
    };

    public static ModelInfo Get(string id) => All.FirstOrDefault(m => m.Id == id) ?? All[0];
}

/// <summary>Downloads a model archive into %LOCALAPPDATA%\Transkrito\models and extracts it.</summary>
public static class ModelManager
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromHours(2) };

    public static async Task DownloadAsync(ModelInfo model, IProgress<(long done, long total)> progress, CancellationToken ct)
    {
        Directory.CreateDirectory(AppPaths.ModelsDir);
        var archive = Path.Combine(AppPaths.ModelsDir, model.Folder + ".tar.bz2");

        using (var response = await Http.GetAsync(model.Url, HttpCompletionOption.ResponseHeadersRead, ct))
        {
            response.EnsureSuccessStatusCode();
            var total = response.Content.Headers.ContentLength ?? -1;
            await using var src = await response.Content.ReadAsStreamAsync(ct);
            await using var dst = File.Create(archive);
            var buffer = new byte[1 << 16];
            long done = 0;
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
            using var stream = File.OpenRead(archive);
            using var reader = ReaderFactory.Open(stream);
            while (reader.MoveToNextEntry())
            {
                ct.ThrowIfCancellationRequested();
                if (reader.Entry.IsDirectory) continue;
                // Archive entries are "<folder>/<file>"; keep that layout under ModelsDir.
                reader.WriteEntryToDirectory(AppPaths.ModelsDir, new ExtractionOptions { ExtractFullPath = true, Overwrite = true });
            }
        }, ct);

        File.Delete(archive);
        if (!model.IsInstalled)
            throw new InvalidOperationException("Archive extracted but expected model files are missing.");
    }

    public static void Delete(ModelInfo model)
    {
        if (Directory.Exists(model.Dir)) Directory.Delete(model.Dir, recursive: true);
    }
}
