# Transkrito design tokens (v2)

Source of truth: `tokens.json`. Mirrors: `macos/Sources/Transkrito/Design/Tokens.swift`, `windows/Transkrito/Design/Tokens.xaml` + `Tokens.cs`. Change the JSON, run `python design/gen-tokens.py`.

Direction: A listening instrument, not a dashboard. Deep navy → icy cyan atmosphere; the glass capsule pillars are the only living thing; everything else is quiet navy paper with 1px glass edges. One committed dark look; the OS theme is ignored.

Source: User-pinned 'Voice App Design System' board (2026-09-12) + Wispr Flow layout reference.

**No literal values in views.**

## Color

| Token | Value | Use |
|---|---|---|
| `bg.top` | #0B1E3D | window gradient start (top) — blue.900 Midnight |
| `bg.bottom` | #050A14 | window gradient end (bottom) — blue.950 Deep Navy |
| `bg.deep` | #7DD3FC @ 14% | icy wash behind the pillars; center (50%, 28%), fades to 0 at radius 55% of content width |
| `bg.rail` | #050A14 @ 55% | sidebar rail fill over the gradient |
| `ink.primary` | #F0F8FF @ 92% | transcript text, titles — ice.100 |
| `ink.secondary` | #F0F8FF @ 64% | labels, timestamps, hints |
| `ink.tertiary` | #F0F8FF @ 40% | placeholders, disabled, day headers |
| `ink.inverse` | #F0F8FF | text on accent |
| `accent.base` | #3B82F6 | primary action, active nav, focus, links — blue.500 Sky |
| `accent.strong` | #1C4ED8 | pressed, pillar core — blue.700 Cobalt |
| `accent.ice` | #7DD3FC | recording state, glow, highlights — ice.300 |
| `accent.pale` | #3B82F6 @ 18% | selection tint, chip fill, active nav fill |
| `surface.glass1` | #F0F8FF @ 6% | glass fill: fields, hovered rows, secondary buttons |
| `surface.glass2` | #F0F8FF @ 10% | glass fill: raised (popovers, pressed) |
| `surface.glass3` | #F0F8FF @ 16% | glass fill: strong (mic button rest) |
| `line.glass1` | #F0F8FF @ 10% | border.glass.1 — hairlines, field edges |
| `line.glass2` | #F0F8FF @ 20% | border.glass.2 — hovered / raised edges |
| `line.glassStrong` | #F0F8FF @ 40% | border.glass.strong — focused / active edges |
| `pillar.idle` | #F0F8FF @ 18% | resting pillar fill |
| `pillar.glassFillTop` | #7DD3FC @ 95% | speaking pillar gradient top — ice |
| `pillar.glassFillBottom` | #1C4ED8 @ 95% | speaking pillar gradient bottom — cobalt |
| `pillar.glassHighlight` | #FFFFFF @ 70% | inner highlight stroke, top 40% of pillar, left edge |
| `pillar.glassEdge` | #7DD3FC @ 45% | outer refraction edge |
| `field.bg` | → surface.glass1 |  |
| `field.border` | → line.glass1 |  |
| `state.danger` | #F87171 | delete, errors |
| `state.warning` | #FBBF24 | dictionary 'looks common' warning |
| `state.recording` | → accent.ice | listening indicator |
| `state.success` | #7DD3FC | copied confirmation |

## Type (SF Pro / Segoe UI Variable)

| Token | Size/Line | Weight | Tracking | Use |
|---|---|---|---|---|
| `caption` | 12/16 | 400 | 0 | timestamps, hints, chips, day headers (uppercase +0.6 tracking) |
| `body` | 13/18 | 400 | 0 | nav, rows, settings labels |
| `transcript` | 15/22 | 400 | 0 | transcription text |
| `status` | 14/20 | 500 | 0.2 | Ready / Listening / Transcribing |
| `title` | 28/34 | 500 | -0.5 | page titles — type.title.m |
| `mono` | 12/16 | 500 | 0.4 | hotkey glyphs |

## Space (4pt) — s1 4 · s2 8 · s3 12 · s4 16 · s5 24 · s6 32 · s7 48 · s8 64
Rules: {'pageInset': 's6', 'rowPaddingV': 's3', 'rowPaddingH': 's4', 'sectionGap': 's6', 'railInset': 's4'}

## Radius — sm 8 · md 12 · lg 16 · xl 24 · pill 999

## Border — hairline 1px line.glass1 · field 1px line.glass1 · raised 1px line.glass2 · focus 1.5px accent.base@70% · warning 1px state.warning@60%

## Shadow — menu 0 4 12 bg.bottom@45% (shadow.soft.2 — menus, popovers) · soft 0 1 2 bg.bottom@30% (shadow.soft.1 — subtle elevation (mic button)) · glow 0 0 24 accent.ice@45% (speaking pillars + recording mic; alpha scales with level)

## Motion
fast 150ms · base 200ms · slow 300ms · ease standard [0.2, 0, 0, 1] enter [0, 0, 0.2, 1] exit [0.4, 0, 1, 1]
Level EMA attack 60ms / release 220ms · pillar spring response 0.3s damping 0.85 (WPF lerp 120ms) · status pulse 1600ms · breathing 3000ms ±0.05 · new-row highlight holds 1600ms

## Pillars
count 21 · width 8 · gap 7 · minHeight 12 · maxHeight 140 · envelope cos^2(pi * d / (count-1)) where d = distance from center; floor 0.15 · jitter ±0.06 · speaking threshold 0.06 · idleLevel 0.3 (resting height so the envelope shape reads while silent)
`breath = sin(2πt/breathing)·amplitude` · `drive = idleLevel·(1+breath) + (1−idleLevel)·level` · `h_i = min + (max−min)·drive·env_i·(1+jitter_i)`, mirrored around center. Speaking pillars only: glass gradient fill, inner highlight, edge, ice glow ∝ level.

## Layout
window: minWidth=880 minHeight=600 defaultWidth=1040 defaultHeight=720, settings: width=560 height=520, rail: width=220, content: maxWidth=760
Shell: left rail (wordmark · Dictation / Dictionary / Settings · status + hotkey caps at the bottom) + one page. Dictation page: pillars → mic + “Hold ⌃⌥Space anywhere” + one stats line → search → history grouped by day. No cards, no panels; glass only on pillars, fields and the mic.

## Component sizes
fieldPaddingH 12 · fieldPaddingV 8 · pillHeight 36 · pillMinWidth 120 · checkSize 16 · chipPaddingH 8 · chipPaddingV 2 · scrollbarWidth 6 · pillarsAreaHeight 180 · iconSize 16 · tabGap 24 · trayMenuMinWidth 180 · settingsLabelWidth 140 · navItemHeight 36 · micButton 48 · railIconGap 10 · iconSizeLg 20 · iconSizeMd 14 · iconSizeSm 12 · iconStroke 1.75 · popupMaxHeight 280 · checkRadius 4 · tickSize 11 · timeColumn 56 · timeBaselineOffset 3 · rowGap 2 · statusDot 8 · dayHeaderTracking 0.6

## Bias — maxTerms 40 (long context makes speech models drift and invent text on quiet audio)
