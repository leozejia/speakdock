# LLM Wiki Methodology for SpeakDock

Status: research input only. Product truth lives in `docs/technical/ARCHITECTURE.md`.

## 1. Why This Matters

SpeakDock should not only help users capture voice. It should help them accumulate usable knowledge over time.

A plain inbox quickly becomes a pile. A raw transcript archive becomes even worse. The purpose of the knowledge layer is to transform repeated capture into a navigable personal wiki.

This is where the `llm wiki` methodology is useful.

## 2. Core Idea

The methodology separates three concerns:

- raw sources
- intermediate structure
- compiled wiki pages

This is valuable because it prevents the common failure mode where generated notes are treated as final truth too early.

For SpeakDock, the equivalent mapping is:

- voice captures and transformed notes become the `raw sources`
- metadata and extraction logic define the `structure`
- stable markdown topic pages become the `wiki`

## 3. Why It Fits SpeakDock

SpeakDock is a continuous capture tool. That means it naturally generates a stream of small information units.

Without an organizing method, the product degrades into a transcript bucket. With a wiki compilation layer, the same input stream can become:

- project pages
- people pages
- topic pages
- chronological logs
- action history

This makes the product more than dictation. It becomes a local knowledge engine.

## 4. Hot Path vs Cold Path

This distinction is critical.

### Hot path

The hot path is the user-facing action that happens immediately after speaking:

- insert text at cursor
- create inbox markdown note
- optionally run explicit workspace refine

The hot path must stay fast and deterministic.

### Cold path

The cold path is background knowledge compilation:

- append raw capture to logs
- cluster notes by topic or entity
- update wiki pages
- regenerate index pages
- maintain backlinks or references

The cold path should never block immediate completion.

## 5. File-Based Truth Model

The source of truth should remain the local file system.

The right mental model is:

- SpeakDock writes markdown and metadata files
- wiki output is served via a lightweight local HTTP server, viewable in any browser
- any compatible local markdown tool (including Obsidian) can also read the files, but none is a dependency

## 6. Recommended Directory Layout

```text
SpeakDock/
  raw/
    voice/
  inbox/
  wiki/
    index.md
    log.md
    people/
    projects/
    topics/
  schema/
```

### Purpose of each layer

- `raw`: durable input artifacts, including transcripts and metadata
- `inbox`: user-facing near-term working notes
- `wiki`: compiled durable knowledge pages
- `schema`: prompts, extraction rules, templates, and page-generation conventions

## 7. Recommended Content Flow

1. user records a voice action
2. SpeakDock generates a raw transcript artifact
3. local processing creates an immediate output note or insertion result
4. a background compiler reads raw artifacts and inbox notes
5. entities, topics, and time-based events are extracted
6. relevant wiki pages are updated
7. index and log pages are refreshed

## 8. Why Not Write Directly into Wiki Pages

Direct-to-wiki generation looks elegant but is a bad default.

Problems:

- raw spoken input is noisy
- the system may misclassify the target page
- bad generations become entrenched too early
- the user loses provenance and reprocessing ability

Therefore every capture should land first as a raw or inbox artifact, and only then be compiled into the wiki.

## 9. Page Types

The wiki layer should start with a very small set of durable page types.

### People

Tracks people, conversations, decisions, and relationship context.

### Projects

Tracks goals, active tasks, decisions, and open loops.

### Topics

Tracks concepts, recurring themes, and reference knowledge.

### Log

Provides chronological history and traceability.

## 10. Metadata Discipline

Every raw artifact should carry enough metadata to support future compilation.

Recommended metadata fields:

- `id`
- `created_at`
- `source`
- `mode`
- `device`
- `language`
- `tags`
- `entities`
- `confidence`

The schema should remain small at first. Too much metadata becomes a maintenance burden.

## 11. Role of Local Models

One likely near-term role for local models in SpeakDock is on-device ASR. `Qwen3-ASR-0.6B via MLX` is the current leading candidate, but the exact model package, quantization, and runtime shape still need a dedicated evaluation before they become product truth.

Wiki compilation is a multi-turn knowledge task requiring autonomous exploration, cross-referencing, and error correction. It is handled by an external agent (Claude Code CLI or Codex CLI), not by local small models.

Local models should not be asked to free-form author a full wiki.

## 12. Strategic Outcome

By combining local voice capture with an agent-driven wiki compiler, SpeakDock can become:

- a dictation replacement
- a local voice inbox
- a markdown-native knowledge system
- a browser-viewable personal memory layer

That is a stronger product position than a pure speech-to-text tool.

## 13. Practical Principle

The right order is:

1. capture the speech
2. complete the immediate user action
3. preserve the raw artifact
4. compile knowledge in the background

Never invert this order.
