// GENERATED from design/tokens.json by design/gen-tokens.py. Do not edit by hand.
using System.Windows.Media;

namespace Transkrito.Design;

/// <summary>Numeric design tokens for code paths (drawing, timing). Brushes live in Tokens.xaml.</summary>
public static class Tokens
{
    public static class Color
    {
        /// <summary>window gradient start (top) — blue.900 Midnight</summary>
        public static readonly System.Windows.Media.Color BgTop = System.Windows.Media.Color.FromArgb(255, 11, 30, 61);
        /// <summary>window gradient end (bottom) — blue.950 Deep Navy</summary>
        public static readonly System.Windows.Media.Color BgBottom = System.Windows.Media.Color.FromArgb(255, 5, 10, 20);
        /// <summary>icy wash behind the pillars; center (50%, 28%), fades to 0 at radius 55% of content width</summary>
        public static readonly System.Windows.Media.Color BgDeep = System.Windows.Media.Color.FromArgb(36, 125, 211, 252);
        /// <summary>sidebar rail fill over the gradient</summary>
        public static readonly System.Windows.Media.Color BgRail = System.Windows.Media.Color.FromArgb(140, 5, 10, 20);
        /// <summary>transcript text, titles — ice.100</summary>
        public static readonly System.Windows.Media.Color InkPrimary = System.Windows.Media.Color.FromArgb(235, 240, 248, 255);
        /// <summary>labels, timestamps, hints</summary>
        public static readonly System.Windows.Media.Color InkSecondary = System.Windows.Media.Color.FromArgb(163, 240, 248, 255);
        /// <summary>placeholders, disabled, day headers</summary>
        public static readonly System.Windows.Media.Color InkTertiary = System.Windows.Media.Color.FromArgb(102, 240, 248, 255);
        /// <summary>text on accent</summary>
        public static readonly System.Windows.Media.Color InkInverse = System.Windows.Media.Color.FromArgb(255, 240, 248, 255);
        /// <summary>primary action, active nav, focus, links — blue.500 Sky</summary>
        public static readonly System.Windows.Media.Color AccentBase = System.Windows.Media.Color.FromArgb(255, 59, 130, 246);
        /// <summary>pressed, pillar core — blue.700 Cobalt</summary>
        public static readonly System.Windows.Media.Color AccentStrong = System.Windows.Media.Color.FromArgb(255, 28, 78, 216);
        /// <summary>recording state, glow, highlights — ice.300</summary>
        public static readonly System.Windows.Media.Color AccentIce = System.Windows.Media.Color.FromArgb(255, 125, 211, 252);
        /// <summary>selection tint, chip fill, active nav fill</summary>
        public static readonly System.Windows.Media.Color AccentPale = System.Windows.Media.Color.FromArgb(46, 59, 130, 246);
        /// <summary>glass fill: fields, hovered rows, secondary buttons</summary>
        public static readonly System.Windows.Media.Color SurfaceGlass1 = System.Windows.Media.Color.FromArgb(15, 240, 248, 255);
        /// <summary>glass fill: raised (popovers, pressed)</summary>
        public static readonly System.Windows.Media.Color SurfaceGlass2 = System.Windows.Media.Color.FromArgb(26, 240, 248, 255);
        /// <summary>glass fill: strong (mic button rest)</summary>
        public static readonly System.Windows.Media.Color SurfaceGlass3 = System.Windows.Media.Color.FromArgb(41, 240, 248, 255);
        /// <summary>border.glass.1 — hairlines, field edges</summary>
        public static readonly System.Windows.Media.Color LineGlass1 = System.Windows.Media.Color.FromArgb(26, 240, 248, 255);
        /// <summary>border.glass.2 — hovered / raised edges</summary>
        public static readonly System.Windows.Media.Color LineGlass2 = System.Windows.Media.Color.FromArgb(51, 240, 248, 255);
        /// <summary>border.glass.strong — focused / active edges</summary>
        public static readonly System.Windows.Media.Color LineGlassStrong = System.Windows.Media.Color.FromArgb(102, 240, 248, 255);
        /// <summary>resting pillar fill</summary>
        public static readonly System.Windows.Media.Color PillarIdle = System.Windows.Media.Color.FromArgb(46, 240, 248, 255);
        /// <summary>speaking pillar gradient top — ice</summary>
        public static readonly System.Windows.Media.Color PillarGlassFillTop = System.Windows.Media.Color.FromArgb(242, 125, 211, 252);
        /// <summary>speaking pillar gradient bottom — cobalt</summary>
        public static readonly System.Windows.Media.Color PillarGlassFillBottom = System.Windows.Media.Color.FromArgb(242, 28, 78, 216);
        /// <summary>inner highlight stroke, top 40% of pillar, left edge</summary>
        public static readonly System.Windows.Media.Color PillarGlassHighlight = System.Windows.Media.Color.FromArgb(178, 255, 255, 255);
        /// <summary>outer refraction edge</summary>
        public static readonly System.Windows.Media.Color PillarGlassEdge = System.Windows.Media.Color.FromArgb(115, 125, 211, 252);

