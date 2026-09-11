using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using Transkrito.Settings;

namespace Transkrito.Hotkey;

/// <summary>Global hotkey via RegisterHotKey on a hidden message-only window. Works while any app is in front.</summary>
public sealed class HotkeyManager : IDisposable
{
    private const int WM_HOTKEY = 0x0312;
    private const int Id = 0x5452; // "TR"
    private readonly HwndSource _source;
    private bool _registered;

    public event Action? Pressed;
    public string? LastError { get; private set; }

    public HotkeyManager()
    {
        _source = new HwndSource(new HwndSourceParameters("TranskritoHotkey") { WindowStyle = 0, Width = 0, Height = 0, ParentWindow = new IntPtr(-3) /* HWND_MESSAGE */ });
        _source.AddHook(Hook);
    }

    public bool Register(HotkeySetting hk)
    {
        Unregister();
        var key = KeyInterop.VirtualKeyFromKey(ParseKey(hk.Key));
        uint mods = MOD_NOREPEAT;
        foreach (var m in hk.Modifiers)
            mods |= m switch { "control" => MOD_CONTROL, "alt" => MOD_ALT, "shift" => MOD_SHIFT, "win" => MOD_WIN, _ => 0u };
        _registered = RegisterHotKey(_source.Handle, Id, mods, (uint)key);
        var err = Marshal.GetLastWin32Error();
        LastError = _registered ? null : err == 1409 /* ERROR_HOTKEY_ALREADY_REGISTERED */
            ? $"{hk.Display()} is taken by another app — pick a different hotkey in Settings."
            : $"Hotkey {hk.Display()} could not be registered (error {err}).";
        return _registered;
    }

    public void Unregister()
    {
        if (_registered) UnregisterHotKey(_source.Handle, Id);
        _registered = false;
    }

    public static Key ParseKey(string name) => Enum.TryParse<Key>(name, ignoreCase: true, out var k) ? k : Key.Space;

    private IntPtr Hook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == WM_HOTKEY && wParam.ToInt32() == Id)
        {
            Pressed?.Invoke();
            handled = true;
        }
        return IntPtr.Zero;
    }

    public void Dispose()
    {
        Unregister();
        _source.RemoveHook(Hook);
        _source.Dispose();
    }

    private const uint MOD_ALT = 0x0001, MOD_CONTROL = 0x0002, MOD_SHIFT = 0x0004, MOD_WIN = 0x0008, MOD_NOREPEAT = 0x4000;
    [DllImport("user32.dll", SetLastError = true)] private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll", SetLastError = true)] private static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
