using System.Windows;
using System.Windows.Threading;
using Transkrito.Hotkey;
using Transkrito.Settings;
using Transkrito.Tray;
using Transkrito.Views;

namespace Transkrito;

public partial class App : Application
{
    private AppController? _app;
    private MainWindow? _main;
    private SettingsWindow? _settings;
    private TrayIcon? _tray;
    private HotkeyManager? _hotkey;
    private Mutex? _single;

    public bool IsQuitting { get; private set; }

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        // One instance: a second launch just surfaces the running window.
        _single = new Mutex(true, "Transkrito.SingleInstance", out var first);
        if (!first)
        {
            NativeMethods.SurfaceExisting();
            Shutdown();
            return;
        }

        DispatcherUnhandledException += (_, ex) =>
        {
            try { File.AppendAllText(Path.Combine(Storage.AppPaths.DataDir, "error.log"), $"{DateTime.Now:O} {ex.Exception}" + Environment.NewLine + Environment.NewLine); } catch { }
            MessageBox.Show(ex.Exception.Message, "Transkrito", MessageBoxButton.OK, MessageBoxImage.Error);
            ex.Handled = true;
        };

        _app = new AppController();
        _main = new MainWindow(_app);

        _hotkey = new HotkeyManager();
        _hotkey.Pressed += () => _app.Toggle();
        ApplyHotkey(_app.Settings.Hotkey);

        _tray = new TrayIcon(_app);
        _tray.OpenRequested += ShowMain;
        _tray.SettingsRequested += ShowSettings;
        _tray.QuitRequested += Quit;

        _main.Show();
        _ = _app.LoadModelAsync();
    }

    public void ApplyHotkey(HotkeySetting hk)
    {
        if (_hotkey is null || _app is null) return;
        _app.HotkeyError = _hotkey.Register(hk) ? null : _hotkey.LastError ?? "Hotkey unavailable";
    }

    public void ShowMain()
    {
        if (_main is null) return;
        _main.Show();
        if (_main.WindowState == WindowState.Minimized) _main.WindowState = WindowState.Normal;
        _main.Activate();
    }

    public void ShowSettings()
    {
        if (_app is null) return;
        if (_settings is { IsLoaded: true }) { _settings.Activate(); return; }
        ShowMain();
        _settings = new SettingsWindow(_app, ApplyHotkey) { Owner = _main };
        _settings.Show();
    }

    public void Quit()
    {
        IsQuitting = true;
        _settings?.Close();
        _main?.Close();
        Shutdown();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _tray?.Dispose();
        _hotkey?.Dispose();
        _app?.Dispose();
        _single?.Dispose();
        base.OnExit(e);
    }
}

internal static class NativeMethods
{
    private const int SW_RESTORE = 9;

    /// <summary>Brings the already-running instance's main window forward.</summary>
    public static void SurfaceExisting()
    {
        var current = Environment.ProcessId;
        foreach (var p in System.Diagnostics.Process.GetProcessesByName("Transkrito"))
        {
            if (p.Id == current || p.MainWindowHandle == IntPtr.Zero) continue;
            ShowWindow(p.MainWindowHandle, SW_RESTORE);
            SetForegroundWindow(p.MainWindowHandle);
        }
    }

    [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr hWnd);
}
