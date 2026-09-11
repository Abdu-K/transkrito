using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;

namespace Transkrito.Views;

/// <summary>The hotkey drawn as key caps ("Ctrl" + "Alt" + "D") followed by the mode hint. Reads AppController from DataContext.</summary>
public sealed class HotkeyCaps : StackPanel
{
    private AppController? _app;

    private readonly WrapPanel _caps = new() { Orientation = Orientation.Horizontal };

    public HotkeyCaps()
    {
        Orientation = Orientation.Vertical;
        Children.Add(_caps);
        DataContextChanged += (_, _) => Attach();
    }

    private void Attach()
    {
        if (DataContext is not AppController app) return;
        if (_app is not null) _app.PropertyChanged -= OnChanged;
        _app = app;
        app.PropertyChanged += OnChanged;
        Rebuild();
    }

    private void OnChanged(object? s, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(AppController.HotkeyLabel) or nameof(AppController.HotkeyHint) or nameof(AppController.HotkeyError)) Rebuild();
    }

    private void Rebuild()
    {
        _caps.Children.Clear();
        while (Children.Count > 1) Children.RemoveAt(1);
        if (_app is null) return;
        if (_app.HotkeyError is { } err)
        {
            Children.Add(new TextBlock { Style = (Style)FindResource("Text.Caption"), Foreground = (System.Windows.Media.Brush)FindResource("Brush.StateDanger"), Text = err });
            return;
        }
        var parts = _app.HotkeyLabel.Split('+');
        for (var i = 0; i < parts.Length; i++)
        {
            if (i > 0) _caps.Children.Add(new TextBlock { Style = (Style)FindResource("Text.Caption"), Text = "+", VerticalAlignment = VerticalAlignment.Center, Margin = (Thickness)FindResource("Pad.Gap.S1") });
            _caps.Children.Add(new Border
            {
                Style = (Style)FindResource("KeyCap"),
                Margin = i > 0 ? (Thickness)FindResource("Pad.Gap.S1") : new Thickness(0),
                Child = new TextBlock { Style = (Style)FindResource("Text.Mono"), Foreground = (System.Windows.Media.Brush)FindResource("Brush.InkPrimary"), Text = parts[i] },
            });
        }
        Children.Add(new TextBlock
        {
            Style = (Style)FindResource("Text.Caption"),
            Foreground = (System.Windows.Media.Brush)FindResource("Brush.InkTertiary"),
            Text = _app.HotkeyHint,
            Margin = (Thickness)FindResource("Pad.Below.S1"),
        });
    }
}
