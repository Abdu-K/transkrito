using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Transkrito.Engine;
using Transkrito.Settings;
using Transkrito.Storage;

namespace Transkrito.Views;

public sealed record LanguageChoice(string Id, string Label);

public partial class SettingsPage : UserControl
{
    private static readonly LanguageChoice[] Languages =
    {
        new(Lang.Auto, "Auto \u2014 Recommended"),
        new(Lang.En, Lang.Display(Lang.En)),
        new(Lang.De, Lang.Display(Lang.De)),
        new(Lang.Ar, Lang.Display(Lang.Ar)),
    };

    private AppController? _app;
    private CancellationTokenSource? _download;
    private bool _loading = true;

    public SettingsPage()
    {
        InitializeComponent();
        DataContextChanged += (_, _) => Attach();
    }

    private void Attach()
    {
        if (DataContext is not AppController app || ReferenceEquals(app, _app)) return;
        _app = app;
        app.PropertyChanged += (_, ev) => { if (ev.PropertyName == nameof(AppController.Status)) RefreshModelStatus(); };
        _loading = true;
        HotkeyBox.Text = app.Settings.Hotkey.Display();
        ModeHold.IsChecked = app.HoldToTalk;
        ModeToggle.IsChecked = !app.HoldToTalk;
        UpdateModeHint();
        FillDevices();
        LanguageBox.ItemsSource = Languages;
        LanguageBox.SelectedItem = Languages.First(l => l.Id == app.Language);
        ModelBox.ItemsSource = ModelCatalog.All;
        ModelBox.SelectedItem = app.Model;
        InsertBox.IsChecked = app.Settings.InsertAtCursor;
        DataPath.Text = AppPaths.DataDir;
        RefreshModelStatus();
        _loading = false;
    }

    // ---- Hotkey ----
    private void OnHotkeyFocus(object sender, KeyboardFocusChangedEventArgs e) { HotkeyBox.Text = ""; HotkeyHint.Text = "Press a combination… Esc cancels."; }
    private void OnHotkeyBlur(object sender, KeyboardFocusChangedEventArgs e)
    {
        if (_app is null) return;
        HotkeyBox.Text = _app.Settings.Hotkey.Display();
        HotkeyHint.Text = "Works in any app. Esc cancels.";
    }

    private void OnHotkeyKey(object sender, KeyEventArgs e)
    {
        if (_app is null) return;
        e.Handled = true;
        var key = e.Key == Key.System ? e.SystemKey : e.Key;
        if (key == Key.Escape) { Keyboard.ClearFocus(); return; }
        if (key is Key.LeftCtrl or Key.RightCtrl or Key.LeftAlt or Key.RightAlt or Key.LeftShift or Key.RightShift or Key.LWin or Key.RWin) return;

        var mods = new List<string>();
        if (Keyboard.Modifiers.HasFlag(ModifierKeys.Control)) mods.Add("control");
        if (Keyboard.Modifiers.HasFlag(ModifierKeys.Alt)) mods.Add("alt");
        if (Keyboard.Modifiers.HasFlag(ModifierKeys.Shift)) mods.Add("shift");
        if (Keyboard.Modifiers.HasFlag(ModifierKeys.Windows)) mods.Add("win");
        if (mods.Count == 0 && key is not (>= Key.F1 and <= Key.F24))
        {
            HotkeyHint.Text = "Add a modifier (Ctrl, Alt, Shift or Win), or use a function key.";
            return;
        }

        var hk = new HotkeySetting { Key = key.ToString(), Modifiers = mods };
        _app.Settings.Hotkey = hk;
        _app.Settings.Save();
        _app.HotkeyChanged();
        ((App)Application.Current).ApplyHotkey(hk);
        Keyboard.ClearFocus();
    }

    private void OnModeChanged(object sender, RoutedEventArgs e)
    {
        if (_loading || _app is null) return;
        _app.HoldToTalk = ModeHold.IsChecked == true;
        UpdateModeHint();
    }

    private void UpdateModeHint() =>
        ModeHint.Text = ModeHold.IsChecked == true
            ? "Hold the keys while you speak; let go and the text is pasted."
            : "Press once to start, press again to stop.";

