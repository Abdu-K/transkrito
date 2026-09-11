"""Generates platform token mirrors from design/tokens.json.
  windows/Transkrito/Design/Tokens.xaml   (brushes, doubles, thicknesses, durations)
  windows/Transkrito/Design/Tokens.cs     (numeric constants for code paths)
  macos/Sources/Transkrito/Design/Tokens.swift
Run after editing tokens.json: python design/gen-tokens.py
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = json.load(open(os.path.join(ROOT, "design", "tokens.json"), encoding="utf-8"))
C = T["color"]

def resolve(entry):
    """-> (hex, alpha) resolving `ref` chains; a ref without its own alpha inherits the target's."""
    if "ref" in entry:
        grp, key = entry["ref"].split(".")
        h, a = resolve(C[grp][key])
        return h, entry.get("alpha", a)
    return entry["hex"], entry.get("alpha", 1.0)

def argb(hexs, alpha):
    a = round(alpha * 255)
    return f"#{a:02X}{hexs.lstrip('#').upper()}"

def pascal(*parts):
    return "".join(p[0].upper() + p[1:] for p in parts)

colors = []  # (name, hex, alpha, use)
for grp, items in C.items():
    for key, entry in items.items():
        if not isinstance(entry, dict) or ("hex" not in entry and "ref" not in entry):
            continue
        h, a = resolve(entry)
        colors.append((pascal(grp, key), h, a, entry.get("use", "")))

# ---------------- XAML ----------------
x = ['<!-- GENERATED from design/tokens.json by design/gen-tokens.py. Do not edit by hand. -->',
     '<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"',
     '                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"',
     '                    xmlns:sys="clr-namespace:System;assembly=mscorlib">', '']
x.append('  <!-- Color -->')
for name, h, a, use in colors:
    x.append(f'  <Color x:Key="Color.{name}">{argb(h, a)}</Color>')
x.append('')
for name, h, a, use in colors:
    x.append(f'  <SolidColorBrush x:Key="Brush.{name}" Color="{{StaticResource Color.{name}}}" />')
x.append('')
x.append('  <LinearGradientBrush x:Key="Brush.BgGradient" StartPoint="0,0" EndPoint="0,1">')
x.append('    <GradientStop Color="{StaticResource Color.BgTop}" Offset="0" />')
x.append('    <GradientStop Color="{StaticResource Color.BgBottom}" Offset="1" />')
x.append('  </LinearGradientBrush>')
x.append('  <LinearGradientBrush x:Key="Brush.PillarGlass" StartPoint="0,0" EndPoint="0,1">')
x.append('    <GradientStop Color="{StaticResource Color.PillarGlassFillTop}" Offset="0" />')
x.append('    <GradientStop Color="{StaticResource Color.PillarGlassFillBottom}" Offset="1" />')
x.append('  </LinearGradientBrush>')
x.append('')
x.append('  <!-- Type -->')
fam = T["type"]["family"]["windows"]
x.append(f'  <FontFamily x:Key="Font.Sans">{fam}</FontFamily>')
x.append('  <FontFamily x:Key="Font.Mono">Cascadia Mono, Consolas</FontFamily>')
for key in ("caption", "body", "transcript", "status", "title", "mono"):
    t = T["type"][key]
    n = pascal(key)
    weight = {400: "Normal", 500: "Medium", 600: "SemiBold"}[t["weight"]]
    x.append(f'  <sys:Double x:Key="Type.{n}.Size">{t["size"]}</sys:Double>')
    x.append(f'  <sys:Double x:Key="Type.{n}.Line">{t["line"]}</sys:Double>')
    x.append(f'  <FontWeight x:Key="Type.{n}.Weight">{weight}</FontWeight>')
x.append('')
x.append('  <!-- Space -->')
for k, v in T["space"].items():
    if isinstance(v, (int, float)):
        x.append(f'  <sys:Double x:Key="Space.{k.upper()}">{v}</sys:Double>')
        x.append(f'  <Thickness x:Key="Pad.{k.upper()}">{v}</Thickness>')
x.append('')
x.append('  <!-- Radius -->')
for k, v in T["radius"].items():
    x.append(f'  <CornerRadius x:Key="Radius.{pascal(k)}">{v}</CornerRadius>')
    x.append(f'  <sys:Double x:Key="Radius.{pascal(k)}.Value">{v}</sys:Double>')
