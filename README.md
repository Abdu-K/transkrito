# 🎙️ Transkrito

### Your voice. Your machine. Your text.

**Stop paying subscriptions just to turn your voice into text.**

Transkrito is a fast, private, local dictation app for Windows (and soon macOS — see below).

Hold a hotkey, speak, release — and your words are instantly turned into text, copied to your clipboard, and optionally pasted right where you're typing.

No cloud.
No account.
No word limits.
No subscription watching every sentence you say.

Just press, speak, and let your keyboard catch up. ⚡

---

## ✨ Why Transkrito?

Voice-to-text isn't magic anymore.

So why should you need another monthly subscription just to use it?

Many dictation apps send your voice to remote servers and charge you based on usage.

Transkrito takes a different approach:

> **Your voice stays on your computer.**

Audio capture, speech recognition, language detection, dictionary corrections, and history all run locally on your machine.

The only network access normally needed is when downloading a speech model.

After that, transcription happens on-device.

---

## 🚀 How it works

It's intentionally simple:

1. ⌨️ Hold your global hotkey
2. 🎙️ Speak
3. ✋ Release
4. ⚡ Transkrito converts your speech into text
5. 📋 The result goes to your clipboard
6. 📝 Optionally, it gets pasted automatically at your cursor

That's it.

No browser tabs.
No uploading recordings.
No copy-pasting from a website.

---

## 🔥 Features

### 🎙️ Push-to-talk dictation

Use a global hotkey from almost anywhere on your computer.

Choose between:

- Hold-to-talk
- Toggle mode
- Custom hotkeys

---

### ⚡ Fast transcription

Transkrito processes your speech locally and can place the result in your clipboard within roughly a second after you stop speaking.

You can also enable automatic paste so the text appears directly where you're typing.

---

### 🌍 Automatic language detection

Speak naturally without constantly changing settings.

Transkrito can automatically detect:

- 🇬🇧 English
- 🇩🇪 German
- 🇸🇦 Arabic

Or lock the app to one language manually.

---

### 📖 Personal Dictionary

Speech recognition isn't perfect — especially with names, technical terms, slang, or words you use often.

Transkrito lets you create your own correction rules.

For example:

```text
Transcripto → Transkrito
```

Matching is whole-word, case-insensitive, and Unicode-safe (handles Arabic diacritics and German umlauts correctly). It warns you about duplicate or conflicting rules instead of silently doing the wrong thing.

---

### 🕘 History

Everything you dictate is saved locally, grouped by day and searchable. Arabic entries render right-to-left. You can see which dictionary corrections fired on each entry.

---

## 🧠 Under the hood

No server, no database — just one process talking to itself. Two things worth knowing:

- **Speech engines:** NVIDIA Nemotron 3.5 (streaming) by default, with an offline Parakeet TDT model available for English/German. Both run through [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) — an open-source ONNX runtime for speech models.
- **Design:** colors, spacing, and type all come from one JSON file (`design/tokens.json`), so the app looks consistent instead of being styled ad hoc.

Stack: C# / .NET 9 / WPF on Windows.

---

## 🤖 Built with AI-assisted development

I used Claude Code to help write parts of this — not all of it. I designed the architecture, wrote the behavior spec and the test cases, and reviewed every change it generated before accepting it. Some of the implementation is AI-written, checked and tested by me; the product decision, the system design, and the review are mine. I'm saying this upfront instead of pretending otherwise.

This isn't my first project — it follows the same spec-first, review-everything way I work generally.

---

## 🚧 Honest limitations

- No dictionary biasing at the engine level yet — corrections happen as a pass after transcription.
- CPU-only inference, so expect roughly 1–2 seconds of delay after you release the hotkey.
- Local-only, single user: no sync, no multiple profiles, history caps at 500 entries.

---

## 🗺️ Roadmap

- [ ] macOS version — written, not yet built/tested. Coming soon.
- [ ] More languages
- [ ] Smarter dictionary correction

---

## License

MIT — see [LICENSE](LICENSE).
