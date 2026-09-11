namespace Transkrito.Engine;

/// <summary>
/// RMS → 0..1 level with asymmetric EMA smoothing (attack/release from tokens). Shared math with the macOS port:
/// level = clamp((20·log10(rms) + 50) / 50, 0, 1); a = 1 − exp(−dt/τ).
/// </summary>
public sealed class LevelMeter
{
    private readonly double _attack;
    private readonly double _release;
    private double _smoothed;

    public LevelMeter(double attackMs = Design.Tokens.Motion.LevelAttackMs, double releaseMs = Design.Tokens.Motion.LevelReleaseMs)
    {
        _attack = attackMs / 1000.0;
        _release = releaseMs / 1000.0;
    }

    /// <summary>Smoothed level in 0..1.</summary>
    public double Level => _smoothed;

    public static double Instant(ReadOnlySpan<float> samples)
    {
        if (samples.Length == 0) return 0;
        double sum = 0;
        foreach (var s in samples) sum += s * s;
        var rms = Math.Sqrt(sum / samples.Length);
        if (rms <= 1e-6) return 0;
        var db = 20 * Math.Log10(rms);
        return Math.Clamp((db + 50) / 50, 0, 1);
    }

    /// <summary>Feed one buffer; dt is the buffer duration in seconds.</summary>
    public double Push(ReadOnlySpan<float> samples, double dt)
    {
        var target = Instant(samples);
        var tau = target > _smoothed ? _attack : _release;
        var a = 1 - Math.Exp(-dt / tau);
        _smoothed += (target - _smoothed) * a;
        return _smoothed;
    }

    public void Reset() => _smoothed = 0;
}