x.append('')
x.append('  <!-- Border -->')
for k, v in T["border"].items():
    x.append(f'  <Thickness x:Key="Border.{pascal(k)}">{v["width"]}</Thickness>')
x.append('')
x.append('  <!-- Border widths as doubles -->')
for k, v in T["border"].items():
    x.append(f'  <sys:Double x:Key="Border.{pascal(k)}.Width">{v["width"]}</sys:Double>')
x.append('')
x.append('  <!-- Shadow -->')
for k in ("menu", "soft", "glow"):
    s_ = T["shadow"][k]
    x.append(f'  <sys:Double x:Key="Shadow.{pascal(k)}.Blur">{s_["blur"]}</sys:Double>')
    x.append(f'  <sys:Double x:Key="Shadow.{pascal(k)}.Depth">{s_["y"]}</sys:Double>')
    x.append(f'  <sys:Double x:Key="Shadow.{pascal(k)}.Alpha">{s_["alpha"]}</sys:Double>')
x.append('')
x.append('  <!-- Component -->')
comp = T["component"]
for k, v in comp.items():
    if isinstance(v, (int, float)):
        x.append(f'  <sys:Double x:Key="Comp.{pascal(k)}">{v}</sys:Double>')
x.append(f'  <Thickness x:Key="Pad.Field">{comp["fieldPaddingH"]},{comp["fieldPaddingV"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Chip">{comp["chipPaddingH"]},{comp["chipPaddingV"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.PillH">{T["space"]["s5"]},0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Right.S2">0,0,{T["space"]["s2"]},0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Right.S3">0,0,{T["space"]["s3"]},0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Right.S4">0,0,{T["space"]["s4"]},0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Rail">{T["space"]["s4"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Page">{T["space"]["s6"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.PageX">{T["space"]["s6"]},0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Hero">{T["space"]["s6"]},{T["space"]["s6"] + comp["heroTop"]},{T["space"]["s6"]},{T["space"]["s6"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Gap.S4">{T["space"]["s4"]},0,0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Below.S4">0,{T["space"]["s4"]},0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.RowGap">0,0,0,{comp["rowGap"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.LabelNext">{comp["fieldPaddingH"]},{T["space"]["s5"] + comp["fieldPaddingV"]},{comp["fieldPaddingH"]},{comp["fieldPaddingV"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.TimeOffset">0,{comp["timeBaselineOffset"]},0,0</Thickness>')
x.append(f'  <GridLength x:Key="Comp.TimeColumn.Length">{comp["timeColumn"]}</GridLength>')
x.append(f'  <GridLength x:Key="Layout.Rail.Width.Length">{T["layout"]["rail"]["width"]}</GridLength>')
x.append(f'  <CornerRadius x:Key="Radius.Check">{comp["checkRadius"]}</CornerRadius>')
sp_ = T["space"]
x.append(f'  <Thickness x:Key="Pad.Tabs">0,{sp_["s5"]},0,{sp_["s3"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.TabGap">{comp["tabGap"]},0,0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.RowV">0,{sp_["s3"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Row">{sp_["s4"]},{sp_["s3"]}</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Gap.S1">{sp_["s1"]},0,0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Gap.S2">{sp_["s2"]},0,0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Gap.S3">{sp_["s3"]},0,0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Below.S1">0,{sp_["s1"]},0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Below.S2">0,{sp_["s2"]},0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Below.S3">0,{sp_["s3"]},0,0</Thickness>')
x.append(f'  <Thickness x:Key="Pad.Below.S5">0,{sp_["s5"]},0,0</Thickness>')
deep = C["bg"]["deep"]
x.append('  <RadialGradientBrush x:Key="Brush.BgDeepWash" Center="0.5,0.28" GradientOrigin="0.5,0.28" RadiusX="0.55" RadiusY="0.42">')
x.append('    <GradientStop Color="{StaticResource Color.BgDeep}" Offset="0" />')
x.append('    <GradientStop Color="Transparent" Offset="1" />')
x.append('  </RadialGradientBrush>')
x.append('')
x.append('  <!-- Motion -->')
for k in ("fast", "base", "slow"):
    ms = T["motion"][k]
    x.append(f'  <Duration x:Key="Motion.{pascal(k)}">0:0:0.{ms:03d}</Duration>')
    x.append(f'  <sys:Double x:Key="Motion.{pascal(k)}.Ms">{ms}</sys:Double>')
