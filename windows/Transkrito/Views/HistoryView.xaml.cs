using System.Collections.Specialized;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Controls;
using Transkrito.History;
using Transkrito.Insert;

namespace Transkrito.Views;

public partial class HistoryView : UserControl, ISearchable, INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;
    private AppController? _app;

    public HistoryView()
    {
        InitializeComponent();
        DataContextChanged += (_, _) => Attach();
    }

    public bool IsEmpty => List.Items.Count == 0;
    public string EmptyMessage => string.IsNullOrWhiteSpace(SearchBox.Text)
        ? "Nothing yet. Press Start or the hotkey and speak."
        : "No matches.";

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
        List.ItemsSource = _app.History.Search(SearchBox.Text).ToList();
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsEmpty)));
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(EmptyMessage)));
    }

    private void OnSearchChanged(object sender, TextChangedEventArgs e) => Refresh();

    private void OnCopy(object sender, RoutedEventArgs e)
    {
        if ((sender as FrameworkElement)?.Tag is Transcription t) Inserter.CopyToClipboard(t.Text);
    }

    private void OnDelete(object sender, RoutedEventArgs e)
    {
        if ((sender as FrameworkElement)?.Tag is Transcription t) _app?.History.Remove(t);
    }

    public void FocusSearch() { SearchBox.Focus(); SearchBox.SelectAll(); }
}
