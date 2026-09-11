using SherpaOnnx;

namespace Transkrito.Engine;

/// <summary>
/// NVIDIA Parakeet via sherpa-onnx. Offline: takes the whole 16 kHz mono buffer after Stop.
/// Biasing: sherpa-onnx hotwords need modified_beam_search on a classic transducer; Parakeet TDT decodes greedily
/// and ignores hotwords, so <see cref="BiasSupported"/> is false and the dictionary relies on the correction pass.
/// </summary>
public sealed class ParakeetEngine : IDisposable
{
    public const int SampleRate = 16000;

    private OfflineRecognizer? _recognizer;
    private readonly object _gate = new();

    public ModelInfo? LoadedModel { get; private set; }
    public bool IsLoaded => _recognizer is not null;

    /// <summary>False for every Parakeet TDT model; see class remarks.</summary>
    public bool BiasSupported => false;

    public string BiasStatus => LoadedModel is null
        ? "Loads at start-up. Parakeet TDT cannot be biased (greedy decoding) — the dictionary works by correction only."
        : "Loaded. Parakeet TDT cannot be biased (greedy decoding) — the dictionary works by correction only.";

    /// <summary>Loads the model on a background thread. Throws if the files are missing.</summary>
    public Task LoadAsync(ModelInfo model) => Task.Run(() =>
    {
        if (!model.IsInstalled) throw new FileNotFoundException("Model files are not installed.", model.Dir);

        var config = new OfflineRecognizerConfig();
        config.FeatConfig.SampleRate = SampleRate;
        config.FeatConfig.FeatureDim = 80;
        config.ModelConfig.Transducer.Encoder = model.PathTo("encoder.int8.onnx");
        config.ModelConfig.Transducer.Decoder = model.PathTo("decoder.int8.onnx");
        config.ModelConfig.Transducer.Joiner = model.PathTo("joiner.int8.onnx");
        config.ModelConfig.Tokens = model.PathTo("tokens.txt");
        config.ModelConfig.ModelType = "nemo_transducer";
        config.ModelConfig.NumThreads = Math.Clamp(Environment.ProcessorCount / 2, 2, 8);
        config.ModelConfig.Provider = "cpu";
        config.ModelConfig.Debug = 0;
        config.DecodingMethod = "greedy_search";

        var recognizer = new OfflineRecognizer(config);
        lock (_gate)
        {
            _recognizer?.Dispose();
            _recognizer = recognizer;
            LoadedModel = model;
        }
    });

    /// <summary>The bias list is accepted for API symmetry with the macOS engine; Parakeet TDT cannot use it.</summary>
    public void SetBiasTerms(IReadOnlyList<string> terms) { }

    public Task<string> TranscribeAsync(float[] samples16k) => Task.Run(() =>
    {
        lock (_gate)
        {
            if (_recognizer is null) throw new InvalidOperationException("Model not loaded.");
            if (samples16k.Length < SampleRate / 10) return string.Empty; // < 100 ms: nothing to hear
            using var stream = _recognizer.CreateStream();
            stream.AcceptWaveform(SampleRate, samples16k);
            _recognizer.Decode(stream);
            return (stream.Result.Text ?? string.Empty).Trim();
        }
    });

    public void Dispose()
    {
        lock (_gate)
        {
            _recognizer?.Dispose();
            _recognizer = null;
            LoadedModel = null;
        }
    }
}
