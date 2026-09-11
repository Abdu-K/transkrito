---
name: Transkrito
description: A listening instrument, not a dashboard — navy paper, glass edges, one living thing (the pillars).
colors:
  # CSS #RRGGBBAA. Source of truth is design/tokens.json (hex + alpha); the XAML mirror writes #AARRGGBB.
  bg-top: "#0B1E3D"
  bg-bottom: "#050A14"
  bg-deep: "#7DD3FC24"
  bg-rail: "#050A148C"
  ink-primary: "#F0F8FFEB"
  ink-secondary: "#F0F8FFA3"
  ink-tertiary: "#F0F8FF66"
  ink-inverse: "#F0F8FF"
  accent-base: "#3B82F6"
  accent-strong: "#1C4ED8"
  accent-ice: "#7DD3FC"
  accent-pale: "#3B82F62E"
  surface-glass1: "#F0F8FF0F"
  surface-glass2: "#F0F8FF1A"
  surface-glass3: "#F0F8FF29"
  line-glass1: "#F0F8FF1A"
  line-glass2: "#F0F8FF33"
  line-glass-strong: "#F0F8FF66"
  pillar-idle: "#F0F8FF2E"
  pillar-glass-fill-top: "#7DD3FCF2"
  pillar-glass-fill-bottom: "#1C4ED8F2"
  pillar-glass-highlight: "#FFFFFFB2"
  pillar-glass-edge: "#7DD3FC73"
  state-danger: "#F87171"
  state-warning: "#FBBF24"
  state-recording: "#7DD3FC"
  state-success: "#7DD3FC"
typography:
  caption:
    fontFamily: "Segoe UI Variable Text, Segoe UI (Windows) / SF Pro system (macOS)"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "16px"
    letterSpacing: "0"
  body:
    fontFamily: "Segoe UI Variable Text, Segoe UI (Windows) / SF Pro system (macOS)"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "18px"
    letterSpacing: "0"
  status:
    fontFamily: "Segoe UI Variable Text, Segoe UI (Windows) / SF Pro system (macOS)"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: "20px"
    letterSpacing: "0.2px"
  transcript:
    fontFamily: "Segoe UI Variable Text, Segoe UI (Windows) / SF Pro system (macOS)"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: "22px"
    letterSpacing: "0"
  title:
    fontFamily: "Segoe UI Variable Text, Segoe UI (Windows) / SF Pro system (macOS)"
    fontSize: "28px"
    fontWeight: 500
    lineHeight: "34px"
    letterSpacing: "-0.5px"
  mono:
    fontFamily: "Cascadia Mono, Consolas (Windows) / SF Mono (macOS)"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: "16px"
    letterSpacing: "0.4px"
rounded:
  check: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  pill: "999px"
spacing:
  s1: "4px"
  s2: "8px"
  s3: "12px"
  s4: "16px"
  s5: "24px"
  s6: "32px"
  s7: "48px"
  s8: "64px"
