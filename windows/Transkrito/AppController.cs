using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Threading;
using Transkrito.Dictionary;
using Transkrito.Engine;
using Transkrito.History;
using Transkrito.Insert;
using Transkrito.Settings;
using Transkrito.Storage;

namespace Transkrito;

public enum RecordingState { Idle, Listening, Transcribing }

/// <summary>
/// The one object views bind to. Owns the recording state machine (shared/SPEC.md) and wires
/// hotkey → audio → engine → correction pass → history → clipboard/insert.
/// </summary>
public sealed class AppController : INotifyPropertyChanged, IDisposable
{
    public event PropertyChangedEventHandler? PropertyChanged;

    public DictionaryStore Dictionary { get; }
    public HistoryStore History { get; }
    public AppSettings Settings { get; }
    public ParakeetEngine Engine { get; } = new();
    public AudioCapture Audio { get; } = new();

    private RecordingState _state = RecordingState.Idle;
    private string _status = "Ready";
    private bool _statusIsError;
    private double _level;
    private ModelInfo _model;
    private string? _hotkeyError;
    private DateTime _listeningSince;

    public AppController()
    {
        AppPaths.EnsureDirs();
        Settings = AppSettings.Load();
        Dictionary = new DictionaryStore();
        History = new HistoryStore();
        _model = ModelCatalog.Get(Settings.Model);
        Audio.DeviceId = Settings.InputDevice;
        Dictionary.Changed += () => Engine.SetBiasTerms(Bias.Terms(Dictionary.Entries));
        Audio.LevelChanged += l => Application.Current?.Dispatcher.BeginInvoke(() => Level = l);
        Audio.Failed += ex => Application.Current?.Dispatcher.BeginInvoke(() => SetStatus($"Microphone error: {ex.Message}", error: true));
    }

    // ---- State ----

    public RecordingState State
    {
        get => _state;
        private set
        {
            if (_state == value) return;
            _state = value;
            OnChanged(); OnChanged(nameof(IsListening)); OnChanged(nameof(IsIdle)); OnChanged(nameof(IsTranscribing)); OnChanged(nameof(ActionLabel));
        }
    }
    public bool IsListening => State == RecordingState.Listening;
    public bool IsTranscribing => State == RecordingState.Transcribing;
    public bool IsIdle => State == RecordingState.Idle;
    public string ActionLabel => State == RecordingState.Listening ? "Stop" : "Start";

    public string Status { get => _status; private set { _status = value; OnChanged(); } }
    public bool StatusIsError { get => _statusIsError; private set { _statusIsError = value; OnChanged(); } }
    public double Level { get => _level; private set { _level = value; OnChanged(); } }

    public void SetStatus(string text, bool error = false) { Status = text; StatusIsError = error; }

    // ---- Settings-facing ----

    public ModelInfo Model
    {
        get => _model;
        set { _model = value; Settings.Model = value.Id; Settings.Save(); OnChanged(); _ = LoadModelAsync(); }
    }

    public string HotkeyLabel => Settings.Hotkey.Display();
    public string HotkeyHint => Settings.HoldToTalk ? "Hold to dictate" : "Press to start, press to stop";
    public string HoldToTalkVerb => Settings.HoldToTalk ? "Hold" : "Press";
    public bool HoldToTalk
    {
        get => Settings.HoldToTalk;
        set { Settings.HotkeyMode = value ? "hold" : "toggle"; Settings.Save(); OnChanged(); OnChanged(nameof(HotkeyHint)); OnChanged(nameof(HoldToTalkVerb)); }
    }

    /// <summary>Set when the keyboard hook could not be installed. Shown in place of the hotkey hint.</summary>
    public string? HotkeyError
    {
        get => _hotkeyError;
        set { _hotkeyError = value; OnChanged(); OnChanged(nameof(HotkeyHasError)); }
    }
    public bool HotkeyHasError => HotkeyError is not null;
    public void HotkeyChanged() { OnChanged(nameof(HotkeyLabel)); }

