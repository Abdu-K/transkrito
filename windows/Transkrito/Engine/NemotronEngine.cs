using SherpaOnnx;

namespace Transkrito.Engine;

/// <summary>
/// NVIDIA Nemotron 3.5 ASR Streaming 0.6B (multilingual, cache-aware transducer) via sherpa-onnx's OnlineRecognizer.
/// The language is pinned per stream with SetOption("language", "de"); leaving it unset makes the model detect the
/// spoken language itself. Audio is decoded while it arrives on a worker thread, so the transcript is ready almost
/// immediately after the key is released and partial text feeds the live "Listening · Deutsch" status.
/// Biasing: sherpa-onnx hotwords are not wired for NeMo transducers, so the dictionary works by correction only.
/// </summary>
public sealed class NemotronEngine : ISpeechEngine
{
    public const int SampleRate = 16000;
    private const int FeatureDim = 128;   // Nemotron mel bins (see nodejs-addon-examples/test_asr_streaming_nemotron.js)
    private const double TailPaddingSec = 0.4;

    private OnlineRecognizer? _recognizer;
    private OnlineStream? _stream;
    private readonly object _gate = new();
    private readonly Queue<float[]> _pending = new();
    private readonly SemaphoreSlim _wake = new(0);
    private Thread? _worker;
    private bool _running;
    private string _partial = "";

    public ModelInfo? LoadedModel { get; private set; }
    public bool IsLoaded => _recognizer is not null;
    public bool BiasSupported => false;
    public string BiasStatus => LoadedModel is null
        ? "Loads at start-up. Nemotron cannot be biased through sherpa-onnx — the dictionary works by correction only."
        : "Loaded. Nemotron cannot be biased through sherpa-onnx — the dictionary works by correction only.";

    public event Action<string>? PartialText;

    public Task LoadAsync(ModelInfo model) => Task.Run(() =>
    {
        if (!model.IsInstalled) throw new FileNotFoundException("Model files are not installed.", model.Dir);

        var config = new OnlineRecognizerConfig();
        config.FeatConfig.SampleRate = SampleRate;
        config.FeatConfig.FeatureDim = FeatureDim;
        config.ModelConfig.Transducer.Encoder = model.PathTo("encoder.int8.onnx");
        config.ModelConfig.Transducer.Decoder = model.PathTo("decoder.int8.onnx");
        config.ModelConfig.Transducer.Joiner = model.PathTo("joiner.int8.onnx");
        config.ModelConfig.Tokens = model.PathTo("tokens.txt");
        // NeMo transducers are auto-detected from the decoder's outputs; no ModelType needed.
        config.ModelConfig.NumThreads = Math.Clamp(Environment.ProcessorCount / 2, 2, 8);
        config.ModelConfig.Provider = "cpu";
        config.ModelConfig.Debug = 0;
        config.DecodingMethod = "greedy_search";
        config.EnableEndpoint = 0;

        var recognizer = new OnlineRecognizer(config);
        lock (_gate)
        {
            _recognizer?.Dispose();
            _recognizer = recognizer;
            LoadedModel = model;
        }
    });

    public void SetBiasTerms(IReadOnlyList<string> terms) { }

    public void BeginUtterance(string? language)
    {
        lock (_gate)
        {
            if (_recognizer is null) throw new InvalidOperationException("Model not loaded.");
            _stream?.Dispose();
            _stream = _recognizer.CreateStream();
            if (Lang.IsSupported(language)) _stream.SetOption("language", language!);
            _pending.Clear();
            _partial = "";
            _running = true;
            _worker = new Thread(DecodeLoop) { IsBackground = true, Name = "nemotron-decode" };
            _worker.Start();
        }
    }

    public void Feed(float[] samples16k)
    {
        lock (_gate)
        {
            if (!_running) return;
            _pending.Enqueue(samples16k);
        }
        _wake.Release();
    }

    /// <summary>Drains queued audio into the stream and decodes every ready chunk; publishes partial text.</summary>
    private void DecodeLoop()
    {
        while (true)
        {
            _wake.Wait();
            OnlineRecognizer? rec;
            OnlineStream? stream;
            var chunks = new List<float[]>();
            bool running;
            lock (_gate)
            {
                rec = _recognizer; stream = _stream; running = _running;
                while (_pending.Count > 0) chunks.Add(_pending.Dequeue());
            }
            if (rec is null || stream is null) return;
            foreach (var c in chunks) stream.AcceptWaveform(SampleRate, c);
            var decoded = false;
            while (rec.IsReady(stream)) { rec.Decode(stream); decoded = true; }
            if (decoded)
            {
                var text = rec.GetResult(stream).Text ?? "";
                if (text != _partial)
                {
                    _partial = text;
                    PartialText?.Invoke(text);
                }
            }
            if (!running) return;
        }
    }

    public Task<string> EndUtteranceAsync() => Task.Run(() =>
    {
        Thread? worker;
        lock (_gate)
        {
            _running = false;
            worker = _worker;
            _worker = null;
        }
        _wake.Release();           // let the loop drain and exit
        worker?.Join(TimeSpan.FromSeconds(5));

        lock (_gate)
        {
            if (_recognizer is null || _stream is null) return "";
            var stream = _stream;
            _stream = null;
            try
            {
                stream.AcceptWaveform(SampleRate, new float[(int)(SampleRate * TailPaddingSec)]);
                stream.InputFinished();
                while (_recognizer.IsReady(stream)) _recognizer.Decode(stream);
                return (_recognizer.GetResult(stream).Text ?? "").Trim();
            }
            finally
            {
                stream.Dispose();
            }
        }
    });

    public void Dispose()
    {
        Thread? worker;
        lock (_gate) { _running = false; worker = _worker; _worker = null; }
        _wake.Release();
        worker?.Join(TimeSpan.FromSeconds(2));
        lock (_gate)
        {
            _stream?.Dispose();
            _stream = null;
            _recognizer?.Dispose();
            _recognizer = null;
            LoadedModel = null;
        }
    }
}
