# Transkrito shared spec

Both apps implement this identically. Test vectors: `correction-tests.json`.

## Files
| | macOS | Windows |
|---|---|---|
| dir | `~/Library/Application Support/Transkrito/` | `%APPDATA%\Transkrito\` |
| dictionary | `dictionary.json` | same |
| history | `history.json` | same |
| settings | `settings.json` | same |
| models | n/a (Apple assets) | `%LOCALAPPDATA%\Transkrito\models\` |

All JSON is pretty-printed, UTF-8, written atomically (temp + rename). Dictionary is watched; external edits reload the UI. Malformed file → keep last good in-memory copy, show status warning, never overwrite the user's file until they save from the UI.

### dictionary.json
```json
{ "version": 1, "entries": [
  { "id": "uuid", "type": "term",       "text": "Anthropic", "created": "ISO-8601" },
  { "id": "uuid", "type": "correction", "hear": "cloud code", "write": "Claude Code", "created": "ISO-8601" } ] }
```
### history.json — newest first, cap 500
```json
{ "version": 1, "items": [ { "id":"uuid", "date":"ISO", "raw":"…", "text":"…", "durationSec": 4.2,
  "engine":"apple-speech|parakeet", "model":"en-US|parakeet-tdt-0.6b-v3",
  "corrections":[ { "hear":"cloud code", "write":"Claude Code", "matched":"CloudCode", "count":1 } ] } ] }
```
### settings.json
```json
{ "version": 1, "hotkey": { "key": "Space", "modifiers": ["control","option"] },
  "hotkeyMode": "hold", "inputDevice": "", "model": "en-US", "insertAtCursor": true }
```
Windows modifiers: `control`, `alt`, `shift`, `win`. macOS: `control`, `option`, `shift`, `command`. Default: mac ⌃⌥Space, Windows Ctrl+Alt+Space.
`hotkeyMode`: `hold` (default, push-to-talk: chord down → listening, chord up → transcribe; releasing any modifier also ends the hold) or `toggle` (press → start, press → stop). Windows uses a low-level keyboard hook (the chord's key is swallowed); macOS uses Carbon hot-key pressed/released events.
`inputDevice`: Windows = WASAPI endpoint id, macOS = Core Audio device UID; empty = system default. Any device format is downmixed to mono and resampled.

## Correction engine — `apply(text, entries) -> (text, events)`
1. Rules: `correction` → hear→write. `term` → text→text (fixes casing and glued/hyphen variants).
2. Normalize hear: trim, collapse whitespace. Parts = split on whitespace and `-`. Drop empty parts.
3. Pattern = `\b` + parts.map(regexEscape).join(`[\s\-]*`) + `\b`, case-insensitive, Unicode-aware `\b`. Single-part rule: `\bpart\b`.
   - "cloud code" → `\bcloud[\s\-]*code\b`: matches "cloud code", "CloudCode", "Cloud-Code", "cloud   code". Not "Cloudflare", not "cloud", not "encode".
4. Order: by normalized-hear length desc (ties: created asc). Apply sequentially over the whole text.
5. Each rule replaces every match with `write` verbatim (write's casing preserved). A match whose substring already equals `write` exactly is left alone and not counted. Record one event per rule with ≥1 counted match: `{hear, write, matched: first counted substring, count}`.
6. Skip `correction` rules where hear == write (exact) after normalization (`term` rules always run — they canonicalize casing). Skip rules with empty parts.
7. Idempotent: `apply(apply(t)) == apply(t)` for all vectors.

## Warnings — `warn(entry, otherEntries) -> [warning]` (shown under the field, save still allowed)
- `common`: normalized hear (lowercase, separators removed) ∈ `common-words.txt`, OR hear has one part and that part ≤ 3 chars. Message: `"X" is a common word — this will rewrite it everywhere.`
- `noop`: hear equals write (case-sensitive). `Hear and write are the same.`
- `duplicate`: another entry has same normalized hear. `Already in the dictionary.`
- `shadowed`: another entry's normalized parts are a strict contiguous sub-sequence of this entry's parts, or vice versa. `Overlaps with "Y" — longest match wins.`

## Biasing — `biasTerms(entries) -> [String]`
All `term.text` + all `correction.write`, dedup case-insensitive keeping first, order by `created` desc, cap `bias.maxTerms` (40). macOS → `AnalysisContext.contextualStrings[.general]`. Windows → sherpa-onnx hotwords if the loaded model supports it, else no-op and `Engine.biasSupported == false` (Settings shows it).

## Recording state machine
`idle → listening → transcribing → idle`. Audio: 16 kHz mono float32. Level = RMS per buffer, mapped `level = clamp((20·log10(rms) + 50) / 50, 0, 1)` (−50 dBFS → 0, 0 dBFS → 1), smoothed with EMA: `a = 1 − exp(−dt/τ)`, τ = attack when rising, release when falling.
On stop: transcribe → `apply` → history insert (row flagged `isNew` for `motion.rowHighlight` ms) → clipboard → optional insert-at-cursor → idle. Empty transcript → status "Nothing heard" (or "Hold the key while you speak" when the hold was < 0.4 s), no history entry.

## Pillars
`count 21`, index `i ∈ [0, 20]`, center 10, `d = |i − 10|`, `env = max(0.15, cos²(π·d/20))`.
Jitter: per-pillar random walk in [−0.06, 0.06], mirrored (i and 20−i share). `drive = idleLevel + (1−idleLevel)·level` (idleLevel 0.12 keeps a resting wave while silent). `h_i = min + (max−min)·drive·env_i·(1+jitter_i)`. Pillar is "speaking" when smoothed level ≥ 0.06 → glass style (fill gradient, inner highlight, edge, glow with alpha ∝ level) fades in over `motion.base`. Below threshold: `pillar.idle` fill, no glow.

## Main window (v2 shell)
Rail (220): wordmark · nav Dictation / Dictionary / Settings · status dot + text · hotkey key caps + mode hint. Page = Dictation (pillars, mic + “Hold <hotkey> anywhere”, stats line “Today · n dictations · w words · s-day streak”, search, history grouped Today / Yesterday / d MMMM), Dictionary (title, add editor, search + All/Words/Corrections filter, rows), Settings (hotkey + Hold/Toggle, microphone, model, insert, files). ⌘, / Ctrl+, opens the Settings page in-window.

## Main window layout v1 (superseded, kept for reference)
status text (`type.status`) · pillars · Start/Stop pill (`accent.base`, `ink.inverse`, radius pill) with hotkey hint (`type.mono`, `ink.tertiary`) · text toggle "History | Dictionary" (`type.body`; active = `accent.base` + 1pt underline) · flat search field · rows with hairline separators.
History row: `text` (`type.transcript`), time (`type.caption`, `ink.secondary`), copy button (appears on hover / always on touch), chip "N corrections" (`type.caption`, `accent.pale` bg, radius sm) → expands to `matched → write` lines.
Dictionary row: term or `hear → write`, edit inline, delete (`state.danger` on hover). Add form: type toggle, fields, warning line (`state.warning`).

## Menu bar / tray
Icon states: idle (outline waveform), listening (filled, `state.recording`), transcribing (outline + dot). Menu: Start/Stop Listening (hotkey shown), Open Transkrito, Settings…, Quit. Closing main window keeps app alive.
