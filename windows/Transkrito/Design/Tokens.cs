// GENERATED from design/tokens.json by design/gen-tokens.py. Do not edit by hand.
using System.Windows.Media;

namespace Transkrito.Design;

/// <summary>Numeric design tokens for code paths (drawing, timing). Brushes live in Tokens.xaml.</summary>
public static class Tokens
{
    public static class Color
    {
        /// <summary>window gradient start (top)</summary>
        public static readonly System.Windows.Media.Color BgTop = System.Windows.Media.Color.FromArgb(255, 211, 227, 244);
        /// <summary>window gradient end (bottom)</summary>
        public static readonly System.Windows.Media.Color BgBottom = System.Windows.Media.Color.FromArgb(255, 242, 246, 251);
        /// <summary>atmospheric radial wash behind the visualization; center (50%, 32%), fades to 0 at radius 55% of window width</summary>
        public static readonly System.Windows.Media.Color BgDeep = System.Windows.Media.Color.FromArgb(46, 30, 63, 102);
        /// <summary>transcript text, titles</summary>
        public static readonly System.Windows.Media.Color InkPrimary = System.Windows.Media.Color.FromArgb(255, 36, 54, 77);
        /// <summary>labels, timestamps, hints</summary>
        public static readonly System.Windows.Media.Color InkSecondary = System.Windows.Media.Color.FromArgb(255, 91, 110, 134);
        /// <summary>placeholders, disabled</summary>
        public static readonly System.Windows.Media.Color InkTertiary = System.Windows.Media.Color.FromArgb(255, 138, 155, 176);
        /// <summary>text on accent button</summary>
        public static readonly System.Windows.Media.Color InkInverse = System.Windows.Media.Color.FromArgb(255, 244, 248, 252);
        /// <summary>primary action, active toggle, focus ring, links</summary>
        public static readonly System.Windows.Media.Color AccentBase = System.Windows.Media.Color.FromArgb(255, 74, 139, 214);
        /// <summary>speaking pillar body</summary>
        public static readonly System.Windows.Media.Color AccentSoft = System.Windows.Media.Color.FromArgb(255, 156, 196, 234);
        /// <summary>idle pillar body, selection tint</summary>
        public static readonly System.Windows.Media.Color AccentPale = System.Windows.Media.Color.FromArgb(255, 214, 230, 247);
        /// <summary>non-speaking pillar fill</summary>
        public static readonly System.Windows.Media.Color PillarIdle = System.Windows.Media.Color.FromArgb(26, 36, 54, 77);
        /// <summary>speaking pillar gradient top</summary>
        public static readonly System.Windows.Media.Color PillarGlassFillTop = System.Windows.Media.Color.FromArgb(199, 185, 215, 243);
        /// <summary>speaking pillar gradient bottom</summary>
        public static readonly System.Windows.Media.Color PillarGlassFillBottom = System.Windows.Media.Color.FromArgb(158, 143, 188, 233);
        /// <summary>inner stroke, top 40% of pillar</summary>
        public static readonly System.Windows.Media.Color PillarGlassHighlight = System.Windows.Media.Color.FromArgb(140, 255, 255, 255);
        /// <summary>outer refraction edge</summary>
        public static readonly System.Windows.Media.Color PillarGlassEdge = System.Windows.Media.Color.FromArgb(89, 111, 166, 223);
        /// <summary>search/text inputs</summary>
        public static readonly System.Windows.Media.Color FieldBg = System.Windows.Media.Color.FromArgb(128, 255, 255, 255);

        public static readonly System.Windows.Media.Color FieldBorder = System.Windows.Media.Color.FromArgb(26, 36, 54, 77);
        /// <summary>row separators</summary>
        public static readonly System.Windows.Media.Color LineHairline = System.Windows.Media.Color.FromArgb(20, 36, 54, 77);
        /// <summary>delete, mic/model errors</summary>
        public static readonly System.Windows.Media.Color StateDanger = System.Windows.Media.Color.FromArgb(255, 194, 84, 74);
        /// <summary>dictionary 'looks common' warning</summary>
        public static readonly System.Windows.Media.Color StateWarning = System.Windows.Media.Color.FromArgb(255, 183, 121, 31);
        /// <summary>listening indicator (pulses)</summary>
        public static readonly System.Windows.Media.Color StateRecording = System.Windows.Media.Color.FromArgb(255, 74, 139, 214);
    }
    public static class Pillar
    {
        public const double Count = 21;
        public const double Width = 6;
        public const double Gap = 6;
        public const double MinHeight = 8;
        public const double MaxHeight = 120;
        public const double EnvelopeFloor = 0.15;
        public const double Jitter = 0.06;
        public const double SpeakingThreshold = 0.06;
        public const double IdleLevel = 0.12;
        public const double HighlightWidth = 1;
        public const double HighlightCoverage = 0.4;
        public const double EdgeWidth = 0.5;
    }
    public static class Motion
    {
        public const double FastMs = 120;
        public const double BaseMs = 200;
        public const double SlowMs = 320;
        public const double LevelAttackMs = 60;
        public const double LevelReleaseMs = 220;
        public const double PillarLerpMs = 120;
        public const double StatusPulseMs = 1600;
    }
    public static class Shadow
    {
        public const double MenuBlur = 8;
        public const double MenuAlpha = 0.08;
        public const double GlowBlur = 14;
        public const double GlowAlpha = 0.22;
    }
    public static class Bg
    {
        /// <summary>Radial wash: center (0.5, 0.32), radius 0.55 of width, alpha from tokens.</summary>
        public const double DeepCenterX = 0.5, DeepCenterY = 0.32, DeepRadius = 0.55;
        public const double DeepAlpha = 0.18;
    }
    public static class Comp
    {
        public const double FieldPaddingH = 10;
        public const double FieldPaddingV = 6;
        public const double PillHeight = 36;
        public const double CheckSize = 16;
        public const double ChipPaddingH = 8;
        public const double ChipPaddingV = 2;
        public const double ScrollbarWidth = 6;
        public const double PillarsAreaHeight = 160;
        public const double IconSize = 14;
        public const double PillMinWidth = 120;
        public const double TabGap = 24;
        public const double TrayMenuMinWidth = 180;
        public const double SettingsLabelWidth = 120;
    }
    public const int BiasMaxTerms = 40;
}
