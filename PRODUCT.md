# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

(Two native desktop apps: macOS SwiftUI and Windows WPF. Impeccable has no desktop-native reference; its `ios.md` conventions are the nearest analogue for the macOS build, and Windows follows Fluent/WinUI expectations. Live Mode does not apply — it attaches to web pages only.)

## Stack

Existing codebase: `macos/` SwiftPM + SwiftUI (macOS 26, Apple Speech `DictationTranscriber`), `windows/` WPF on .NET 9 (NVIDIA Parakeet via sherpa-onnx). Design tokens are generated from `design/tokens.json` into both.

## Users

One person (the owner) dictating into whatever app is in front — editors, chat, email — on a Windows desk PC and a Mac. Frequent, short bursts: press the hotkey, speak a sentence or a paragraph, release, keep working. Multilingual dictation (English, German, Arabic appear in the reference history).

## Product Purpose

Local, private dictation with a personal dictionary. Success: the transcript lands at the cursor within a second of releasing the key, and names / jargon / product names come out spelled the way the user taught them.

## Positioning

Fully on-device on both platforms, plus a two-layer dictionary (engine biasing + a guaranteed, glue-tolerant correction pass) that shows, per transcription, exactly what it changed. Competing tools (Wispr Flow) are cloud-backed and word-metered.

## Operating Context

- Trigger from another app via a global hotkey; the main window is for review, dictionary editing and settings, not the dictation moment.
- A menu bar item (macOS) / tray icon (Windows) shows state while the window is closed.
- Files are plain JSON the user edits by hand: dictionary, history, settings.
- Windows machine has several capture devices (Elgato Wave:3, webcam mic, USB codec); the user must be able to pick the input.

## Capabilities and Constraints

- Hotkey behavior: **push-to-talk (hold to record, release to transcribe)** is the required primary mode; toggle mode may remain as an option.
- Input device selection is required on both platforms.
- Engine biasing: macOS passes dictionary terms as contextual strings (cap 40); Parakeet TDT on Windows cannot be biased (greedy decoding) — Settings must say so honestly.
- Correction pass: whole-word, case-insensitive, longest match first, tolerant of glued/hyphenated parts; must never touch substrings of other words. Warn on entries that look like common words.
- History: searchable, copy per item, shows which corrections fired.
- Settings: hotkey, model/language, input device, insert-at-cursor.
- No Electron/Tauri; native only. No cloud.

## Brand Commitments

- Name: **Transkrito**.
- Binding visual direction supplied by the user on 2026-09-12 (two reference images):
  1. "Voice App Design System" board — deep navy → icy cyan atmosphere, glass capsule pillars as the signature, tokens named `color.blue.950 #050A14`, `blue.900 #0B1E3D`, `blue.700 #1C4ED8`, `blue.500 #3B82F6`, `ice.300 #7DD3FC`, `ice.100 #F0F8FF`; type scale 56/64 · 28/34 · 16/24 · 12/16; space 8/12/16/24/32; radius 12/16/24/32; borders `glass.1/2/strong` 1px at 10/20/40%; shadows soft.1–3; motion spring gentle 300 ms, fade quick 150 ms, breathing idle 3 s.
  2. Wispr Flow's window as a layout reference: left sidebar navigation, history grouped by day with time · text · row actions, a compact stats block.
- The earlier light icy-blue single-column look (v1 tokens) is superseded.

## Evidence on Hand

- Working Windows build with real transcriptions in `%APPDATA%\Transkrito\history.json`.
- Reference screenshots supplied in chat (not stored in repo).
- No testimonials, metrics or pricing exist; none may be invented.

## Product Principles

1. The dictation moment is invisible; the window is for review and teaching.
2. Honest state: the app says what it is doing, what it cannot do (biasing), and what the dictionary changed.
3. Everything the app knows lives in files the user can read and edit.
4. Same behavior, same vocabulary on both platforms; native chrome on each.

## Accessibility & Inclusion

Keyboard-operable throughout; body text ≥ 4.5:1 on the dark ground; status conveyed by text, never color alone.