components:
  nav-item:
    backgroundColor: "transparent"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
    height: "36px"
  nav-item-hover:
    backgroundColor: "{colors.surface-glass1}"
    textColor: "{colors.ink-primary}"
  nav-item-active:
    backgroundColor: "{colors.accent-pale}"
    textColor: "{colors.ink-primary}"
  button-mic:
    backgroundColor: "{colors.surface-glass3}"
    textColor: "{colors.ink-primary}"
    rounded: "{rounded.pill}"
    size: "48px"
  button-mic-pressed:
    backgroundColor: "{colors.accent-strong}"
  button-mic-listening:
    backgroundColor: "{colors.accent-base}"
  button-glass:
    backgroundColor: "{colors.surface-glass1}"
    textColor: "{colors.ink-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  button-glass-hover:
    backgroundColor: "{colors.surface-glass2}"
  button-glass-pressed:
    backgroundColor: "{colors.surface-glass3}"
  button-primary:
    backgroundColor: "{colors.accent-base}"
    textColor: "{colors.ink-inverse}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  button-primary-pressed:
    backgroundColor: "{colors.accent-strong}"
  button-icon:
    backgroundColor: "transparent"
    textColor: "{colors.ink-secondary}"
    rounded: "{rounded.sm}"
    padding: "8px"
  button-icon-hover:
    backgroundColor: "{colors.surface-glass2}"
    textColor: "{colors.ink-primary}"
  button-text:
    backgroundColor: "transparent"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.caption}"
    padding: "4px"
  button-text-hover:
    textColor: "{colors.accent-ice}"
  segmented:
    backgroundColor: "{colors.surface-glass1}"
    rounded: "{rounded.md}"
    padding: "4px"
  segment-active:
    backgroundColor: "{colors.surface-glass2}"
    textColor: "{colors.ink-primary}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  field:
    backgroundColor: "{colors.surface-glass1}"
    textColor: "{colors.ink-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "8px 12px"
  field-focus:
    backgroundColor: "{colors.surface-glass2}"
  chip:
    backgroundColor: "{colors.accent-pale}"
    textColor: "{colors.accent-ice}"
    typography: "{typography.caption}"
    rounded: "{rounded.pill}"
    padding: "2px 8px"
  chip-hover:
    backgroundColor: "{colors.surface-glass2}"
  keycap:
    backgroundColor: "{colors.surface-glass1}"
    textColor: "{colors.ink-primary}"
    typography: "{typography.mono}"
    rounded: "{rounded.sm}"
    padding: "2px 8px"
  checkbox:
    backgroundColor: "{colors.surface-glass1}"
    rounded: "{rounded.check}"
    size: "16px"
  checkbox-checked:
    backgroundColor: "{colors.accent-base}"
    textColor: "{colors.ink-inverse}"
  popover:
    backgroundColor: "{colors.bg-top}"
    textColor: "{colors.ink-primary}"
    rounded: "{rounded.md}"
    padding: "4px"
  tooltip:
    backgroundColor: "{colors.bg-top}"
    textColor: "{colors.ink-primary}"
    typography: "{typography.caption}"
    rounded: "{rounded.sm}"
    padding: "2px 8px"
  history-row:
    backgroundColor: "transparent"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  history-row-hover:
    backgroundColor: "{colors.surface-glass1}"
  history-row-new:
    backgroundColor: "{colors.accent-pale}"
---

# Design System: Transkrito

Recorded from the shipped Windows WPF build (verified) and its SwiftUI mirror (unverified on hardware). Every value below is evidenced by `design/tokens.json`, `windows/Transkrito/Design/Styles.xaml`, `macos/Sources/Transkrito/Views/Components.swift`, the four views, `PillarsControl.cs` / `PillarsView.swift`, and the review rasters in `.impeccable/review/`.

## Overview

**Creative North Star: "The Listening Instrument"**

One window, one committed dark look. The ground is deep navy paper (`bg-top` → `bg-bottom`, top to bottom); the only material on it is glass: 1px edges at 10 / 20 / 40% ice-white and fills at 6 / 10 / 16%. Nothing casts a shadow except menus. The 21 glass capsule pillars are the single living element: they breathe at rest, light up cobalt-to-ice when you speak, and glow in proportion to your voice. Everything else — rail, history, dictionary, settings — is quiet text on paper with hairlines, so the eye returns to the instrument.

Refused: the card-grid dashboard, the stats hero, tonal panels, OS light mode. The OS theme is ignored on both platforms; there is no light variant.

**Key Characteristics:**
- Single dark atmosphere; no theme switch, no per-OS palette.
- Glass = border + translucent fill only. No blur anywhere except the mic glow / pillar glow.
- One accent family (Sky `accent-base`, Cobalt `accent-strong`, Ice `accent-ice`); ice is reserved for "alive" states (listening, active nav icon, chip text, links).
- One type family per OS, six roles, 12–28px. No display face.
- Icons are drawn geometry (Windows) or SF Symbols (macOS). Never glyph characters.
- Motion is physical: exponential lerps with token time constants, a 3 s breath, a 1.6 s hold on what just changed.

## Colors

Navy ground, ice ink, one blue accent with an ice highlight. Every color is a named token; views never carry a literal.

