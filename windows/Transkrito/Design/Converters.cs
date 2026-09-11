using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace Transkrito.Design;

public sealed class InverseBoolConverter : IValueConverter
{
    public object Convert(object value, Type t, object p, CultureInfo c) => value is bool b && !b;
    public object ConvertBack(object value, Type t, object p, CultureInfo c) => value is bool b && !b;
}

public sealed class BoolToVisibilityConverter : IValueConverter
{
    public bool Inverse { get; set; }
    public object Convert(object value, Type t, object p, CultureInfo c)
    {
        var b = value is bool v && v;
        if (Inverse) b = !b;
        return b ? Visibility.Visible : Visibility.Collapsed;
    }
    public object ConvertBack(object value, Type t, object p, CultureInfo c) => throw new NotSupportedException();
}

public sealed class NullToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type t, object p, CultureInfo c) => value is null ? Visibility.Collapsed : Visibility.Visible;
    public object ConvertBack(object value, Type t, object p, CultureInfo c) => throw new NotSupportedException();
}

public sealed class StringEmptyToVisibilityConverter : IValueConverter
{
    public bool Inverse { get; set; }
    public object Convert(object value, Type t, object p, CultureInfo c)
    {
        var empty = string.IsNullOrEmpty(value as string);
        if (Inverse) empty = !empty;
        return empty ? Visibility.Visible : Visibility.Collapsed;
    }
    public object ConvertBack(object value, Type t, object p, CultureInfo c) => throw new NotSupportedException();
}

/// <summary>true → 1*, false → 0: collapses a grid column together with its content.</summary>
public sealed class BoolToStarConverter : IValueConverter
{
    public object Convert(object value, Type t, object p, CultureInfo c) =>
        value is bool b && b ? new GridLength(1, GridUnitType.Star) : new GridLength(0);
    public object ConvertBack(object value, Type t, object p, CultureInfo c) => throw new NotSupportedException();
}

/// <summary>Attached placeholder text for the Field style.</summary>
public static class FieldHelper
{
    public static readonly DependencyProperty PlaceholderProperty = DependencyProperty.RegisterAttached(
        "Placeholder", typeof(string), typeof(FieldHelper), new PropertyMetadata(string.Empty));
    public static string GetPlaceholder(DependencyObject d) => (string)d.GetValue(PlaceholderProperty);
    public static void SetPlaceholder(DependencyObject d, string v) => d.SetValue(PlaceholderProperty, v);

    /// <summary>Optional leading icon geometry (from the Icon.* resources).</summary>
    public static readonly DependencyProperty IconProperty = DependencyProperty.RegisterAttached(
        "Icon", typeof(System.Windows.Media.Geometry), typeof(FieldHelper), new PropertyMetadata(null));
    public static System.Windows.Media.Geometry? GetIcon(DependencyObject d) => (System.Windows.Media.Geometry?)d.GetValue(IconProperty);
    public static void SetIcon(DependencyObject d, System.Windows.Media.Geometry? v) => d.SetValue(IconProperty, v);
}
