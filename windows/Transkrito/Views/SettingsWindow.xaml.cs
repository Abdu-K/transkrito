using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Transkrito.Engine;
using Transkrito.Settings;
using Transkrito.Storage;

namespace Transkrito.Views;

public partial class SettingsWindow : Window
{
    private readonly AppController _app;
    private readonly Action<HotkeySetting> _applyHotkey;
    private CancellationTokenSource? _download;
    private bool _loading = true;

    public SettingsWindow(AppController app, Action<HotkeySetting> applyHotkey)
    {
        _app = app;
        _applyHotkey = applyHotkey;
        InitializeComponent();
        HotkeyBox.Text = app.Settings.Hotkey.Display();
        ModelBox.ItemsSource = ModelCatalog.All;
        ModelBox.SelectedItem = app.Model;
        InsertBox.IsChecked = app.Settings.InsertAtCursor;
        DataPath.Text = AppPaths.DataDir;
        RefreshModelStatus();
        _loading = false;
    }

    // ---- Hotkey recorder ----
    private void OnHotkeyFocus(object sender, KeyboardFocusChangedEventArgs e) { HotkeyBox.Text = ""; HotkeyHint.Text = "Press a combination… Esc cancels."; }
    private void OnHotkeyBlur(object sender, KeyboardFocusChangedEventArgs e)
    {
        HotkeyBox.Text = _app.Settings.Hotkey.Display();
        HotkeyHint.Text = "Press to start listening, press again to stop.";
    }

    private void OnHotkeyKey(object sender, KeyEventArgs e)
    {
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
        _applyHotkey(hk);
        Keyboard.ClearFocus();
    }

    // ---- Model ----
    private ModelInfo Selected => (ModelInfo?)ModelBox.SelectedItem ?? ModelCatalog.All[0];

    private void OnModelChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading) return;
        _app.Model = Selected;
        RefreshModelStatus();
    }

    private void RefreshModelStatus()
    {
        var m = Selected;
        var installed = m.IsInstalled;
        ModelStatus.Text = installed ? "Downloaded" : "Not downloaded (about 470 MB)";
        DownloadButton.Visibility = installed || _download is not null ? Visibility.Collapsed : Visibility.Visible;
        RemoveButton.Visibility = installed && _download is null ? Visibility.Visible : Visibility.Collapsed;
        CancelButton.Visibility = _download is not null ? Visibility.Visible : Visibility.Collapsed;
        BiasStatus.Text = _app.Engine.BiasStatus;
    }

    private async void OnDownload(object sender, RoutedEventArgs e)
    {
        var m = Selected;
        _download = new CancellationTokenSource();
        RefreshModelStatus();
        var progress = new Progress<(long done, long total)>(p =>
        {
            if (p.done < 0) { ModelStatus.Text = "Extracting…"; Progress.Width = ActualWidth; return; }
            var frac = p.total > 0 ? (double)p.done / p.total : 0;
            ModelStatus.Text = p.total > 0 ? $"Downloading {p.done / 1048576} / {p.total / 1048576} MB" : $"Downloading {p.done / 1048576} MB";
            Progress.Width = Math.Max(0, (ModelBox.ActualWidth) * frac);
        });
        try
        {
            await ModelManager.DownloadAsync(m, progress, _download.Token);
            if (_app.Model.Id == m.Id) await _app.LoadModelAsync();
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
        var m = Selected;
        if (_app.Model.Id == m.Id) _app.Engine.Dispose();
        try { ModelManager.Delete(m); } catch (Exception ex) { ModelStatus.Text = ex.Message; }
        RefreshModelStatus();
        if (_app.Model.Id == m.Id) _app.SetStatus("Model not downloaded. Open Settings to download it.", error: true);
    }

    // ---- Insert ----
    private void OnInsertChanged(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        _app.Settings.InsertAtCursor = InsertBox.IsChecked == true;
        _app.Settings.Save();
    }

    private void OnOpenFolder(object sender, RoutedEventArgs e) =>
        Process.Start(new ProcessStartInfo("explorer.exe", AppPaths.DataDir) { UseShellExecute = true });
}
