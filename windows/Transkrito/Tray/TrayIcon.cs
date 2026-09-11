using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;
using H.NotifyIcon;
using H.NotifyIcon.Core;

namespace Transkrito.Tray;

/// <summary>
/// Secondary surface: status icon + menu for the hotkey workflow while another app is in front.
/// Icon states: idle / listening / transcribing (Assets/tray-*.ico, generated from tokens by design/make-icon.py).
/// </summary>
public sealed class TrayIcon : IDisposable
{
    private readonly TaskbarIcon _icon;
    private readonly AppController _app;
    private readonly MenuItem _toggle;

    public event Action? OpenRequested;
    public event Action? SettingsRequested;
    public event Action? QuitRequested;

    public TrayIcon(AppController app)
    {
        _app = app;
        _toggle = Item("Start Listening", () => _app.Toggle());
        var menu = new ContextMenu { Style = (Style)Application.Current.FindResource("Tray.Menu") };
        menu.Items.Add(_toggle);
        menu.Items.Add(new Separator { Style = (Style)Application.Current.FindResource("Tray.Separator") });
        menu.Items.Add(Item("Open Transkrito", () => OpenRequested?.Invoke()));
        menu.Items.Add(Item("Settings…", () => SettingsRequested?.Invoke()));
        menu.Items.Add(new Separator { Style = (Style)Application.Current.FindResource("Tray.Separator") });
        menu.Items.Add(Item("Quit Transkrito", () => QuitRequested?.Invoke()));

        _icon = new TaskbarIcon
        {
            ToolTipText = "Transkrito",
            ContextMenu = menu,
            MenuActivation = PopupActivationMode.RightClick,
        };
        _icon.TrayLeftMouseUp += (_, _) => OpenRequested?.Invoke();
        _icon.ForceCreate();

        app.PropertyChanged += OnAppChanged;
        Refresh();
    }

    private static MenuItem Item(string header, Action act)
    {
        var mi = new MenuItem { Header = header, Style = (Style)Application.Current.FindResource("Tray.MenuItem") };
        mi.Click += (_, _) => act();
        return mi;
    }

    private void OnAppChanged(object? s, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(AppController.State) or nameof(AppController.HotkeyLabel)) Refresh();
    }

    private void Refresh()
    {
        var state = _app.State switch
        {
            RecordingState.Listening => "listening",
            RecordingState.Transcribing => "transcribing",
            _ => "idle",
        };
        _icon.IconSource = new BitmapImage(new Uri($"pack://application:,,,/Assets/tray-{state}.ico"));
        _icon.ToolTipText = _app.State == RecordingState.Idle ? $"Transkrito · {_app.HotkeyLabel}" : $"Transkrito · {_app.Status}";
        _toggle.Header = (_app.State == RecordingState.Listening ? "Stop Listening" : "Start Listening") + $"\t{_app.HotkeyLabel}";
        _toggle.IsEnabled = _app.State != RecordingState.Transcribing;
    }

    public void Dispose() => _icon.Dispose();
}
