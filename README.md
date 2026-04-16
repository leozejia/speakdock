# SpeakDock

SpeakDock is an AI voice input method for macOS that does not stop at typing.

Speak, and it writes where you are. Deterministic cleanup keeps the hot path stable, and optional model-based `Refine` can reorganize an entire workspace when the user wants clearer expression. Capture a thought instead, and it becomes the entry point to a local Markdown knowledge base that can later be compiled into an LLM-maintained wiki.

The long-term goal is a voice layer that can write, learn the right terms, organize expression, and remember, while keeping the source of truth on your machine.

[中文说明](README.zh-CN.md)

## Why

Most dictation tools stop at text insertion. That is useful, but it misses the harder problem: spoken thoughts are often part of an ongoing project, conversation, decision, or research thread.

SpeakDock treats voice as the first step in a local working memory loop:

- `Compose`: put speech into the current cursor when a safe editable target exists.
- `Capture`: preserve speech as local Markdown when there is no text target.
- `Wiki`: compile durable captures into structured knowledge in the background.

The wiki direction is inspired by Andrej Karpathy's [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) pattern: instead of asking a model to rediscover knowledge from raw files on every query, let it maintain a persistent Markdown wiki over time.

## Product Direction

SpeakDock's product target goes beyond speech-to-text. It is a small, dependable voice layer that can stay close to the user's work:

- quick replies in chat or documents
- local voice inbox for thoughts that do not belong in the current app
- conservative cleanup that keeps the user's meaning intact
- reversible edits and short undo windows
- background knowledge compilation into Markdown pages
- Apple-platform workflows first, with macOS as the proving ground

Local-first matters here. The source of truth should remain on the user's machine, in ordinary files. Cloud model calls can help reorganize a workspace, but they should not define the default hot path. Over time, small on-device models should handle most cleanup, classification, and structured extraction work. Larger models stay optional.

Hardware triggers are also part of the design, but not as a product dependency. A device such as a DJI microphone button should be one `TriggerAdapter` among others: keyboard, iPhone action, shortcut, widget, or future hardware. The user-facing semantics should stay the same.

## How It Is Different

Most AI dictation products focus on polished writing in every app. That is a strong wedge. SpeakDock should start there, but it should not compete only on transcription polish.

The sharper angle is local memory:

- immediate AI voice input when you already know where the text should go
- local Markdown capture when the thought needs a place to land
- conservative model cleanup instead of uncontrolled rewriting
- a future Wiki compiler that turns saved captures into durable pages, links, logs, and project memory
- pluggable triggers, including hardware, without binding the product to one device

That makes SpeakDock closer to a voice-native personal knowledge workflow than a keyboard replacement alone.

## Current Status

SpeakDock is in an early macOS implementation phase. The first milestone is the fast path: speak, transcribe, write or capture, then recover if something went wrong.

What works today:

- Menu bar app with the Dock icon visible by default.
- Press and hold `Fn` to speak, release to finish, double-press to submit.
- Apple Speech streaming recognition with `zh-CN` by default.
- Language options for `en-US`, `zh-CN`, `zh-TW`, `ja-JP`, and `ko-KR`.
- Compose through clipboard paste with temporary ASCII input-source switching.
- Capture to local Markdown files named `speakdock-YYYYMMDD-HHMMSS.md`.
- Lightweight overlay for listening, thinking, refining, transcript preview, and audio level.
- Deterministic `Clean`, a local `Term Dictionary`, and optional OpenAI-compatible workspace-level `Refine`.
- Conservative passive word-level learning in readable targets, with repeated stable corrections promoted into the local term dictionary.
- Recent insertion undo and refine undo.
- Compatibility diagnostics for third-party text targets.
- Settings for trigger, capture root, local term dictionary, and refine configuration.
- Apple Unified Logging through `OSLog.Logger`.

Not shipped yet:

- A packaged and signed public release.
- A local ASR model path.
- A local small-model cleanup or extraction engine.
- Background Wiki compiler and schema workflow.
- DJI or other hardware trigger adapters.
- iOS trigger or capture surface.

## Install From Source

Requirements:

- macOS 14 or later.
- Xcode command line tools or a Swift toolchain compatible with Swift Package Manager.
- Microphone, Speech Recognition, and Accessibility permissions.

Build and run:

```bash
make build
make run
```

Run tests:

```bash
make test
```

Show recent logs:

```bash
make logs
make logs LOG_WINDOW=2h
```

Show recent raw interaction trace lines:

```bash
make traces
make traces TRACE_WINDOW=5m
```

Summarize recent trace results and latency locally:

```bash
make trace-report
make trace-report TRACE_WINDOW=20m
```

Probe Compose compatibility without recording or inserting text:

```bash
make probe-compose PROBE_SECONDS=30
make logs LOG_WINDOW=2m
```

Run the local automated Compose smoke baseline against SpeakDock's own test host:

```bash
make smoke-compose
make trace-report TRACE_WINDOW=5m
make traces TRACE_WINDOW=5m
```

Run the local automated Refine smoke baseline with a temporary local stub server:

```bash
make smoke-refine
make trace-report TRACE_WINDOW=5m
make traces TRACE_WINDOW=5m
```

Run the local automated term-learning smoke baseline against an isolated temporary dictionary:

```bash
make smoke-term-learning
make trace-report TRACE_WINDOW=5m
make traces TRACE_WINDOW=5m
```

## Permissions

SpeakDock asks macOS for the permissions required by the current path:

- Microphone captures speech and drives the audio-level overlay.
- Speech Recognition produces streaming and final text through Apple Speech.
- Accessibility listens for the default `Fn` trigger and checks or restores the current text target for Compose.
- Input Monitoring is not expected for the current implementation. It may become relevant only if the trigger implementation changes later.

If Accessibility appears enabled but `Fn` still shows as unavailable, remove the old SpeakDock entry from System Settings, add the current `.build/debug/SpeakDock.app`, and run the app again.

## Development Model

The public `main` branch is intended to stay clean and stable: source code, build instructions, license, and public-facing project description.

Detailed architecture notes, execution logs, and research notes are kept out of the public branch. They guide development, but the public README should change only when the product direction, setup flow, or licensing changes.

## License

SpeakDock is licensed under the Apache License 2.0. See [LICENSE](LICENSE).
