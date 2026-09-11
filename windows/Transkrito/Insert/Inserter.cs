using System.Runtime.InteropServices;
using System.Windows;

namespace Transkrito.Insert;

/// <summary>Clipboard + optional Ctrl+V into whatever app has focus (the one the hotkey was pressed in).</summary>
public static class Inserter
{
    public static void CopyToClipboard(string text)
    {
        for (var attempt = 0; attempt < 5; attempt++)
        {
            try { Clipboard.SetDataObject(text, true); return; }
            catch (COMException) { Thread.Sleep(30); } // another app holds the clipboard; retry briefly
        }
    }

    /// <summary>Sends Ctrl+V. Skipped when Transkrito itself is in front (nothing sensible to paste into).</summary>
    public static void PasteIntoForegroundApp()
    {
        var fg = GetForegroundWindow();
        if (fg == IntPtr.Zero) return;
        GetWindowThreadProcessId(fg, out var pid);
        if (pid == Environment.ProcessId) return;

        var inputs = new[]
        {
            Key(VK_CONTROL, false), Key(VK_V, false), Key(VK_V, true), Key(VK_CONTROL, true),
        };
        SendInput((uint)inputs.Length, inputs, Marshal.SizeOf<INPUT>());
    }

    private const ushort VK_CONTROL = 0x11;
    private const ushort VK_V = 0x56;
    private const uint INPUT_KEYBOARD = 1;
    private const uint KEYEVENTF_KEYUP = 0x0002;

    private static INPUT Key(ushort vk, bool up) => new()
    {
        type = INPUT_KEYBOARD,
        u = new InputUnion { ki = new KEYBDINPUT { wVk = vk, dwFlags = up ? KEYEVENTF_KEYUP : 0 } },
    };

    [StructLayout(LayoutKind.Sequential)]
    private struct INPUT { public uint type; public InputUnion u; }

    [StructLayout(LayoutKind.Explicit)]
    private struct InputUnion
    {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr dwExtraInfo; }

    [StructLayout(LayoutKind.Sequential)]
    private struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr dwExtraInfo; }

    [DllImport("user32.dll", SetLastError = true)] private static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
}
