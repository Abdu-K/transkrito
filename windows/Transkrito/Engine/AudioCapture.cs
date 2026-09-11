using NAudio.Wave;

namespace Transkrito.Engine;

/// <summary>
/// Default microphone → 16 kHz mono float32, accumulated until Stop. Publishes a smoothed level per buffer.
/// WaveInEvent lets the Windows wave mapper resample from whatever the device runs at.
/// </summary>
public sealed class AudioCapture : IDisposable
{
    private const int BufferMs = 20;
    private WaveInEvent? _waveIn;
    private readonly List<float> _samples = new();
    private readonly LevelMeter _meter = new();
    private readonly object _gate = new();
    private DateTime _started;

    /// <summary>Smoothed level 0..1, raised on the capture thread.</summary>
    public event Action<double>? LevelChanged;
    public event Action<Exception>? Failed;

    public bool IsCapturing => _waveIn is not null;
    public double Level => _meter.Level;

    public void Start()
    {
        if (_waveIn is not null) return;
        lock (_gate) _samples.Clear();
        _meter.Reset();
        _waveIn = new WaveInEvent
        {
            WaveFormat = new WaveFormat(ParakeetEngine.SampleRate, 16, 1),
            BufferMilliseconds = BufferMs,
            NumberOfBuffers = 4,
        };
        _waveIn.DataAvailable += OnData;
        _waveIn.RecordingStopped += (_, e) => { if (e.Exception is not null) Failed?.Invoke(e.Exception); };
        _started = DateTime.UtcNow;
        _waveIn.StartRecording();
    }

    private void OnData(object? sender, WaveInEventArgs e)
    {
        var count = e.BytesRecorded / 2;
        var chunk = new float[count];
        for (var i = 0; i < count; i++)
            chunk[i] = BitConverter.ToInt16(e.Buffer, i * 2) / 32768f;
        lock (_gate) _samples.AddRange(chunk);
        var level = _meter.Push(chunk, count / (double)ParakeetEngine.SampleRate);
        LevelChanged?.Invoke(level);
    }

    /// <summary>Stops and returns everything captured plus its duration in seconds.</summary>
    public (float[] Samples, double DurationSec) Stop()
    {
        var w = _waveIn;
        _waveIn = null;
        if (w is not null)
        {
            w.DataAvailable -= OnData;
            w.StopRecording();
            w.Dispose();
        }
        float[] samples;
        lock (_gate) { samples = _samples.ToArray(); _samples.Clear(); }
        _meter.Reset();
        LevelChanged?.Invoke(0);
        return (samples, samples.Length / (double)ParakeetEngine.SampleRate);
    }

    public void Dispose() => Stop();
}