sp = T["motion"]["statusPulse"]
x.append(f'  <Duration x:Key="Motion.StatusPulse">0:0:{sp["periodMs"]/1000:.3f}</Duration>')
x.append(f'  <sys:Double x:Key="Motion.StatusPulse.Min">{sp["opacityMin"]}</sys:Double>')
x.append(f'  <sys:Double x:Key="Motion.StatusPulse.Max">{sp["opacityMax"]}</sys:Double>')
x.append('')
x.append('  <!-- Layout -->')
for grp, items in T["layout"].items():
    for k, v in items.items():
        x.append(f'  <sys:Double x:Key="Layout.{pascal(grp)}.{pascal(k)}">{v}</sys:Double>')
br = T["motion"]["breathing"]
x.append(f'  <Duration x:Key="Motion.Breathing">0:0:{br["periodMs"]/1000:.3f}</Duration>')
x.append(f'  <sys:Double x:Key="Motion.Breathing.Amplitude">{br["amplitude"]}</sys:Double>')
x.append(f'  <Duration x:Key="Motion.RowHighlight">0:0:{T["motion"]["rowHighlight"]["holdMs"]/1000:.3f}</Duration>')
x.append('')
x.append('</ResourceDictionary>')
os.makedirs(os.path.join(ROOT, "windows", "Transkrito", "Design"), exist_ok=True)
open(os.path.join(ROOT, "windows", "Transkrito", "Design", "Tokens.xaml"), "w", encoding="utf-8").write("\n".join(x) + "\n")

# ---------------- C# ----------------
cs = ['// GENERATED from design/tokens.json by design/gen-tokens.py. Do not edit by hand.',
      'using System.Windows.Media;', '', 'namespace Transkrito.Design;', '',
      '/// <summary>Numeric design tokens for code paths (drawing, timing). Brushes live in Tokens.xaml.</summary>',
      'public static class Tokens', '{']
cs.append('    public static class Color')
cs.append('    {')
for name, h, a, use in colors:
    r, g, b = int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)
    cs.append(f'        /// <summary>{use}</summary>' if use else '')
    cs.append(f'        public static readonly System.Windows.Media.Color {name} = System.Windows.Media.Color.FromArgb({round(a*255)}, {r}, {g}, {b});')
cs.append('    }')
cs = [l for l in cs if l is not None]
cs.append('    public static class Pillar')
cs.append('    {')
p = T["pillars"]
for k in ("count", "width", "gap", "minHeight", "maxHeight"):
    cs.append(f'        public const double {pascal(k)} = {p[k]};')
cs.append(f'        public const double EnvelopeFloor = 0.15;')
cs.append(f'        public const double Jitter = {p["jitter"]};')
cs.append(f'        public const double SpeakingThreshold = {p["speakingThreshold"]};')
cs.append(f'        public const double IdleLevel = {p["idleLevel"]};')
cs.append(f'        public const double RestAlpha = {p["restAlpha"]};')
cs.append(f'        public const double GlowFloor = {p["glowFloor"]};')
cs.append(f'        public const double HighlightInset = {p["highlightInset"]};')
gh = C["pillar"]["glassHighlight"]; ge = C["pillar"]["glassEdge"]
cs.append(f'        public const double HighlightWidth = {gh["width"]};')
cs.append(f'        public const double HighlightCoverage = {gh["coverage"]};')
cs.append(f'        public const double EdgeWidth = {ge["width"]};')
cs.append('    }')
cs.append('    public static class Motion')
cs.append('    {')
m = T["motion"]
for k in ("fast", "base", "slow"):
    cs.append(f'        public const double {pascal(k)}Ms = {m[k]};')
