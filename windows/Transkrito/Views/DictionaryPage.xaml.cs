using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Transkrito.Dictionary;

namespace Transkrito.Views;

/// <summary>Editable row / add-form model for one dictionary entry. Recomputes warnings as you type.</summary>
public sealed class EntryRow : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;
    private readonly DictionaryStore _store;
    private bool _isTerm = true, _isEditing;
    private string _hear = "", _write = "";

    public DictionaryEntry? Entry { get; }
    public bool IsNew => Entry is null;

    public EntryRow(DictionaryStore store, DictionaryEntry? entry)
    {
        _store = store;
        Entry = entry;
        if (entry is not null) Reset();
    }

    public void Reset()
    {
        _isTerm = Entry?.IsTerm ?? true;
        _hear = Entry?.HearText ?? "";
        _write = Entry?.IsTerm == false ? Entry.WriteText : "";
        Recompute();
        OnChanged(nameof(IsTerm)); OnChanged(nameof(IsCorrection)); OnChanged(nameof(Hear)); OnChanged(nameof(Write)); OnChanged(nameof(HearPlaceholder));
    }

    public bool IsTerm { get => _isTerm; set { if (value && !_isTerm) { _isTerm = true; OnChanged(); OnChanged(nameof(IsCorrection)); OnChanged(nameof(HearPlaceholder)); Recompute(); } } }
    public bool IsCorrection { get => !_isTerm; set { if (value && _isTerm) { _isTerm = false; OnChanged(); OnChanged(nameof(IsTerm)); OnChanged(nameof(HearPlaceholder)); Recompute(); } } }
    public bool IsEditing { get => _isEditing; set { _isEditing = value; OnChanged(); } }
    public string Hear { get => _hear; set { _hear = value; OnChanged(); Recompute(); } }
    public string Write { get => _write; set { _write = value; OnChanged(); Recompute(); } }

    public string HearPlaceholder => IsTerm ? "Word or phrase, e.g. Anthropic" : "When it hears, e.g. cloud code";
    public string SaveLabel => IsNew ? "Add" : "Save";
    public bool CanSave => Hear.Trim().Length > 0 && (IsTerm || Write.Trim().Length > 0);
    public IReadOnlyList<DictionaryWarning> Warnings { get; private set; } = Array.Empty<DictionaryWarning>();

    private void Recompute()
    {
        Warnings = Hear.Trim().Length == 0
            ? Array.Empty<DictionaryWarning>()
            : DictionaryWarnings.Check(Hear, IsTerm ? null : Write, _store.Entries, Entry?.Id);
        OnChanged(nameof(Warnings)); OnChanged(nameof(CanSave));
    }

    /// <summary>Writes the form into a new or existing entry and persists.</summary>
    public void Commit()
    {
        var e = Entry ?? new DictionaryEntry();
        e.Type = IsTerm ? EntryType.Term : EntryType.Correction;
        if (IsTerm) { e.Text = Hear.Trim(); e.Hear = null; e.Write = null; }
        else { e.Text = null; e.Hear = Hear.Trim(); e.Write = Write.Trim(); }
        if (IsNew) _store.Add(e); else _store.Update();
    }

    private void OnChanged([CallerMemberName] string? n = null) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(n));
}

public partial class DictionaryPage : UserControl, ISearchable, INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;
    private AppController? _app;
    private EntryRow? _add;

    public DictionaryPage()
    {
        InitializeComponent();
        DataContextChanged += (_, _) => Attach();
    }

    public string EmptyMessage => string.IsNullOrWhiteSpace(SearchBox.Text) && FilterAll.IsChecked == true
        ? "Nothing here yet. Add the first word above."
        : "No matches.";

    private void Attach()
    {
        if (DataContext is not AppController app || ReferenceEquals(app, _app)) return;
        _app = app;
        _add = new EntryRow(app.Dictionary, null);
        AddForm.Content = _add;
        app.Dictionary.Changed += Refresh;
        Refresh();
    }

    private void Refresh()
    {
        if (_app is null) return;
        var entries = _app.Dictionary.Search(SearchBox.Text);
        if (FilterWords?.IsChecked == true) entries = entries.Where(e => e.IsTerm);
        else if (FilterCorrections?.IsChecked == true) entries = entries.Where(e => !e.IsTerm);
        var rows = entries.Select(e => new EntryRow(_app.Dictionary, e)).ToList();
        List.ItemsSource = rows;
        Empty.Visibility = rows.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(EmptyMessage)));
    }

    private void OnFilterChanged(object sender, RoutedEventArgs e) => Refresh();

    private static EntryRow? RowOf(object sender) =>
        (sender as Button)?.CommandParameter as EntryRow ?? (sender as FrameworkElement)?.Tag as EntryRow ?? (sender as FrameworkElement)?.DataContext as EntryRow;

    private void OnSave(object sender, RoutedEventArgs e)
    {
        var row = RowOf(sender);
        if (row is null || !row.CanSave) return;
        row.Commit();
        if (row.IsNew) { row.Hear = ""; row.Write = ""; }
        else row.IsEditing = false;
    }

    private void OnCancel(object sender, RoutedEventArgs e)
    {
        var row = RowOf(sender);
        if (row is null) return;
        row.Reset();
        row.IsEditing = false;
    }

    private void OnEdit(object sender, RoutedEventArgs e) { if (RowOf(sender) is { } r) r.IsEditing = true; }

    private void OnDelete(object sender, RoutedEventArgs e)
    {
        if (RowOf(sender) is { Entry: { } entry }) _app?.Dictionary.Remove(entry);
    }

    private void OnEditorKey(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter) { OnSave(sender, e); e.Handled = true; }
        else if (e.Key == Key.Escape && RowOf(sender) is { IsNew: false } row) { row.Reset(); row.IsEditing = false; e.Handled = true; }
    }

    public void FocusSearch() { SearchBox.Focus(); SearchBox.SelectAll(); }
}
