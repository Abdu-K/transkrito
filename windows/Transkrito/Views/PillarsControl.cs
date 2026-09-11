using System.Windows;
using System.Windows.Media;
using Transkrito.Design;

namespace Transkrito.Views;

/// <summary>
/// The central audio visualization: symmetrical rounded pillars, tallest in the middle.
/// Geometry, envelope, jitter, thresholds and every color come from Tokens (design/tokens.json "pillars").
/// Renders per frame via CompositionTarget.Rendering while the level is non-zero or pillars are settling.
/// </summary>
public sealed class PillarsControl : FrameworkElement
{
    public static readonly DependencyProperty LevelProperty = DependencyProperty.Register(
        nameof(Level), typeof(double), typeof(PillarsControl), new PropertyMetadata(0.0, (d, _) => ((PillarsControl)d).EnsureAnimating()));

    /// <summary>Smoothed input level 0..1 (already attack/release filtered by LevelMeter).</summary>
    public double Level { get => (double)GetValue(LevelProperty); set => SetValue(LevelProperty, value); }

    private const int N = (int)Tokens.Pillar.Count;
    private const int Half = N / 2;
    private readonly double[] _envelope = new double[N];
    private readonly double[] _jitter = new double[N];      // mirrored random walk
    private readonly double[] _jitterTarget = new double[N];
    private readonly double[] _height = new double[N];      // displayed heights, lerped toward target
    private double _speaking;                                // 0..1 glass style blend
    private readonly Random _rng = new(7);
    private bool _animating;
    private TimeSpan _last;
    private double _clock; // seconds, for the idle breathing cycle

    private static readonly Brush IdleBrush = Freeze(new SolidColorBrush(Tokens.Color.PillarIdle));
    private static readonly Brush GlassBrush = Freeze(new LinearGradientBrush(Tokens.Color.PillarGlassFillTop, Tokens.Color.PillarGlassFillBottom, 90));
    private static readonly Pen EdgePen = Freeze(new Pen(new SolidColorBrush(Tokens.Color.PillarGlassEdge), Tokens.Pillar.EdgeWidth));
    private static readonly Pen HighlightPen = Freeze(new Pen(new SolidColorBrush(Tokens.Color.PillarGlassHighlight), Tokens.Pillar.HighlightWidth)
    { StartLineCap = PenLineCap.Round, EndLineCap = PenLineCap.Round });

    public PillarsControl()
    {
        for (var i = 0; i < N; i++)
        {
            var d = Math.Abs(i - Half);
            var c = Math.Cos(Math.PI * d / (N - 1));
            _envelope[i] = Math.Max(Tokens.Pillar.EnvelopeFloor, c * c);
            _height[i] = Tokens.Pillar.MinHeight + (Tokens.Pillar.MaxHeight - Tokens.Pillar.MinHeight) * Tokens.Pillar.IdleLevel * _envelope[i];
        }
        IsHitTestVisible = false;
        Loaded += (_, _) => EnsureAnimating();
        Unloaded += (_, _) => StopAnimating();
    }

    private static T Freeze<T>(T f) where T : Freezable { f.Freeze(); return f; }

    protected override Size MeasureOverride(Size available)
    {
        var w = N * Tokens.Pillar.Width + (N - 1) * Tokens.Pillar.Gap;
        var h = double.IsInfinity(available.Height) ? Tokens.Pillar.MaxHeight : available.Height;
        return new Size(Math.Min(w, available.Width), h);
    }

    private void EnsureAnimating()
    {
        if (_animating || !IsLoaded) return;
        _animating = true;
        _last = TimeSpan.Zero;
        CompositionTarget.Rendering += OnFrame;
    }

    private void StopAnimating()
    {
        if (!_animating) return;
        _animating = false;
        CompositionTarget.Rendering -= OnFrame;
    }

    private void OnFrame(object? sender, EventArgs e)
    {
        var now = ((RenderingEventArgs)e).RenderingTime;
        var dt = _last == TimeSpan.Zero ? 1 / 60.0 : Math.Min(0.1, (now - _last).TotalSeconds);
        _last = now;

        var level = Level;
        _clock += dt;
        Step(level, dt);
        InvalidateVisual();
        // Never settles: at rest the pillars breathe (motion.breathing.idle), so the frame loop stays on while visible.
    }