cs.append(f'        public const double LevelAttackMs = {m["level"]["attackMs"]};')
cs.append(f'        public const double LevelReleaseMs = {m["level"]["releaseMs"]};')
cs.append(f'        public const double PillarLerpMs = {m["pillarSpring"]["wpfLerpMs"]};')
cs.append(f'        public const double StatusPulseMs = {m["statusPulse"]["periodMs"]};')
cs.append(f'        public const double BreathingMs = {m["breathing"]["periodMs"]};')
cs.append(f'        public const double BreathingAmplitude = {m["breathing"]["amplitude"]};')
cs.append(f'        public const double RowHighlightMs = {m["rowHighlight"]["holdMs"]};')
cs.append('    }')
cs.append('    public static class Shadow')
cs.append('    {')
for k in ("menu", "soft", "glow"):
    s = T["shadow"][k]
    cs.append(f'        public const double {pascal(k)}Blur = {s["blur"]};')
    cs.append(f'        public const double {pascal(k)}Depth = {s["y"]};')
    cs.append(f'        public const double {pascal(k)}Alpha = {s["alpha"]};')
cs.append('    }')
cs.append('    public static class Bg')
cs.append('    {')
cs.append('        /// <summary>Radial wash: center (0.5, 0.28), radius 0.55 of width, alpha from tokens.</summary>')
cs.append('        public const double DeepCenterX = 0.5, DeepCenterY = 0.28, DeepRadius = 0.55;')
cs.append(f'        public const double DeepAlpha = {C["bg"]["deep"]["alpha"]};')
cs.append('    }')
cs.append('    public static class Comp')
cs.append('    {')
for k, v in T["component"].items():
    if isinstance(v, (int, float)):
        cs.append(f'        public const double {pascal(k)} = {v};')
cs.append('    }')
cs.append(f'    public const int BiasMaxTerms = {T["bias"]["maxTerms"]};')
cs.append('}')
open(os.path.join(ROOT, "windows", "Transkrito", "Design", "Tokens.cs"), "w", encoding="utf-8").write("\n".join(cs) + "\n")

# ---------------- Swift ----------------
sw = ['// GENERATED from design/tokens.json by design/gen-tokens.py. Do not edit by hand.',
      'import SwiftUI', '',
      '/// Design tokens. Every view pulls from here; no literal values in views.',
      'enum Tokens {',
      '    enum Colors {']
for name, h, a, use in colors:
    r, g, b = int(h[1:3], 16)/255, int(h[3:5], 16)/255, int(h[5:7], 16)/255
    if use: sw.append(f'        /// {use}')
    sw.append(f'        static let {name[0].lower()+name[1:]} = Color(.sRGB, red: {r:.4f}, green: {g:.4f}, blue: {b:.4f}, opacity: {a})')
sw.append('    }')
sw.append('    enum TypeScale {')
for key in ("caption", "body", "transcript", "status", "title", "mono"):
    t = T["type"][key]
    weight = {400: ".regular", 500: ".medium", 600: ".semibold"}[t["weight"]]
    design = ".monospaced" if key == "mono" else ".default"
    sw.append(f'        static let {key} = TextStyle(size: {t["size"]}, line: {t["line"]}, weight: {weight}, tracking: {t["tracking"]}, design: {design})')
sw.append('    }')
sw.append('    enum Space {')
for k, v in T["space"].items():
    if isinstance(v, (int, float)):
        sw.append(f'        static let {k}: CGFloat = {v}')
sw.append('    }')
sw.append('    enum Radius {')
for k, v in T["radius"].items():
    sw.append(f'        static let {k}: CGFloat = {v}')
sw.append('    }')
sw.append('    enum Border {')
for k, v in T["border"].items():
    sw.append(f'        static let {k}: CGFloat = {v["width"]}')
sw.append('    }')
sw.append('    enum Shadow {')
for k in ("menu", "soft", "glow"):
    s = T["shadow"][k]
    sw.append(f'        static let {k} = ShadowStyle(x: {s["x"]}, y: {s["y"]}, blur: {s["blur"]}, alpha: {s["alpha"]})')
sw.append('    }')
sw.append('    enum Motion {')
for k in ("fast", "base", "slow"):
    sw.append(f'        static let {k}: Double = {m[k]/1000}')
