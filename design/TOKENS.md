# Transkrito design tokens

Source of truth: `tokens.json`. Mirrors: `macos/Sources/Transkrito/Design/Tokens.swift`, `windows/Transkrito/Design/Tokens.xaml` + `Tokens.cs`. Change the JSON first, then the mirrors.

Direction: quiet, minimal, fluid. Icy blue atmosphere, one central pillar visualization, flat everything else. One committed look — system dark mode is ignored. **No literal values in views.**

## Color
| Token | Value | Use |
|---|---|---|
| `bg.top` | `#D3E3F4` | window gradient start |
| `bg.bottom` | `#F2F6FB` | window gradient end |
| `bg.deep` | `#1E3F66` @ 18% → 0 | radial wash behind visualization, center (50%, 32%), radius 55% width |
| `ink.primary` | `#24364D` | transcript text, titles |
| `ink.secondary` | `#5B6E86` | labels, timestamps, hints |
| `ink.tertiary` | `#8A9BB0` | placeholders, disabled |
| `ink.inverse` | `#F4F8FC` | text on accent button |
| `accent.base` | `#4A8BD6` | primary action, active toggle, focus, links |
| `accent.soft` | `#9CC4EA` | speaking pillar body |
| `accent.pale` | `#D6E6F7` | idle pillar body, selection tint |
| `pillar.idle` | ink.primary @ 10% | non-speaking pillar |
| `pillar.glassFillTop/Bottom` | `#B9D7F3` @ 78% → `#8FBCE9` @ 62% | speaking pillar |
| `pillar.glassHighlight` | white @ 55%, 1pt inner, top 40% | soft internal highlight |
| `pillar.glassEdge` | `#6FA6DF` @ 35%, 0.5pt | refraction edge |
| `field.bg` / `field.border` | white @ 50% / ink @ 10% | inputs (flat) |
| `line.hairline` | ink @ 8% | row separators |
| `state.danger` | `#C2544A` | delete, errors |
| `state.warning` | `#B7791F` | dictionary warnings |
| `state.recording` | = accent.base, pulsing | listening |

## Type (SF Pro / Segoe UI Variable)
| Token | Size/Line | Weight | Tracking |
|---|---|---|---|
| `caption` | 11/14 | 400 | 0 |
| `body` | 13/18 | 400 | 0 |
| `transcript` | 15/22 | 400 | 0 |
| `status` | 15/20 | 500 | +0.3 |
| `title` | 20/26 | 500 | −0.2 |
| `mono` | 12/16 | 400 | 0 |

## Space (4pt) — `s1 4 · s2 8 · s3 12 · s4 16 · s5 24 · s6 32 · s7 48 · s8 64`
Window inset s6 · row padding s3/s4 · section gap s7.

## Radius — `sm 6 · md 10 · lg 14 · pill 999`
## Border — `hairline 1 line.hairline · field 1 field.border · focus 1.5 accent@60% · warning 1 state.warning@50%`
## Shadow — `none` (default) · `menu 0 2 8 ink@8%` · `glow 0 0 14 accent@22%` (speaking pillars only)

## Motion
`fast 120ms · base 200ms · slow 320ms` · ease standard (0.2,0,0,1) · enter (0,0,0.2,1) · exit (0.4,0,1,1)
Level meter EMA: attack τ 60ms, release τ 220ms. Pillar spring: response 0.28s, damping 0.85 (WPF: 120ms lerp). Status pulse 1.6s, 0.55↔1.

## Pillars
count 21 · width 6 · gap 6 · minHeight 8 · maxHeight 120 · envelope cos²(π·d/(count−1)) floor 0.15 · jitter ±6% · speaking threshold 0.06.
`h_i = min + (max−min) · level · env_i · (1 + jitter_i)`, mirrored around center.

## Layout
Window min 560×640, default 640×760. Settings 460×360. Structure: status → pillars → Start pill + hotkey hint → History | Dictionary text toggle → flat search field → hairline rows. No sidebar, cards, panels.

## Bias
`maxTerms 40` — long context makes speech models drift and invent text on quiet audio.
