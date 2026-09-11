using System.Runtime.InteropServices;
using System.Windows.Input;
using Transkrito.Settings;

namespace Transkrito.Hotkey;

/// <summary>
/// Global hotkey with press AND release events (needed for hold-to-talk), via a low-level keyboard hook.
/// The chord's main key is swallowed so the app in front never sees it; modifiers pass through.
/// The hook runs on the UI thread's message loop, so callbacks arrive on the dispatcher.
/// </summary>
public sealed class HotkeyManager : IDisposable
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100, WM_KEYUP = 0x0101, WM_SYSKEYDOWN = 0x0104, WM_SYSKEYUP = 0x0105;

    private readonly LowLevelKeyboardProc _proc; // kept alive for the hook's lifetime
    private IntPtr _hook;
    private int _mainVk;
    private readonly List<int[]> _modifierVks = new(); // each entry: the left/right VKs that satisfy one required modifier
    private bool _held;

    public event Action? Pressed;
    public event Action? Released;
    public string? LastError { get; private set; }

    public HotkeyManager()
    {
        _proc = Hook;
        _hook = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(null), 0);
        if (_hook == IntPtr.Zero) LastError = $"Keyboard hook failed (error {Marshal.GetLastWin32Error()}).";
    }

    public bool Register(HotkeySetting hk)
    {
        _mainVk = KeyInterop.VirtualKeyFromKey(ParseKey(hk.Key));
        _modifierVks.Clear();
        foreach (var m in hk.Modifiers)
        {
            int[]? vks = m switch
            {
                "control" => new[] { 0xA2, 0xA3 },
                "alt" => new[] { 0xA4, 0xA5 },
                "shift" => new[] { 0xA0, 0xA1 },
                "win" => new[] { 0x5B, 0x5C },
                _ => null,
            };
            if (vks is not null) _modifierVks.Add(vks);
        }
        _held = false;
        if (_hook == IntPtr.Zero) return false;
        LastError = null;
        return true;
    }

    public static Key ParseKey(string name) => Enum.TryParse<Key>(name, ignoreCase: true, out var k) ? k : Key.Space;

    private bool ModifiersDown() => _modifierVks.All(pair => pair.Any(vk => (GetAsyncKeyState(vk) & 0x8000) != 0));

    private IntPtr Hook(int code, IntPtr wParam, IntPtr lParam)
    {
        if (code >= 0 && _mainVk != 0)
        {
            var vk = Marshal.ReadInt32(lParam);
            var msg = wParam.ToInt32();
            var down = msg is WM_KEYDOWN or WM_SYSKEYDOWN;
            var up = msg is WM_KEYUP or WM_SYSKEYUP;

            if (vk == _mainVk)
            {
                if (down && !_held && ModifiersDown())
                {
                    _held = true;
                    Pressed?.Invoke();
                    return (IntPtr)1; // swallow: the app in front must not see the chord's key
                }
                if (down && _held) return (IntPtr)1; // key repeat while held
                if (up && _held)
                {
                    _held = false;
                    Released?.Invoke();
                    return (IntPtr)1;
                }
            }
            else if (up && _held && _modifierVks.Any(pair => pair.Contains(vk)))
            {
                // Letting go of a modifier ends the hold too.
                _held = false;
                Released?.Invoke();
            }
        }
        return CallNextHookEx(_hook, code, wParam, lParam);
    }

    public void Dispose()
    {
        if (_hook != IntPtr.Zero) UnhookWindowsHookEx(_hook);
        _hook = IntPtr.Zero;
    }

    private delegate IntPtr LowLevelKeyboardProc(int code, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll", SetLastError = true)] private static extern IntPtr SetWindowsHookEx(int id, LowLevelKeyboardProc proc, IntPtr hMod, uint threadId);
    [DllImport("user32.dll", SetLastError = true)] private static extern bool UnhookWindowsHookEx(IntPtr hook);
    [DllImport("user32.dll")] private static extern IntPtr CallNextHookEx(IntPtr hook, int code, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int vk);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] private static extern IntPtr GetModuleHandle(string? name);
}
