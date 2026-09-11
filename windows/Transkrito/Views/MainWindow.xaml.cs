using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using Transkrito.Design;

namespace Transkrito.Views;

public partial class MainWindow : Window
{
    public static readonly RoutedCommand OpenSettings = new(nameof(OpenSettings), typeof(MainWindow));
    public static readonly RoutedCommand FocusSearch = new(nameof(FocusSearch), typeof(MainWindow));
    public static readonly RoutedCommand GoDictation = new(nameof(GoDictation), typeof(MainWindow));
    public static readonly RoutedCommand GoDictionary = new(nameof(GoDictionary), typeof(MainWindow));

    private readonly AppController _app;

    public MainWindow(AppController app)
    {
        _app = app;
        DataContext = app;
        InitializeComponent();
        CommandBindings.Add(new CommandBinding(OpenSettings, (_, _) => NavSettings.IsChecked = true));
        CommandBindings.Add(new CommandBinding(GoDictation, (_, _) => NavDictation.IsChecked = true));
        CommandBindings.Add(new CommandBinding(GoDictionary, (_, _) => NavDictionary.IsChecked = true));
        CommandBindings.Add(new CommandBinding(FocusSearch, (_, _) => ActivePane?.FocusSearch()));
        SourceInitialized += (_, _) => ApplyDarkChrome();
        // Dev aid: TRANSKRITO_PAGE=dictionary|settings opens on that page (used for screenshot checks).
        switch (Environment.GetEnvironmentVariable("TRANSKRITO_PAGE"))
        {
            case "dictionary": NavDictionary.IsChecked = true; break;
            case "settings": NavSettings.IsChecked = true; break;
        }
    }

    private ISearchable? ActivePane => NavDictionary.IsChecked == true ? PageDictionary : NavDictation.IsChecked == true ? PageDictation : null;

    public void ShowSettings() => NavSettings.IsChecked = true;

    private void OnNav(object sender, RoutedEventArgs e)
    {
        if (PageDictation is null || PageDictionary is null || PageSettings is null) return;
        Show(PageDictation, NavDictation.IsChecked == true);
        Show(PageDictionary, NavDictionary.IsChecked == true);
        Show(PageSettings, NavSettings.IsChecked == true);
    }

    /// <summary>The one authored moment on navigation: the incoming page fades in over motion.fast, ease-out.</summary>
    private static void Show(UIElement page, bool visible)
    {
        if (!visible) { page.Visibility = Visibility.Collapsed; return; }
        if (page.Visibility == Visibility.Visible) return;
        page.Visibility = Visibility.Visible;
        page.BeginAnimation(OpacityProperty, new System.Windows.Media.Animation.DoubleAnimation(0, 1, TimeSpan.FromMilliseconds(Tokens.Motion.FastMs))
        {
            EasingFunction = new System.Windows.Media.Animation.ExponentialEase { EasingMode = System.Windows.Media.Animation.EasingMode.EaseOut },
        });
    }

    /// <summary>Closing hides to the tray; the app keeps running for the hotkey. Quit lives in the tray menu.</summary>
    protected override void OnClosing(CancelEventArgs e)
    {
        if (((App)Application.Current).IsQuitting) return;
        e.Cancel = true;
        Hide();
    }

    /// <summary>Native title bar in the world's colors (Windows 11 DWM): dark mode + caption painted bg.top.</summary>
    private void ApplyDarkChrome()
    {
        var hwnd = new WindowInteropHelper(this).Handle;
        var dark = 1;
        DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, ref dark, sizeof(int));
        var top = Tokens.Color.BgTop;
        var caption = top.R | (top.G << 8) | (top.B << 16); // COLORREF is BGR
        DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, ref caption, sizeof(int));
        var ink = Tokens.Color.InkSecondary;
        var text = ink.R | (ink.G << 8) | (ink.B << 16);
        DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, ref text, sizeof(int));
    }

    private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20, DWMWA_CAPTION_COLOR = 35, DWMWA_TEXT_COLOR = 36;
    [DllImport("dwmapi.dll")] private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);
}

public interface ISearchable { void FocusSearch(); }
