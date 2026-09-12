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
    public AudioCapture Audio { get; } = new();

    /// <summary>The engine for the resolved model; swapped (and the old one released) when model or language changes.</summary>
    public ISpeechEngine Engine { get; private set; }

    private RecordingState _state = RecordingState.Idle;
    private string _status = "Ready";
    private bool _statusIsError;
    private double _level;
    private ModelInfo _model;
    private string? _hotkeyError;
    private DateTime _listeningSince;
    private string? _liveLanguage;          // confident guess from partial text while listening (Auto mode)
    private string? _lastDetected;          // last confident detection, used as a fallback hint
    private ModelInfo _loadedFor = null!;   // which resolved model Engine was created for

    public AppController()
    {
        AppPaths.EnsureDirs();
        Settings = AppSettings.Load();
        Dictionary = new DictionaryStore();
        History = new HistoryStore();
        _model = ModelCatalog.Get(Settings.Model);
        _loadedFor = EffectiveModel;
        Engine = _loadedFor.CreateEngine();
        Engine.PartialText += OnPartialText;
        Audio.DeviceId = Settings.InputDevice;
        Dictionary.Changed += () => Engine.SetBiasTerms(Bias.Terms(Dictionary.Entries));
        Audio.ChunkAvailable += chunk => { if (State == RecordingState.Listening) Engine.Feed(chunk); };
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

    /// <summary>The user's model pick. The model that actually runs is <see cref="EffectiveModel"/>.</summary>
    public ModelInfo Model
    {
        get => _model;
        set { _model = value; Settings.Model = value.Id; Settings.Save(); OnChanged(); OnChanged(nameof(EffectiveModel)); OnChanged(nameof(ModelCompatibility)); _ = LoadModelAsync(); }
    }

    /// <summary>Spoken language setting: auto | en | de | ar. Takes effect on the next recording; no restart.</summary>
    public string Language
    {
        get => Settings.Language;
        set
        {
            if (Settings.Language == value) return;
            Settings.Language = value; Settings.Save();
            OnChanged(); OnChanged(nameof(EffectiveModel)); OnChanged(nameof(ModelCompatibility)); OnChanged(nameof(LanguageHint));
            _ = LoadModelAsync();
        }
    }
    public string LanguageHint => Language == Lang.Auto
        ? "Automatically detects English, German, or Arabic."
        : "Always transcribe using this language.";

    /// <summary>Model resolved from the pick and the language: Parakeet cannot do Arabic or Auto, so those route to Nemotron.</summary>
    public ModelInfo EffectiveModel => ModelCatalog.Resolve(Settings.Model, Settings.Language);
    public string ModelCompatibility => EffectiveModel.Id == Model.Id
        ? ""
        : $"{Model.Name} cannot transcribe {(Language == Lang.Auto ? "in Auto mode" : Lang.Display(Language))} — {EffectiveModel.Name} is used instead.";

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

    /// <summary>Called once at startup and whenever the model pick or the language changes.</summary>
    public async Task LoadModelAsync()
    {
        var target = EffectiveModel;
        if (target.Id != _loadedFor.Id)
        {
            // Release the previous engine so only one model stays resident.
            Engine.PartialText -= OnPartialText;
            Engine.Dispose();
            Engine = target.CreateEngine();
            Engine.PartialText += OnPartialText;
            _loadedFor = target;
            OnChanged(nameof(Engine));
        }
        if (!target.IsInstalled)
        {
            SetStatus($"{target.Name} not downloaded — open Settings", error: true);
            return;
        }
        if (Engine.IsLoaded && Engine.LoadedModel?.Id == target.Id) { SetStatus("Ready"); return; }
        SetStatus("Loading model…");
        try
        {
            await Engine.LoadAsync(target);
            Engine.SetBiasTerms(Bias.Terms(Dictionary.Entries));
            SetStatus("Ready");
        }
        catch (Exception ex)
        {
            SetStatus($"Model failed to load: {ex.Message}", error: true);
        }
    }

    /// <summary>Streaming partial text → live language for the status line ("Listening · Deutsch").</summary>
    private void OnPartialText(string partial)
    {
        if (Settings.Language != Lang.Auto) return;
        var guess = LanguageDetector.Detect(partial);
        if (!guess.IsConfident || guess.Language == _liveLanguage) return;
        _liveLanguage = guess.Language;
        Application.Current?.Dispatcher.BeginInvoke(() =>
        {
            if (State == RecordingState.Listening) SetStatus($"Listening · {Lang.Display(_liveLanguage)}");
        });
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
            SetStatus(EffectiveModel.IsInstalled ? "Model is still loading" : $"{EffectiveModel.Name} not downloaded — open Settings", error: true);
            return;
        }
        try
        {
            _liveLanguage = null;
            Engine.BeginUtterance(Settings.Language == Lang.Auto ? null : Settings.Language);
            Audio.Start();
            _listeningSince = DateTime.UtcNow;
            State = RecordingState.Listening;
            SetStatus(Settings.Language == Lang.Auto ? "Listening" : $"Listening · {Lang.Display(Settings.Language)}");
        }
        catch (Exception ex)
        {
            SetStatus($"Microphone unavailable: {ex.Message}", error: true);
        }
    }

    public async Task StopAsync()
    {
        if (State != RecordingState.Listening) return;
        var (_, duration) = Audio.Stop();
        State = RecordingState.Transcribing;
        SetStatus("Transcribing…");
        try
        {
            var raw = await Engine.EndUtteranceAsync();
            if (string.IsNullOrWhiteSpace(raw))
            {
                SetStatus(duration < 0.4 ? "Hold the key while you speak" : "Nothing heard");
                return;
            }
            var (text, events) = CorrectionEngine.Apply(raw, Dictionary.Entries);
            // Explicit mode: the language is what the user pinned. Auto: what the transcript's script/lexicon says, else unknown.
            var language = Settings.Language == Lang.Auto ? LanguageDetector.ForHistory(raw) : Settings.Language;
            if (language != Lang.Unknown) _lastDetected = language;
            var item = new Transcription
            {
                Raw = raw,
                Text = text,
                DurationSec = Math.Round(duration, 2),
                Engine = EffectiveModel.Kind == EngineKind.NemotronStreaming ? "nemotron" : "parakeet",
                Model = EffectiveModel.Id,
                Language = language,
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