    /// <summary>Advance jitter, heights and glass blend by dt. Returns true when nothing is moving any more.</summary>
    private bool Step(double level, double dt)
    {
        // Frame-rate independent lerp with the token time constant.
        var k = 1 - Math.Exp(-dt * 1000 / Tokens.Motion.PillarLerpMs);
        var kSpeak = 1 - Math.Exp(-dt * 1000 / Tokens.Motion.BaseMs);
        var speakingTarget = level >= Tokens.Pillar.SpeakingThreshold ? 1.0 : 0.0;
        _speaking += (speakingTarget - _speaking) * kSpeak;

        var moving = false;
        for (var i = 0; i <= Half; i++)
        {
            // Jitter: slow random walk toward a new target, mirrored so symmetry holds.
            if (Math.Abs(_jitter[i] - _jitterTarget[i]) < 0.005)
                _jitterTarget[i] = (_rng.NextDouble() * 2 - 1) * Tokens.Pillar.Jitter;
            _jitter[i] += (_jitterTarget[i] - _jitter[i]) * k * 0.5;

            // Resting shape (idleLevel) that breathes slowly; voice adds on top of it.
            var breath = Math.Sin(_clock * 2 * Math.PI * 1000 / Tokens.Motion.BreathingMs) * Tokens.Motion.BreathingAmplitude;
            var drive = Tokens.Pillar.IdleLevel * (1 + breath) + (1 - Tokens.Pillar.IdleLevel) * level;
            var target = Tokens.Pillar.MinHeight + (Tokens.Pillar.MaxHeight - Tokens.Pillar.MinHeight)
                         * drive * _envelope[i] * (1 + _jitter[i] * Math.Min(1, level * 4));
            _height[i] += (target - _height[i]) * k;
            _height[N - 1 - i] = _height[i];
            if (Math.Abs(target - _height[i]) > 0.05) moving = true;
        }
        return !moving && Math.Abs(speakingTarget - _speaking) < 0.01;
    }

    protected override void OnRender(DrawingContext dc)
    {
        var w = Tokens.Pillar.Width;
        var gap = Tokens.Pillar.Gap;
        var totalW = N * w + (N - 1) * gap;
        var x0 = (ActualWidth - totalW) / 2;
        var cy = ActualHeight / 2;
        var r = w / 2;

        // Glow: token shadow.glow, alpha scaled by level and the glass blend. Drawn as soft stacked halos.
        var glowAlpha = Tokens.Shadow.GlowAlpha * _speaking * Math.Min(1, Level * 1.5);
        if (glowAlpha > 0.005)
        {
            var blur = Tokens.Shadow.GlowBlur;
            for (var i = 0; i < N; i++)
            {
                var h = _height[i];
                var x = x0 + i * (w + gap);
                for (var ring = 3; ring >= 1; ring--)
                {
                    var spread = blur * ring / 3.0;
                    var a = glowAlpha / (ring * 3.0);
                    var c = Tokens.Color.AccentIce; c.A = (byte)(a * 255);
                    var brush = new SolidColorBrush(c); brush.Freeze();
                    dc.DrawRoundedRectangle(brush, null, new Rect(x - spread, cy - h / 2 - spread, w + 2 * spread, h + 2 * spread), r + spread, r + spread);
                }
            }
        }

        for (var i = 0; i < N; i++)
        {
            var h = _height[i];
            var x = x0 + i * (w + gap);
            var rect = new Rect(x, cy - h / 2, w, h);

            dc.DrawRoundedRectangle(IdleBrush, null, rect, r, r);
            if (_speaking > 0.01)
            {
                dc.PushOpacity(_speaking);
                dc.DrawRoundedRectangle(GlassBrush, EdgePen, rect, r, r);
                // Inner highlight: a short vertical stroke inside the left edge, top portion only.
                var hx = x + w * 0.32;
                var top = rect.Top + r * 0.9;
                var bottom = rect.Top + Math.Max(r * 1.2, h * Tokens.Pillar.HighlightCoverage);
                dc.DrawLine(HighlightPen, new Point(hx, top), new Point(hx, bottom));
                dc.Pop();
            }
        }
    }
}
