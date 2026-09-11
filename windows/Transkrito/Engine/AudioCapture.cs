using NAudio.CoreAudioApi;
using NAudio.Dsp;
using NAudio.Wave;

namespace Transkrito.Engine;

public sealed record MicDevice(string Id, string Name)
{
    public static readonly MicDevice Default = new("", "System default microphone");
    public override string ToString() => Name;
}

/// <summary>
/// Chosen microphone (WASAPI shared mode) → 16 kHz mono float32, accumulated until Stop.
/// The device's own mix format is downmixed to mono and resampled here, so any endpoint works.
/// Publishes a smoothed level per buffer.
/// </summary>
public sealed class AudioCapture : IDisposable
{
    private static readonly Guid FloatSubtype = new("00000003-0000-0010-8000-00aa00389b71"); // KSDATAFORMAT_SUBTYPE_IEEE_FLOAT
    private WasapiCapture? _capture;
    private WdlResampler? _resampler;
    private readonly List<float> _samples = new();
    private readonly LevelMeter _meter = new();
    private readonly object _gate = new();
    private int _channels;
    private bool _isFloat;
    private DateTime _started;

    /// <summary>Smoothed level 0..1, raised on the capture thread.</summary>
    public event Action<double>? LevelChanged;
    public event Action<Exception>? Failed;

    public bool IsCapturing => _capture is not null;
    public double Level => _meter.Level;

    /// <summary>Device id ("" = system default). Applied on the next Start.</summary>
    public string DeviceId { get; set; } = "";

    public static IReadOnlyList<MicDevice> Devices()
    {
        var list = new List<MicDevice> { MicDevice.Default };
        try
        {
            using var e = new MMDeviceEnumerator();
            foreach (var d in e.EnumerateAudioEndPoints(DataFlow.Capture, DeviceState.Active))
                list.Add(new MicDevice(d.ID, d.FriendlyName));
        }
        catch { /* no audio subsystem: default only */ }
        return list;
    }

    private static MMDevice ResolveDevice(string id)
    {
        using var e = new MMDeviceEnumerator();
        if (!string.IsNullOrEmpty(id))
        {
            try { return e.GetDevice(id); }
            catch { /* unplugged: fall back to default */ }
        }
        return e.GetDefaultAudioEndpoint(DataFlow.Capture, Role.Communications);
    }

    public void Start()
    {
        if (_capture is not null) return;
        lock (_gate) _samples.Clear();
        _meter.Reset();

        var device = ResolveDevice(DeviceId);
        var capture = new WasapiCapture(device, useEventSync: true, audioBufferMillisecondsLength: 20);
        var fmt = capture.WaveFormat;
        _channels = fmt.Channels;
        _isFloat = fmt.Encoding == WaveFormatEncoding.IeeeFloat ||
                   (fmt is WaveFormatExtensible ext && ext.SubFormat == FloatSubtype) ||
                   fmt.BitsPerSample == 32;
        _resampler = new WdlResampler();
        _resampler.SetMode(true, 2, false);
        _resampler.SetFilterParms();
        _resampler.SetFeedMode(true);
        _resampler.SetRates(fmt.SampleRate, ParakeetEngine.SampleRate);

        capture.DataAvailable += OnData;
        capture.RecordingStopped += (_, e) => { if (e.Exception is not null) Failed?.Invoke(e.Exception); };
        _capture = capture;
        _started = DateTime.UtcNow;
        capture.StartRecording();
    }

    private void OnData(object? sender, WaveInEventArgs e)
    {
        if (_resampler is null) return;
        var bytesPerSample = _isFloat ? 4 : 2;
        var frames = e.BytesRecorded / (bytesPerSample * _channels);
        if (frames == 0) return;

        // Downmix to mono.
        var mono = new float[frames];
        for (var f = 0; f < frames; f++)
        {
            float sum = 0;
            for (var c = 0; c < _channels; c++)
            {
                var i = (f * _channels + c) * bytesPerSample;
                sum += _isFloat ? BitConverter.ToSingle(e.Buffer, i) : BitConverter.ToInt16(e.Buffer, i) / 32768f;
            }
            mono[f] = sum / _channels;
        }

        // Resample to the engine rate.
        var outCount = (int)Math.Ceiling(frames * (double)ParakeetEngine.SampleRate / _capture!.WaveFormat.SampleRate) + 16;
        var outBuf = new float[outCount];
        var needed = _resampler.ResamplePrepare(frames, 1, out var inBuf, out var inOffset);
        Array.Copy(mono, 0, inBuf, inOffset, Math.Min(needed, frames));
        var produced = _resampler.ResampleOut(outBuf, 0, frames, outCount, 1);
        if (produced <= 0) return;

        var chunk = new float[produced];
        Array.Copy(outBuf, chunk, produced);
        lock (_gate) _samples.AddRange(chunk);
        var level = _meter.Push(chunk, produced / (double)ParakeetEngine.SampleRate);
        LevelChanged?.Invoke(level);
    }

    /// <summary>Stops and returns everything captured plus its duration in seconds.</summary>
    public (float[] Samples, double DurationSec) Stop()
    {
        var c = _capture;
        _capture = null;
        if (c is not null)
        {
            c.DataAvailable -= OnData;
            try { c.StopRecording(); } catch { /* already stopped */ }
            c.Dispose();
        }
        _resampler = null;
        float[] samples;
        lock (_gate) { samples = _samples.ToArray(); _samples.Clear(); }
        _meter.Reset();
        LevelChanged?.Invoke(0);
        return (samples, samples.Length / (double)ParakeetEngine.SampleRate);
    }

    public void Dispose() => Stop();
}