    // ---- Microphone ----
    private void FillDevices()
    {
        if (_app is null) return;
        var devices = AudioCapture.Devices();
        DeviceBox.ItemsSource = devices;
        DeviceBox.SelectedItem = devices.FirstOrDefault(d => d.Id == _app.Settings.InputDevice) ?? devices[0];
    }

    private void OnDeviceOpened(object sender, EventArgs e)
    {
        // Re-enumerate so a mic plugged in after launch shows up.
        var wasLoading = _loading; _loading = true;
        FillDevices();
        _loading = wasLoading;
    }

    private void OnDeviceChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || _app is null || DeviceBox.SelectedItem is not MicDevice d) return;
        _app.InputDeviceId = d.Id;
    }

    // ---- Language ----
    private void OnLanguageChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || _app is null || LanguageBox.SelectedItem is not LanguageChoice c) return;
        _app.Language = c.Id;
        RefreshModelStatus();
    }

    // ---- Model ----
    /// <summary>Status rows describe the model that will actually run for the current language.</summary>
    private ModelInfo Selected => _app?.EffectiveModel ?? ModelCatalog.Default;

    private void OnModelChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || _app is null) return;
        _app.Model = Selected;
        RefreshModelStatus();
    }

    private void RefreshModelStatus()
    {
        if (_app is null) return;
        var m = Selected;
        var installed = m.IsInstalled;
        ModelStatus.Text = installed ? $"{m.Name} downloaded · on this PC" : $"{m.Name} not downloaded (about {m.ApproxMb} MB)";
        DownloadButton.Visibility = installed || _download is not null ? Visibility.Collapsed : Visibility.Visible;
        RemoveButton.Visibility = installed && _download is null ? Visibility.Visible : Visibility.Collapsed;
        CancelButton.Visibility = _download is not null ? Visibility.Visible : Visibility.Collapsed;
        ProgressTrack.Visibility = _download is not null ? Visibility.Visible : Visibility.Collapsed;
        BiasStatus.Text = _app.Engine.BiasStatus;
    }

    private async void OnDownload(object sender, RoutedEventArgs e)
    {
        if (_app is null) return;
        var m = Selected;
        _download = new CancellationTokenSource();
        RefreshModelStatus();
        var progress = new Progress<(long done, long total)>(p =>
        {
            if (p.done < 0) { ModelStatus.Text = "Extracting…"; Progress.Width = ProgressTrack.ActualWidth; return; }
            var frac = p.total > 0 ? (double)p.done / p.total : 0;
            ModelStatus.Text = p.total > 0 ? $"Downloading {p.done / 1048576} / {p.total / 1048576} MB" : $"Downloading {p.done / 1048576} MB";
            Progress.Width = Math.Max(0, ProgressTrack.ActualWidth * frac);
        });
        try
        {
            await ModelManager.DownloadAsync(m, progress, _download.Token);
            if (_app.EffectiveModel.Id == m.Id) await _app.LoadModelAsync();
        }
        catch (OperationCanceledException) { ModelStatus.Text = "Cancelled"; }
        catch (Exception ex) { ModelStatus.Text = $"Download failed: {ex.Message}"; }
        finally
        {
            _download = null;
            Progress.Width = 0;
            RefreshModelStatus();
        }
    }

    private void OnCancelDownload(object sender, RoutedEventArgs e) => _download?.Cancel();

    private void OnRemoveModel(object sender, RoutedEventArgs e)
    {
        if (_app is null) return;
        var m = Selected;
        if (_app.EffectiveModel.Id == m.Id) _app.Engine.Dispose();
        try { ModelManager.Delete(m); } catch (Exception ex) { ModelStatus.Text = ex.Message; }
        RefreshModelStatus();
        if (_app.EffectiveModel.Id == m.Id) _app.SetStatus($"{m.Name} not downloaded — open Settings", error: true);
    }

    // ---- Insert ----
    private void OnInsertChanged(object sender, RoutedEventArgs e)
    {
        if (_loading || _app is null) return;
        _app.Settings.InsertAtCursor = InsertBox.IsChecked == true;
        _app.Settings.Save();
    }

    private void OnOpenFolder(object sender, RoutedEventArgs e) =>
        Process.Start(new ProcessStartInfo("explorer.exe", AppPaths.DataDir) { UseShellExecute = true });
}
