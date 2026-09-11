using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Transkrito.History;
using Transkrito.Insert;

namespace Transkrito.Views;

public sealed record DayGroup(string Label, IReadOnlyList<Transcription> Items);

public partial class DictationPage : UserControl, ISearchable, INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;
    private AppController? _app;
    private bool _micHeld;

    public DictationPage()
    {
        InitializeComponent();
        DataContextChanged += (_, _) => Attach();
    }

    public string EmptyTitle => string.IsNullOrWhiteSpace(SearchBox.Text) ? "Nothing dictated yet" : "No matches";
    public string EmptyHint => string.IsNullOrWhiteSpace(SearchBox.Text)
        ? "Hold the hotkey in any app, speak, let go. The text lands at your cursor and shows up here."
        : "Search looks at the final text and the raw transcript.";

    private void Attach()
    {
        if (DataContext is not AppController app || ReferenceEquals(app, _app)) return;
        _app = app;
        app.History.Items.CollectionChanged += (_, _) => Refresh();
        Refresh();
    }

    private void Refresh()
    {
        if (_app is null) return;
        var items = _app.History.Search(SearchBox.Text).ToList();
        Groups.ItemsSource = items
            .GroupBy(t => t.DayKey)
            .Select(g => new DayGroup(g.First().DayLabel, g.ToList()))
            .ToList();
        Empty.Visibility = items.Count == 0 ? Visibility.Visible : Visibility.Collapsed;

        var (today, words, streak) = _app.History.Stats();
        StatsLine.Text = today == 0
            ? "Nothing dictated today"
            : $"Today · {today} {(today == 1 ? "dictation" : "dictations")} · {words} words" + (streak > 1 ? $" · {streak}-day streak" : "");

        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(EmptyTitle)));
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(EmptyHint)));
    }

    private void OnSearchChanged(object sender, TextChangedEventArgs e) => Refresh();

    // The on-screen mic mirrors the hotkey: hold in hold mode, click in toggle mode.
    private void OnMicDown(object sender, MouseButtonEventArgs e)
    {
        if (_app is null) return;
        _micHeld = true;
        MicButton.CaptureMouse();
        _app.HotkeyDown();
        e.Handled = true;
    }

    private void OnMicUp(object sender, MouseButtonEventArgs e)
    {
        if (_app is null || !_micHeld) return;
        _micHeld = false;
        MicButton.ReleaseMouseCapture();
        _app.HotkeyUp();
        e.Handled = true;
    }

    private void OnMicLeave(object sender, MouseEventArgs e)
    {
        // Mouse capture keeps the release reliable; nothing to do here.
    }

    private void OnCopy(object sender, RoutedEventArgs e)
    {
        if ((sender as Button)?.CommandParameter is Transcription t) { Inserter.CopyToClipboard(t.Text); _app?.SetStatus("Copied"); }
    }

    private void OnDelete(object sender, RoutedEventArgs e)
    {
        if ((sender as Button)?.CommandParameter is Transcription t) _app?.History.Remove(t);
    }

    public void FocusSearch() { SearchBox.Focus(); SearchBox.SelectAll(); }
}
