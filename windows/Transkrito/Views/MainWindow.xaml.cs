using System.ComponentModel;
using System.Windows;
using System.Windows.Input;

namespace Transkrito.Views;

public partial class MainWindow : Window
{
    public static readonly RoutedCommand OpenSettings = new(nameof(OpenSettings), typeof(MainWindow));
    public static readonly RoutedCommand FocusSearch = new(nameof(FocusSearch), typeof(MainWindow));

    private readonly AppController _app;

    public MainWindow(AppController app)
    {
        _app = app;
        DataContext = app;
        InitializeComponent();
        CommandBindings.Add(new CommandBinding(OpenSettings, (_, _) => ((App)Application.Current).ShowSettings()));
        CommandBindings.Add(new CommandBinding(FocusSearch, (_, _) => ActivePane.FocusSearch()));
    }

    private ISearchable ActivePane => TabDictionary.IsChecked == true ? DictionaryPane : HistoryPane;

    private void OnToggle(object sender, RoutedEventArgs e) => _app.Toggle();

    private void OnTabChanged(object sender, RoutedEventArgs e)
    {
        if (HistoryPane is null || DictionaryPane is null) return;
        var dict = TabDictionary.IsChecked == true;
        HistoryPane.Visibility = dict ? Visibility.Collapsed : Visibility.Visible;
        DictionaryPane.Visibility = dict ? Visibility.Visible : Visibility.Collapsed;
    }

    /// <summary>Closing hides to the tray; the app keeps running for the hotkey. Quit lives in the tray menu.</summary>
    protected override void OnClosing(CancelEventArgs e)
    {
        if (((App)Application.Current).IsQuitting) return;
        e.Cancel = true;
        Hide();
    }
}

public interface ISearchable { void FocusSearch(); }
