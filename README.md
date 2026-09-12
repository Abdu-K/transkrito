# Transkrito

Quiet, minimal dictation. Hold a hotkey anywhere, speak, let go — the text lands at your cursor, corrected by a dictionary you teach it.

Two native apps, one design, one spec:

| | macOS | Windows |
|---|---|---|
| UI | SwiftUI (`macos/`) | WPF, .NET 9 (`windows/`) |
| Engine | Apple Speech — `SpeechAnalyzer` + `DictationTranscriber`, on-device (macOS 26); Nemotron 3.5 (sherpa-onnx) as the Arabic fallback | NVIDIA Nemotron 3.5 ASR Streaming 0.6B via sherpa-onnx, on-device (Parakeet TDT optional for en/de) |
| Languages | English, Deutsch, العربية — Auto detects per utterance (Whisper-tiny language ID + Apple locale) | English, Deutsch, العربية — Auto uses the model's own language detection |
| Biasing | dictionary terms passed as `AnalysisContext.contextualStrings` (cap 40) | not available for NeMo transducers through sherpa-onnx — shown in Settings |
| Correction pass | identical, tested against `shared/correction-tests.json` | identical |
| Hotkey | Carbon `RegisterEventHotKey` press + release (no Accessibility needed) | low-level keyboard hook (press + release, chord key swallowed) |
| Microphone | Core Audio device list, set on the input unit | WASAPI endpoint list, downmix + resample |
| Secondary surface | menu bar extra | tray icon |

## Layout

```
design/   tokens.json (source of truth) · TOKENS.md · gen-tokens.py (→ Tokens.swift / Tokens.xaml / Tokens.cs) · make-icon.py
shared/   SPEC.md (behavior + file formats) · correction-tests.json · common-words.txt · dictionary.example.json
macos/    SwiftPM package + XcodeGen project.yml + scripts/make-app.sh
windows/  Transkrito.sln (WPF app + xUnit tests)
```

Every view pulls from the tokens. Change `design/tokens.json`, run `python design/gen-tokens.py`, rebuild.

## macOS

Requires macOS 26 and Xcode 26 (Swift 6 toolchain).

```bash
cd macos
./scripts/make-app.sh            # swift build -c release → build/Transkrito.app (ad-hoc signed)
./scripts/make-app.sh --install  # also copies to /Applications
swift test                       # shared correction vectors
```

Prefer Xcode? `brew install xcodegen && xcodegen generate && open Transkrito.xcodeproj`, then ⌘R.

First run: allow **Microphone** and **Speech Recognition** when asked. Settings (⌘,) → Speech models shows one row per language; assets install on demand (Auto also fetches the 116 MB Whisper-tiny language detector; Arabic without an Apple asset fetches the 475 MB Nemotron model). "Insert at cursor" needs **Accessibility** (asked once; without it text is still copied to the clipboard).

Verifying languages on the Mac: set Language to English / Deutsch / العربية in turn and dictate; each history row shows the language under the time. Set Auto and dictate the three languages on consecutive hotkey presses — the rail status reads "Detecting language…" then "Listening · Deutsch" (etc.), and history stamps `en`/`de`/`ar`. If Settings shows Arabic as "Apple Speech unavailable", the Nemotron row appears and Arabic dictation runs through it.

## Windows

Requires the .NET 9 SDK (`winget install Microsoft.DotNet.SDK.9`).

```bash
cd windows
dotnet test                                        # shared vectors + Parakeet smoke test (skipped until the model is downloaded)
dotnet run --project Transkrito                    # run
dotnet publish Transkrito -c Release -r win-x64    # self-contained exe in Transkrito/bin/Release/net9.0-windows10.0.19041.0/win-x64/publish
```

First run: Settings (Ctrl+,) → Model → Download (Nemotron 3.5 multilingual, ≈475 MB, extracted to `%LOCALAPPDATA%\Transkrito\models`). Pick your microphone and language there too (Auto is the default). Default hotkey Ctrl+Alt+Space, hold-to-talk; switch to press-to-toggle in Settings.

Dev aids: `TRANSKRITO_PAGE=dictionary|settings` opens on that page; `TRANSKRITO_TEST_WAV=<16 kHz mono wav>` replays a file instead of the microphone when you hold the hotkey. `TRANSKRITO_DOWNLOAD=1 dotnet test` fetches the model through `ModelManager` and runs the real-audio tests (the archive's `test_wavs/{de,ar}.wav` plus Windows TTS for English).

## Design

`design/tokens.json` is the single source of truth (v2: navy → icy cyan, glass pillars, sidebar shell). `PRODUCT.md` holds product truth; `.impeccable/surfaces/*.md` the direction contract; `DESIGN.md` the built world. The impeccable skills are installed under `.claude/skills/impeccable` — its Live Mode is web-only and does not attach to these native apps; the review/critique/polish playbooks do apply.

## Files you can edit by hand

| | macOS | Windows |
|---|---|---|
| dictionary | `~/Library/Application Support/Transkrito/dictionary.json` | `%APPDATA%\Transkrito\dictionary.json` |
| history | `…/history.json` | same |
| settings | `…/settings.json` | same |

The dictionary file is watched; edits in a text editor show up in the app immediately. Format in `shared/dictionary.example.json`.

## Dictionary

Two entry types:

- **Word or phrase** — `Anthropic`, `Vercel`, `Claude Code`. Passed to the engine as context (macOS) and used to fix casing / glued variants afterwards (`claude-code` → `Claude Code`).
- **Correction** — when you hear *X*, write *Y*. `cloud code` → `Claude Code` also catches `CloudCode` and `Cloud-Code`; it never touches `Cloudflare` or a bare `cloud`.

Matching is whole-word, case-insensitive, longest entry first. Entries that look like common words get a warning before you save. Every history row shows what the dictionary changed.