sw.append(f'        static let levelAttack: Double = {m["level"]["attackMs"]/1000}')
sw.append(f'        static let levelRelease: Double = {m["level"]["releaseMs"]/1000}')
sw.append(f'        static let pillarSpring = Animation.spring(response: {m["pillarSpring"]["response"]}, dampingFraction: {m["pillarSpring"]["damping"]})')
sw.append(f'        /// Time constant for the per-frame Canvas lerp (same feel as the spring, used when we step manually).')
sw.append(f'        static let pillarSpringLerp: Double = {m["pillarSpring"]["wpfLerpMs"]/1000}')
sw.append(f'        static let statusPulse: Double = {sp["periodMs"]/1000}')
sw.append(f'        static let statusPulseMin: Double = {sp["opacityMin"]}')
sw.append(f'        static let statusPulseMax: Double = {sp["opacityMax"]}')
sw.append(f'        static let breathing: Double = {m["breathing"]["periodMs"]/1000}')
sw.append(f'        static let breathingAmplitude: Double = {m["breathing"]["amplitude"]}')
sw.append(f'        static let rowHighlight: Double = {m["rowHighlight"]["holdMs"]/1000}')
e = m["ease"]
for k in ("standard", "enter", "exit"):
    v = e[k]
    sw.append(f'        static let ease{pascal(k)} = Animation.timingCurve({v[0]}, {v[1]}, {v[2]}, {v[3]}, duration: {m["base"]/1000})')
sw.append('    }')
sw.append('    enum Pillar {')
sw.append(f'        static let count = {p["count"]}')
for k in ("width", "gap", "minHeight", "maxHeight"):
    sw.append(f'        static let {k}: CGFloat = {p[k]}')
sw.append('        static let envelopeFloor: Double = 0.15')
sw.append(f'        static let jitter: Double = {p["jitter"]}')
sw.append(f'        static let speakingThreshold: Double = {p["speakingThreshold"]}')
sw.append(f'        static let idleLevel: Double = {p["idleLevel"]}')
sw.append(f'        static let restAlpha: Double = {p["restAlpha"]}')
sw.append(f'        static let glowFloor: Double = {p["glowFloor"]}')
sw.append(f'        static let highlightInset: CGFloat = {p["highlightInset"]}')
sw.append(f'        static let highlightWidth: CGFloat = {gh["width"]}')
sw.append(f'        static let highlightCoverage: CGFloat = {gh["coverage"]}')
sw.append(f'        static let edgeWidth: CGFloat = {ge["width"]}')
sw.append('    }')
sw.append('    enum Bg {')
sw.append('        static let deepCenter = UnitPoint(x: 0.5, y: 0.28)')
sw.append('        static let deepRadius: CGFloat = 0.55')
sw.append('    }')
sw.append('    enum Layout {')
for grp, items in T["layout"].items():
    for k, v in items.items():
        sw.append(f'        static let {grp}{pascal(k)}: CGFloat = {v}')
sw.append('    }')
sw.append('    enum Comp {')
for k, v in T["component"].items():
    if isinstance(v, (int, float)):
        sw.append(f'        static let {k}: CGFloat = {v}')
sw.append('    }')
sw.append(f'    static let biasMaxTerms = {T["bias"]["maxTerms"]}')
sw.append('}')
sw.append('')
sw.append('struct TextStyle {')
sw.append('    let size: CGFloat; let line: CGFloat; let weight: Font.Weight; let tracking: CGFloat; let design: Font.Design')
sw.append('    var font: Font { .system(size: size, weight: weight, design: design) }')
sw.append('    var lineSpacing: CGFloat { max(0, line - size * 1.2) }')
sw.append('}')
sw.append('')
sw.append('struct ShadowStyle { let x: CGFloat; let y: CGFloat; let blur: CGFloat; let alpha: Double }')
sw.append('')
sw.append('extension View {')
sw.append('    /// Applies a type token: font, tracking and line spacing together.')
sw.append('    func textStyle(_ s: TextStyle) -> some View { self.font(s.font).tracking(s.tracking).lineSpacing(s.lineSpacing) }')
sw.append('}')
os.makedirs(os.path.join(ROOT, "macos", "Sources", "Transkrito", "Design"), exist_ok=True)
open(os.path.join(ROOT, "macos", "Sources", "Transkrito", "Design", "Tokens.swift"), "w", encoding="utf-8").write("\n".join(sw) + "\n")
# common-words.txt is shared; SwiftPM resources must live inside the target, so mirror it.
import shutil
os.makedirs(os.path.join(ROOT, "macos", "Sources", "Transkrito", "Resources"), exist_ok=True)
shutil.copyfile(os.path.join(ROOT, "shared", "common-words.txt"), os.path.join(ROOT, "macos", "Sources", "Transkrito", "Resources", "common-words.txt"))
print("tokens generated")
