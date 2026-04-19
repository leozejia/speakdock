#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
import re

PREDICATE = 'subsystem == "com.leozejia.speakdock" AND category == "speech"'
CORRECTION_PATTERN = re.compile(
    r"asr correction commit finished: outcome=([^,]+), changed=(true|false), inputLength=(\d+), outputLength=(\d+)"
)


@dataclass
class ASRCorrectionSession:
    outcome: str
    changed: str
    input_length: int
    output_length: int


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
            PREDICATE,
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


def parse_sessions(lines: list[str]) -> list[ASRCorrectionSession]:
    sessions: list[ASRCorrectionSession] = []

    for line in lines:
        match = CORRECTION_PATTERN.search(line)
        if not match:
            continue

        sessions.append(
            ASRCorrectionSession(
                outcome=match.group(1).strip(),
                changed=match.group(2).strip(),
                input_length=int(match.group(3)),
                output_length=int(match.group(4)),
            )
        )

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

    print("ASR Correction Report")
    print(f"window: {'stdin' if args.stdin else args.last}")
    print(f"sessions: {len(sessions)}")
    print()

    if not sessions:
        print("No asr correction sessions found.")
        return

    outcome_counter: Counter[str] = Counter()
    changed_counter: Counter[str] = Counter()
    input_lengths = 0
    output_lengths = 0

    for session in sessions:
        outcome_counter.update([session.outcome])
        changed_counter.update([session.changed])
        input_lengths += session.input_length
        output_lengths += session.output_length

    emit_counter_section("outcome", outcome_counter)
    emit_counter_section("changed", changed_counter)
    print(f"average input length: {input_lengths / len(sessions):.2f}")
    print(f"average output length: {output_lengths / len(sessions):.2f}")


if __name__ == "__main__":
    main()
