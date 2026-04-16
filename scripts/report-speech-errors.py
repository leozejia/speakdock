#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
import re

SPEECH_PREDICATE = 'subsystem == "com.leozejia.speakdock" AND category == "speech"'
START_REQUEST_PATTERN = re.compile(r"speech recognition start requested: language=([^\s]+)")
ERROR_PATTERN = re.compile(r"speech recognition task reported error: domain=([^,]+), code=(-?\d+)")


@dataclass
class SpeechSession:
    language: str
    outcome: str
    error_key: str | None = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--last", default="20m")
    parser.add_argument("--stdin", action="store_true")
    return parser.parse_args()


def load_lines(window: str, read_stdin: bool) -> list[str]:
    if read_stdin:
        return sys.stdin.read().splitlines()

    result = subprocess.run(
        [
            "/usr/bin/log",
            "show",
            "--predicate",
            SPEECH_PREDICATE,
            "--info",
            "--debug",
            "--last",
            window,
            "--style",
            "compact",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.splitlines()


def parse_sessions(lines: list[str]) -> list[SpeechSession]:
    sessions: list[SpeechSession] = []
    pending_language: str | None = None

    for line in lines:
        start_match = START_REQUEST_PATTERN.search(line)
        if start_match:
            if pending_language is not None:
                sessions.append(SpeechSession(language=pending_language, outcome="unfinished"))
            pending_language = start_match.group(1)
            continue

        if pending_language is None:
            continue

        error_match = ERROR_PATTERN.search(line)
        if error_match:
            domain = error_match.group(1).strip()
            code = error_match.group(2).strip()
            sessions.append(
                SpeechSession(
                    language=pending_language,
                    outcome="failed",
                    error_key=f"{domain}#{code}",
                )
            )
            pending_language = None
            continue

        if "speech recognition final result received" in line:
            sessions.append(SpeechSession(language=pending_language, outcome="succeeded"))
            pending_language = None

    if pending_language is not None:
        sessions.append(SpeechSession(language=pending_language, outcome="unfinished"))

    return sessions


def emit_counter_section(title: str, counter: Counter[str]) -> None:
    if not counter:
        return

    print(title)
    for key, value in sorted(counter.items()):
        print(f"- {key}: {value}")
    print()


def main() -> None:
    args = parse_args()
    sessions = parse_sessions(load_lines(args.last, args.stdin))

    print("Speech Error Report")
    print(f"window: {'stdin' if args.stdin else args.last}")
    print(f"sessions: {len(sessions)}")
    print()

    if not sessions:
        print("No speech sessions found.")
        return

    outcome_counter: Counter[str] = Counter()
    language_counter: Counter[str] = Counter()
    error_counter: Counter[str] = Counter()

    for session in sessions:
        outcome_counter.update([session.outcome])
        language_counter.update([session.language])
        if session.error_key is not None:
            error_counter.update([session.error_key])

    emit_counter_section("outcome", outcome_counter)
    emit_counter_section("language", language_counter)
    emit_counter_section("error", error_counter)


if __name__ == "__main__":
    main()
