---
version: 1
slug: "windows-transkrito-views-mainwindow-xaml"
primary_target: "windows/Transkrito/Views/MainWindow.xaml"
related_targets: ["macos/Sources/Transkrito/Views/MainWindow.swift"]
---

# Surface brief: main window (Windows WPF + macOS SwiftUI)

Scope: the app's only window — sidebar shell with three pages (Dictation, Dictionary, Settings). Mode: Operate.
Audience/job: the owner reviewing what was dictated, teaching the dictionary, tuning hotkey/model/mic. Dictation itself happens outside the window via hold-to-talk.
Proof/content: real history from history.json; real dictionary; real engine state. No invented stats beyond what history can compute (words, items, days).
Constraints: native chrome on each OS; dark navy single look; Windows title bar via DWM dark mode; keyboard operable; body text ≥ 4.5:1.

## Direction contract

THESIS: A listening instrument, not a dashboard. The glass pillars are the one thing on screen that is alive; everything else is quiet navy paper. Refuses: the card-grid dashboard with a stats hero.

OWN-WORLD: Ground `blue.950 #050A14` → `blue.900 #0B1E3D` atmosphere with an icy `ice.300 #7DD3FC` wash behind the pillars. Ink `ice.100 #F0F8FF` at 92/64/40% steps. Accent `blue.500 #3B82F6`; pressed `blue.700 #1C4ED8`. Glass = 1px borders at 10/20/40% white, fills at 6–10% white, no blur except the pillars. Capsule pillars with internal cobalt gradient, white top highlight, cyan glow proportional to level. One family (Segoe UI Variable / SF Pro), scale 28/16/13/12. Radius 12/16/24.

STORY: Open the window → see the pillars breathe at rest, the hotkey printed under them, and today's dictations below. Hold the key anywhere → pillars light up. Release → row appears with a chip naming what the dictionary fixed.

FIRST VIEWPORT (Dictation page, 1040×720): left rail 220px — wordmark, three nav items, status + hotkey at the bottom. Content: pillars centered at y≈30% (maxHeight 140, count 21), hint “Hold ⌃⌥Space to dictate” beneath; a single quiet stats line (today · words · streak) as text, not tiles; then day-grouped history (TODAY / YESTERDAY / date) — each row time · text · actions on hover (Copy, Delete) and a chip “2 corrections” expanding to what changed. Primary action = the hotkey; the on-screen mic button is secondary, sits right of the hint.

FORM: pinned by the user’s reference images (Voice App board + Wispr Flow layout); the roll (seed 86ae69c4, assigned index 4 “boarding pass + gate board”) was overruled by the pinned brief. Donation kept from the assigned direction: rows that change move in place and stay lit until noticed — new history rows slide in and hold a cyan tint for 1.6 s. Challengers declined: sneaker stack, tensegrity column, streaming wall.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