    public string InputDeviceId
    {
        get => Settings.InputDevice;
        set { Settings.InputDevice = value; Settings.Save(); Audio.DeviceId = value; OnChanged(); }
    }

    // ---- Model ----

    /// <summary>Called once at startup and whenever the model changes.</summary>
    public async Task LoadModelAsync()
    {
        if (!Model.IsInstalled)
        {
            SetStatus("Model not downloaded — open Settings", error: true);
            return;
        }
        SetStatus("Loading model…");
        try
        {
            await Engine.LoadAsync(Model);
            Engine.SetBiasTerms(Bias.Terms(Dictionary.Entries));
            SetStatus("Ready");
        }
        catch (Exception ex)
        {
            SetStatus($"Model failed to load: {ex.Message}", error: true);
        }
    }

    // ---- Hotkey entry points ----

    /// <summary>Chord pressed. Hold mode: start. Toggle mode: start or stop.</summary>
    public void HotkeyDown()
    {
        if (Settings.HoldToTalk) Start();
        else Toggle();
    }

    /// <summary>Chord released. Hold mode: stop (a tap shorter than the guard is treated as a mis-press).</summary>
    public void HotkeyUp()
    {
        if (!Settings.HoldToTalk) return;
        if (State != RecordingState.Listening) return;
        _ = StopAsync();
    }

    public void Toggle()
    {
        switch (State)
        {
            case RecordingState.Idle: Start(); break;
            case RecordingState.Listening: _ = StopAsync(); break;
        }
    }

    public void Start()
    {
        if (State != RecordingState.Idle) return;
        if (!Engine.IsLoaded)
        {
            SetStatus(Model.IsInstalled ? "Model is still loading" : "Model not downloaded — open Settings", error: true);
            return;
        }
        try
        {
            Audio.Start();
            _listeningSince = DateTime.UtcNow;
            State = RecordingState.Listening;
            SetStatus("Listening");
        }
        catch (Exception ex)
        {
            SetStatus($"Microphone unavailable: {ex.Message}", error: true);
        }
    }

    public async Task StopAsync()
    {
        if (State != RecordingState.Listening) return;
        var (samples, duration) = Audio.Stop();
        State = RecordingState.Transcribing;
        SetStatus("Transcribing…");
        try
        {
            var raw = await Engine.TranscribeAsync(samples);
            if (string.IsNullOrWhiteSpace(raw))
            {
                SetStatus(duration < 0.4 ? "Hold the key while you speak" : "Nothing heard");
                return;
            }
            var (text, events) = CorrectionEngine.Apply(raw, Dictionary.Entries);
            var item = new Transcription
            {
                Raw = raw,
                Text = text,
                DurationSec = Math.Round(duration, 2),
                Engine = "parakeet",
                Model = Model.Id,
                Corrections = events.Select(CorrectionRecord.From).ToList(),
            };
            History.Add(item);
            ClearNewLater(item);
            Inserter.CopyToClipboard(text);
            if (Settings.InsertAtCursor) Inserter.PasteIntoForegroundApp();
            SetStatus(events.Count == 0 ? "Copied" : $"Copied · {item.CorrectionLabel}");
        }
        catch (Exception ex)
        {
            SetStatus($"Transcription failed: {ex.Message}", error: true);
        }
        finally
        {
            State = RecordingState.Idle;
            Level = 0;
        }
    }

    /// <summary>New rows stay tinted until noticed (motion.rowHighlight), then settle.</summary>
    private static void ClearNewLater(Transcription t)
    {
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(Design.Tokens.Motion.RowHighlightMs) };
        timer.Tick += (_, _) => { t.IsNew = false; timer.Stop(); };
        timer.Start();
    }

    private void OnChanged([CallerMemberName] string? name = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    public void Dispose()
    {
        Audio.Dispose();
        Engine.Dispose();
        Dictionary.Dispose();
    }
}
