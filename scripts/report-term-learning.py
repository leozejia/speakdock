#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


def default_storage_path() -> Path:
    return Path.home() / "Library" / "Application Support" / "SpeakDock" / "term-dictionary.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--storage", default=str(default_storage_path()))
    parser.add_argument("--promotion-threshold", type=int, default=3)
    return parser.parse_args()


def load_snapshot(storage_path: Path) -> dict:
    if not storage_path.exists():
        return {
            "confirmedEntries": [],
            "pendingCandidates": [],
            "observedCorrections": [],
            "learningEvents": [],
        }

    with storage_path.open("r", encoding="utf-8") as handle:
        snapshot = json.load(handle)

    return {
        "confirmedEntries": snapshot.get("confirmedEntries", []),
        "pendingCandidates": snapshot.get("pendingCandidates", []),
        "observedCorrections": snapshot.get("observedCorrections", []),
        "learningEvents": snapshot.get("learningEvents", []),
    }


def canonical_key(text: str) -> str:
    return text.strip().casefold()


def status_for_observation(observation: dict, observed_corrections: list[dict], confirmed_entries: list[dict]) -> str:
    alias_key = canonical_key(observation.get("alias", ""))
    observed_canonical_keys = {
        canonical_key(candidate.get("canonicalTerm", ""))
        for candidate in observed_corrections
        if canonical_key(candidate.get("alias", "")) == alias_key
    }
    if len(observed_canonical_keys) > 1:
        return "conflicted"

    expected_canonical_key = canonical_key(observation.get("canonicalTerm", ""))
    for entry in confirmed_entries:
        entry_canonical_key = canonical_key(entry.get("canonicalTerm", ""))
        for alias in entry.get("aliases", []):
            if canonical_key(alias) != alias_key:
                continue
            if entry_canonical_key == expected_canonical_key:
                return "promoted"
            return "conflicted"

    return "observed"


def emit_counter_section(title: str, counter: Counter[str]) -> None:
    if not counter:
        return

    print(title)
    for key, value in sorted(counter.items()):
        print(f"- {key}: {value}")
    print()


def emit_current_observed(
    observed_corrections: list[dict],
    confirmed_entries: list[dict],
    promotion_threshold: int,
) -> None:
    if not observed_corrections:
        return

    print("current observed")
    sorted_corrections = sorted(
        observed_corrections,
        key=lambda observation: (
            canonical_key(observation.get("alias", "")),
            -int(observation.get("evidenceCount", 0)),
            canonical_key(observation.get("canonicalTerm", "")),
        ),
    )
    for observation in sorted_corrections:
        alias = observation.get("alias", "")
        canonical_term = observation.get("canonicalTerm", "")
        evidence_count = int(observation.get("evidenceCount", 0))
        status = status_for_observation(observation, observed_corrections, confirmed_entries)
        print(
            f"- {alias} -> {canonical_term} "
            f"evidence={evidence_count}/{promotion_threshold} status={status}"
        )
    print()


def emit_confirmed_entries(confirmed_entries: list[dict]) -> None:
    if not confirmed_entries:
        return

    print("confirmed dictionary")
    sorted_entries = sorted(
        confirmed_entries,
        key=lambda entry: canonical_key(entry.get("canonicalTerm", "")),
    )
    for entry in sorted_entries:
        aliases = ", ".join(entry.get("aliases", []))
        print(f"- {entry.get('canonicalTerm', '')} <- {aliases}")
    print()


def main() -> None:
    args = parse_args()
    storage_path = Path(args.storage).expanduser()
    snapshot = load_snapshot(storage_path)
    confirmed_entries = snapshot["confirmedEntries"]
    observed_corrections = snapshot["observedCorrections"]
    learning_events = snapshot["learningEvents"]

    print("Term Learning Report")
    print(f"storage: {storage_path}")
    print(f"confirmed entries: {len(confirmed_entries)}")
    print(f"observed corrections: {len(observed_corrections)}")
    print(f"learning events: {len(learning_events)}")
    print()

    if not confirmed_entries and not observed_corrections and not learning_events:
        print("No term dictionary learning data found.")
        return

    outcome_counter: Counter[str] = Counter()
    for event in learning_events:
        outcome = event.get("outcome")
        if isinstance(outcome, str) and outcome:
            outcome_counter.update([outcome])

    emit_counter_section("outcome", outcome_counter)
    emit_current_observed(observed_corrections, confirmed_entries, max(1, args.promotion_threshold))
    emit_confirmed_entries(confirmed_entries)


if __name__ == "__main__":
    main()