### Primary
- **Sky** (`accent-base`, #3B82F6): primary action fill (Add / Save), focused field border, checkbox on, combo open border, transcribing status dot, mic fill while listening, text selection.
- **Cobalt** (`accent-strong`, #1C4ED8): pressed primary / pressed mic, bottom of the speaking-pillar gradient.
- **Ice** (`accent-ice`, #7DD3FC): the "alive" color — listening dot and status text, active nav icon, wordmark mark, chip text, correction lines, text-button hover, caret, download progress, glow color, top of the speaking-pillar gradient.
- **Sky wash** (`accent-pale`, #3B82F6 @ 18%): active nav fill, chip fill, selected combo row, a history row that just landed.

### Neutral
- **Midnight** (`bg-top`, #0B1E3D): window gradient start; also the solid fill of popovers, tooltips and the tray menu; the Windows caption bar.
- **Deep Navy** (`bg-bottom`, #050A14): window gradient end; the shadow color for menus.
- **Icy wash** (`bg-deep`, #7DD3FC @ 14%): radial wash behind the pillars, center (50%, 28%), radius 55% of content width (WPF RadiusY 42%), fades to transparent. Dictation page only.
- **Rail** (`bg-rail`, #050A14 @ 55%): sidebar fill over the gradient, 1px `line-glass1` on its right edge.
- **Ink 92 / 64 / 40** (`ink-primary` / `ink-secondary` / `ink-tertiary`, #F0F8FF @ 92 / 64 / 40%): transcript text and titles / labels, hints, timestamps, status / placeholders, day headers, time column, disabled, idle status dot.
- **Ink on accent** (`ink-inverse`, #F0F8FF): text and checkmark on `accent-base`.
- **Glass fills** (`surface-glass1/2/3`, #F0F8FF @ 6 / 10 / 16%): fields, hovered rows, glass buttons, segmented track, key caps / raised: focused field, pressed glass, hovered icon button, active segment, highlighted menu row, chip hover / strong: mic at rest, pressed glass button.
- **Glass lines** (`line-glass1/2/strong`, #F0F8FF @ 10 / 20 / 40%): hairlines, field and segmented edges, rail edge / hovered field, key cap edge, mic ring at rest, popover and tooltip edge, scrollbar thumb / hovered mic ring, keyboard-focused nav item ring.

### Pillar
- `pillar-idle` (#F0F8FF @ 18%): every pillar at rest.
- `pillar-glass-fill-top` → `pillar-glass-fill-bottom` (#7DD3FC → #1C4ED8, both @ 95%): vertical gradient, speaking only.
- `pillar-glass-highlight` (#FFFFFF @ 70%, 1.5px): inner stroke at 32% of pillar width from the left, from the cap down to 40% of height.
- `pillar-glass-edge` (#7DD3FC @ 45%, 0.75px): outer refraction stroke.

### State
- **Danger** (`state-danger`, #F87171): delete hover, error status dot and text, dictionary load error, hotkey error.
- **Warning** (`state-warning`, #FBBF24): "looks like a common word" line under the dictionary editor; warning field border at 60%.
- **Recording** (`state-recording` → `accent-ice`) and **Success** (`state-success`, #7DD3FC): listening indicator; "Copied" confirmation.

### Named Rules
**The Ice-Is-Alive Rule.** `accent-ice` marks something happening or something the app changed (listening, corrections, active page icon). Static chrome never uses it.
**The Glass-Only Rule.** Surfaces are `surface-glass*` fill plus `line-glass*` border, or nothing. No opaque panels, no cards; the only opaque surfaces are floating (popover, tooltip, tray menu) and they use `bg-top`.
**The Status-Is-Text Rule.** The rail dot changes color, but the status word beside it always says the same thing; color never carries meaning alone.

## Typography

**Body Font:** Segoe UI Variable Text, Segoe UI (Windows) / SF Pro system (macOS)
**Label/Mono Font:** Cascadia Mono, Consolas (Windows) / SF Mono (macOS) — hotkey key caps and the data path only.

**Character:** One quiet system family, regular weight almost everywhere, medium reserved for the title, the status line, the wordmark, day headers and primary-button labels. The transcript sits two sizes above UI text so dictated words read as content and everything else as chrome.

### Hierarchy
- **Title** (500, 28px / 34px, −0.5 tracking): page titles "Dictionary", "Settings". The Dictation page has no title; the pillars are the title.
- **Status** (500, 14px / 20px, +0.2): the hotkey line beside the mic ("Hold Ctrl+Alt+D anywhere") in `ink-primary`.
- **Transcript** (400, 15px / 22px): history row text, wrapping, max width 760.
- **Body** (400, 13px / 18px): nav labels, dictionary rows, settings labels (`ink-secondary`), buttons, segments, fields.
- **Caption** (400, 12px / 16px, `ink-secondary`): hints, timestamps (`ink-tertiary`), chips, status word, tooltip, model status, correction detail lines (`accent-ice`).
- **Day header** (500, 13px, `ink-tertiary`, small caps requested): "Today", "Yesterday", "10 September".
- **Mono** (500, 12px / 16px, +0.4): key caps ("Ctrl", "Alt", "D"), data path (`ink-tertiary`, ellipsis-trimmed).

### Named Rules
**The Two-Weight Rule.** 400 and 500 only. Nothing is bold.
**The No-Display Rule.** 28px is the ceiling. There is no hero type, no wordmark lockup beyond 13px medium next to a 16px waveform mark.

## Layout

Fixed shell, one window, no responsive breakpoints; the window resizes, the rail does not.

- **Window:** default 1040 × 720, min 880 × 600. Background `bg-top` → `bg-bottom` linear, top to bottom. Text rendering: WPF Ideal + ClearType, layout rounding on.
- **Rail:** 220px, `bg-rail` fill, 1px `line-glass1` right edge, inset 16 (`s4`). Top: wordmark (waveform mark in `accent-ice` + "Transkrito" body/medium) with 12×8 padding. Then, 24 (`s5`) below, three nav items 36px high with 4 (`s1`) between. Bottom: status dot (8px) + status caption, then the hotkey as key caps, then the mode hint in `ink-tertiary`.
- **Content column:** page inset 32 (`s6`) on all sides; content max width 760, left-aligned on Dictionary / Settings, centered hero on Dictation.
- **Dictation page:** pillars area 180px tall, centered; 12 (`s3`) below it a two-column line: 48px mic, 16 (`s4`) gap, then status-style hotkey sentence over a caption stats line ("Today · 3 dictations · 41 words · 4-day streak" or "Nothing dictated today"). Below: search field, 12 gap, scrolling history. History groups by day (header, 8 below), rows 12×16 padding, 2px row gap, time column 56px with a 3px baseline nudge, actions column appears on hover. Chip "N corrections" under the text; clicking expands caption lines in `accent-ice` listing each change.
- **Dictionary page:** title, one-line description, 24 gap, editor (segmented "Word or phrase / Correction", then hear-field → write-field → Add/Save), 24 gap, search + segmented filter (All / Words / Corrections), 12 gap, rows. Rows: hear `→` write in body, actions on hover.
- **Settings page:** title, 24 gap, two-column form; label column min 140px, labels `ink-secondary` top-aligned with a 32px step between sections (`Pad.LabelNext` 12,32,12,8). Fields stretch the remaining width. Every control has a caption hint directly beneath it.
- **Windows-only chrome:** native title bar kept, painted via DWM — immersive dark mode on, caption color `bg-top`, caption text `ink-secondary`. Closing hides to the tray; Quit lives in the tray menu.
- **macOS-only chrome:** `.hiddenTitleBar`; the rail wordmark carries 24 (`s5`) top padding to clear the traffic lights; a `MenuBarExtra` mirrors the tray.

### Named Rules
**The One-Column Rule.** Pages are one column of stacked groups separated by `s5`/`s6`. No side-by-side panels, no cards, no grid.
**The Hint-Under-Control Rule.** Every setting control is followed by one caption line that says what it does or cannot do (e.g. the biasing note under Model).

## Elevation & Depth

Flat by material, depth by translucency. Surfaces stack as glass fills over the gradient; edges are 1px lines, not shadows. Exactly three shadow tokens exist and only two are wired:

### Shadow Vocabulary
- **Menu** (`0 4px 12px bg-bottom @ 45%`): combo popover and tray menu only. The single drop shadow in the app.
- **Soft** (`0 1px 2px bg-bottom @ 30%`): tokened for the mic at rest; not applied in either build (see drift line).
- **Glow** (`0 0 24px accent-ice @ 45%`): not a shadow but a halo. Mic while listening (blurred ice disc, −8 margin, opacity 0.45). Pillars while speaking: three stacked rounded halos at spread 8 / 16 / 24 with alpha 0.45 × speaking-blend × min(1, level × 1.5) ÷ (ring × 3). Alpha scales with voice level.

### Named Rules
**The Only-Menus-Drop Rule.** Nothing anchored in the window casts a shadow. Only things that float (popover, tray menu) do.
**The Glow-Is-Level Rule.** The ice glow is never static decoration; its opacity is a function of the live audio level and fades out with the speaking blend (200 ms constant).

## Shapes

Rounded, never sharp, never fully round except pills.

- **8px (`sm`)**: nav item, glass / primary / icon button, segment, key cap, tooltip, scrollbar thumb, popover row, tray menu row.
- **12px (`md`)**: field, combo, segmented track, popover, tray menu, history and dictionary row highlight.
- **4px (`check`)**: checkbox box (16px).
- **Pill (999)**: chip, download progress track (1.5px high), mic (circle, 48px).
- **Capsule pillars**: 8px wide, corner radius = half width, 7px gap, 21 across, heights 12–140.
- **Borders**: 1px everywhere (`hairline`, `field`, `raised`); focus is a border-color change, not a wider ring (`Border.Focus` 1.5px exists and is used only as the progress track height).
- **Hairline** (`Rectangle` 1px `line-glass1`): tray separators, rail edge, macOS rail/content divider.

## Components

Character: quiet glass that brightens one step on hover, two on press, and turns Sky only when it is the action or the focus.

### Icons
- **Windows:** `Path` geometry on a 24-unit grid, 1.75 stroke, round caps and joins, no fill, `Stretch=Uniform`, anti-aliased (no pixel snap). Authored set: Mic, Waveform, Book, Sliders, Copy, Trash, Search, Chevron, Pencil, Check, Folder, Download, Plus, Close. Default color `ink-secondary`; inherits the host's foreground on hover/active.
- **macOS:** SF Symbols at weight `.medium`: `mic`, `mic.fill` (mic button), `waveform`, `book.closed`, `slider.horizontal.3`, `trash`, `chevron.down`.
- **Sizes:** 16 default (nav, field leading icon, row actions on Windows), 20 (mic button), 14 (inline in glass buttons, combo chevron, macOS icon buttons and field icons), 12 (chip chevron; macOS ×0.8).
- **Rule:** never a glyph character (no "×", "✓", "🎤", no icon font). Typed punctuation in running text (`→` between hear/write, `+` between key caps) is text, not an icon.

### Navigation (rail item)
- Shape 8px, 36px tall, 12×8 padding, icon + 12 gap + body label.
- Rest: transparent, `ink-secondary`. Hover: `surface-glass1`, `ink-primary`. Active: `accent-pale` fill, `ink-primary` label, icon `accent-ice`. Keyboard focus: 1px `line-glass-strong` ring.
- Shortcuts: Ctrl+1/2/3 (pages), Ctrl+, (settings), Ctrl+F (search).
- macOS hover animates with `easeStandard` (200 ms, cubic 0.2 0 0 1).

### Mic button
- 48px circle. Rest: `surface-glass3` fill, 1px `line-glass2` ring, 20px mic icon in `ink-primary`. Hover: ring → `line-glass-strong`. Pressed: fill `accent-strong`. Listening: fill `accent-base`, ring `accent-ice`, glow halo at 0.45. Disabled (while transcribing): opacity 0.4.
- Press-and-hold mirrors the hotkey (mouse capture keeps release reliable); in toggle mode a click starts/stops. Tooltip = the mode hint.

### Buttons
- **Glass** (secondary, labelled: Download, Open folder, Cancel): `surface-glass1` + 1px `line-glass1`, 8px, 12×8 padding, body text `ink-primary`. Hover: `surface-glass2` + `line-glass2`. Pressed: `surface-glass3`. Focus: border `accent-base`. Disabled: opacity 0.4. May carry a 14px icon + 8 gap before the label.
- **Primary** (Add / Save): `accent-base` fill, no border, `ink-inverse` medium label. Hover: opacity 0.9. Pressed: `accent-strong`. Disabled: opacity 0.4 (Add is disabled until the field is valid).
- **Icon** (row actions Copy / Delete / Edit): transparent, 8px, 8 padding, 16px icon `ink-secondary`. Hover: `surface-glass2` + `ink-primary`; the danger variant hovers `state-danger`. Keyboard focus: `surface-glass2`. Row actions sit at opacity 0 until the row is hovered.
- **Text** (Cancel, Remove): no chrome, caption `ink-secondary`, 4 padding. Hover: `accent-ice`; danger variant hovers `state-danger`. Accent variant: body size, `accent-ice` at rest. macOS pressed: opacity 0.7.

### Segmented toggle
- Track: `surface-glass1` + 1px `line-glass1`, 12px, 4 padding, left-aligned, hugs content. Segments: 8px, 12×8 padding, body. Rest `ink-secondary`; hover `ink-primary`; selected `surface-glass2` + `ink-primary`. Used for filters (All / Words / Corrections), entry kind (Word or phrase / Correction), hotkey mode (Hold to talk / Press to toggle).

### Field
- `surface-glass1` fill, 1px `line-glass1`, 12px radius, 12×8 padding, body text, optional 16px leading icon in `ink-tertiary` with 8 gap, placeholder `ink-tertiary`. Caret `accent-ice`; selection `accent-base` at 0.5.
- Hover: border `line-glass2`. Focus: border `accent-base`, fill `surface-glass2`. Warning (macOS modifier): border `state-warning` @ 60%; on Windows the warning is a caption line in `state-warning` under the editor. Error: caption line in `state-danger` (dictionary load error, hotkey error in the rail).
- The hotkey field is read-only with a hand cursor; focusing it clears the text and swaps the hint to "Press a combination… Esc cancels."

### Chip ("2 corrections")
- Pill, `accent-pale` fill, caption text `accent-ice`, 8×2 padding, 12px chevron with 4 gap that rotates 180° when open. Hover: `surface-glass2`. Toggles the correction detail lines beneath it.

### Checkbox
- 16px box, 4px radius, `surface-glass1` + 1px `line-glass2`; 11px check stroke in `ink-inverse` hidden at rest. Checked: `accent-base` fill and border, check visible. Focus: border `accent-ice`. Label body, 8 gap.

### Combo
- Closed: same chrome as a field with a 14px chevron in `ink-tertiary` at the right (12 inset). Hover: border `line-glass2`. Open: border `accent-base`.
- Popover: `bg-top` fill, 1px `line-glass2`, 12px, 4 padding, 8 margin, min width = control width, max height 280, menu shadow, fade animation. Rows: 12×8 padding, 8px; highlighted `surface-glass2`; selected `accent-pale`. Rows may pair body name + caption detail ("Parakeet TDT 0.6B v3  25 European languages").

### Scrollbar
- Vertical only (horizontal collapsed). 6px wide, no track, no arrows; thumb `line-glass2` at 8px radius.

### Tooltip
- `bg-top`, 1px `line-glass2`, 8px, 8×2 padding, caption `ink-primary`. No shadow.

### Key caps (hotkey)
- Each modifier and the key is a cap: `surface-glass1` + 1px `line-glass2`, 8px, 8×2 padding, mono `ink-primary`; caps joined by a caption "+" with 4 gaps. macOS uses ⌃ ⌥ ⇧ ⌘ symbols in the caps. Below: the mode hint in caption `ink-tertiary`. On hotkey error the caps are replaced by a caption in `state-danger`.

### Hairline
- 1px `line-glass1` rectangle. Tray separators (4 margin), rail edge, and the macOS rail/content divider.

### Tray menu (Windows) / Menu bar extra (macOS)
- Windows `ContextMenu`: `bg-top`, 1px `line-glass2`, 12px, 4 padding, 8 margin, menu shadow, no system drop shadow. Items min width 180, 12×8 padding, 8px; highlighted `surface-glass2`; disabled `ink-tertiary`. Body type.

### Status (rail bottom)
- 8px dot + caption. Idle: dot `ink-tertiary`, text `ink-secondary`, "Ready". Listening: dot and text `state-recording`, "Listening". Transcribing: dot `accent-base`, "Transcribing…". Error: dot and text `state-danger`. Status copy is a full sentence when it needs to be ("Model not downloaded — open Settings").

### History row
- Transparent, 12px radius, 12×16 padding, 2px gap. Hover: `surface-glass1` and the action buttons fade in. New: `accent-pale` tint held for 1.6 s (`rowHighlight.holdMs`) after the transcription lands, then cleared; macOS animates the tint change with `easeStandard`. Time column caption `ink-tertiary`; text transcript `ink-primary`.

### Pillars (signature)
- 21 capsules, 8 wide, 7 gap, centered in a 180px-tall area (WPF measures width = 21×8 + 20×7 = 308). Heights 12–140, vertically centered around the mid-line.
- **Envelope:** `env_i = max(0.15, cos²(π·d/(N−1)))`, d = distance from center; symmetric, tallest in the middle.
- **Level:** RMS → dB → `clamp((20·log10(rms) + 50) / 50, 0, 1)`, smoothed by an asymmetric EMA with attack 60 ms and release 220 ms (`a = 1 − exp(−dt/τ)`).
- **Breathing:** `breath = sin(2π·t / 3000 ms) × 0.05`; the frame loop never sleeps while visible.
- **Drive:** `drive = 0.3·(1 + breath) + 0.7·level` (idleLevel 0.3 so the envelope shape reads in silence).
- **Jitter:** per-pillar random walk toward a target in ±0.06, mirrored, scaled by `min(1, level×4)` so silence is still.
- **Height:** `target_i = 12 + 128 · drive · env_i · (1 + jitter_i)`; displayed height lerps toward target with `k = 1 − exp(−dt / 120 ms)` (WPF) — the macOS equivalent of `spring(response 0.3, damping 0.85)`.
- **Speaking blend:** target 1 when level ≥ 0.06 else 0, lerped with the 200 ms base constant. At blend 0 every pillar is a `pillar-idle` capsule. As blend rises the glass layer is drawn over it at that opacity: gradient fill, 0.75px `pillar-glass-edge`, 1.5px white highlight from the cap to 40% height at 32% of the width, and the ice glow halos.
- Not hit-testable; nothing is clickable inside the instrument.

### Empty states
- Dictation, no history: body `ink-secondary` "Nothing dictated yet" over caption `ink-tertiary` "Hold the hotkey in any app, speak, let go. The text lands at your cursor and shows up here." Search with no hits: "No matches" / "Search looks at the final text and the raw transcript." Centered, 48 (`s7`) inset.
- Dictionary, empty: caption `ink-tertiary` "Nothing here yet. Add the first word above." Filtered/no hits: "No matches."

### Copy voice
- Sentence case, no exclamation marks, no emoji. Second person, imperative when instructing: "Teach it the words it gets wrong", "Click, then press a combination", "Hold the keys while you speak; let go and the text is pasted."
- Status is a short present-tense word or a plain sentence: "Ready", "Listening", "Transcribing…", "Copied · 2 corrections", "Nothing heard", "Hold the key while you speak". Ellipsis for in-progress; middle dot `·` to join facts ("Downloaded · on this PC", "Today · 3 dictations · 41 words"); em dash for a directive ("Model not downloaded — open Settings").
- Honest limits are stated where they apply, in the caption under the control (the bias note under Model, "Text is always copied to the clipboard as well").
- Buttons are single verbs: Add, Save, Cancel, Remove, Download, Open folder, Copy, Delete, Edit.

## Do's and Don'ts

### Do:
- **Do** edit `design/tokens.json` first, then run `python design/gen-tokens.py`; `Tokens.xaml`, `Tokens.cs` and `Tokens.swift` are generated and never hand-edited.
- **Do** reference every color, size, radius, padding and duration by token in views (`{StaticResource …}` / `Tokens.…`). A literal number or hex in a view is a defect.
- **Do** build a new surface as text on the gradient with hairlines; reach for `surface-glass1` + `line-glass1` only for interactive things (fields, buttons, hovered rows).
- **Do** brighten one glass step on hover and one more on press (glass1 → glass2 → glass3; line1 → line2 → strong).
- **Do** put a caption hint under every setting control, and pair every colored status with its word.
- **Do** keep icons as authored 24-grid stroke geometry (Windows) or `.medium` SF Symbols (macOS) at 16 / 20 / 14 / 12.
- **Do** derive any new motion from the token constants: 150 / 200 / 300 ms, ease 0.2 0 0 1, lerp `1 − exp(−dt/τ)`, 1.6 s hold for things the user should notice.
- **Do** keep the pillars the only element that moves on its own.

### Don't:
- **Don't** add cards, panels, tonal containers or a stats tile row; the Dictation hero is pillars, one line, one caption.
- **Don't** add a light theme or read the OS appearance; the palette is one dark look on both platforms.
- **Don't** use `accent-ice` on static chrome; it means alive or changed.
- **Don't** apply shadows to anything anchored in the window; only the popover and tray menu carry the menu shadow.
- **Don't** blur anything but the glow halos.
- **Don't** use glyph characters, emoji or icon fonts as icons, and don't let default WPF grey chrome through (every control derives from `Control.Base`).
- **Don't** exceed 28px type or use weights other than 400 / 500.
- **Don't** let the rail resize, wrap, or gain a fourth item without a matching macOS change; both shells share the same three pages and vocabulary.
- **Don't** restyle the native title bar beyond DWM colors on Windows, or reintroduce a title bar on macOS.