        public static readonly System.Windows.Media.Color FieldBg = System.Windows.Media.Color.FromArgb(15, 240, 248, 255);

        public static readonly System.Windows.Media.Color FieldBorder = System.Windows.Media.Color.FromArgb(26, 240, 248, 255);
        /// <summary>delete, errors</summary>
        public static readonly System.Windows.Media.Color StateDanger = System.Windows.Media.Color.FromArgb(255, 248, 113, 113);
        /// <summary>dictionary 'looks common' warning</summary>
        public static readonly System.Windows.Media.Color StateWarning = System.Windows.Media.Color.FromArgb(255, 251, 191, 36);
        /// <summary>listening indicator</summary>
        public static readonly System.Windows.Media.Color StateRecording = System.Windows.Media.Color.FromArgb(255, 125, 211, 252);
        /// <summary>copied confirmation</summary>
        public static readonly System.Windows.Media.Color StateSuccess = System.Windows.Media.Color.FromArgb(255, 125, 211, 252);
    }
    public static class Pillar
    {
        public const double Count = 21;
        public const double Width = 8;
        public const double Gap = 7;
        public const double MinHeight = 12;
        public const double MaxHeight = 140;
        public const double EnvelopeFloor = 0.15;
        public const double Jitter = 0.06;
        public const double SpeakingThreshold = 0.06;
        public const double IdleLevel = 0.3;
        public const double HighlightWidth = 1.5;
        public const double HighlightCoverage = 0.4;
        public const double EdgeWidth = 0.75;
    }
    public static class Motion
    {
        public const double FastMs = 150;
        public const double BaseMs = 200;
        public const double SlowMs = 300;
        public const double LevelAttackMs = 60;
        public const double LevelReleaseMs = 220;
        public const double PillarLerpMs = 120;
        public const double StatusPulseMs = 1600;
        public const double BreathingMs = 3000;
        public const double BreathingAmplitude = 0.05;
        public const double RowHighlightMs = 1600;
    }
    public static class Shadow
    {
        public const double MenuBlur = 12;
        public const double MenuDepth = 4;
        public const double MenuAlpha = 0.45;
        public const double SoftBlur = 2;
        public const double SoftDepth = 1;
        public const double SoftAlpha = 0.3;
        public const double GlowBlur = 24;
        public const double GlowDepth = 0;
        public const double GlowAlpha = 0.45;
    }
    public static class Bg
    {
        /// <summary>Radial wash: center (0.5, 0.28), radius 0.55 of width, alpha from tokens.</summary>
        public const double DeepCenterX = 0.5, DeepCenterY = 0.28, DeepRadius = 0.55;
        public const double DeepAlpha = 0.14;
    }
    public static class Comp
    {
        public const double FieldPaddingH = 12;
        public const double FieldPaddingV = 8;
        public const double PillHeight = 36;
        public const double PillMinWidth = 120;
        public const double CheckSize = 16;
        public const double ChipPaddingH = 8;
        public const double ChipPaddingV = 2;
        public const double ScrollbarWidth = 6;
        public const double PillarsAreaHeight = 180;
        public const double IconSize = 16;
        public const double TabGap = 24;
        public const double TrayMenuMinWidth = 180;
        public const double SettingsLabelWidth = 140;
        public const double NavItemHeight = 36;
        public const double MicButton = 48;
        public const double RailIconGap = 10;
        public const double IconSizeLg = 20;
        public const double IconSizeMd = 14;
        public const double IconSizeSm = 12;
        public const double IconStroke = 1.75;
        public const double PopupMaxHeight = 280;
        public const double CheckRadius = 4;
        public const double TickSize = 11;
        public const double TimeColumn = 56;
        public const double TimeBaselineOffset = 3;
        public const double RowGap = 2;
    }
    public const int BiasMaxTerms = 40;
}
