#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import statistics
from dataclasses import dataclass
from pathlib import Path


@dataclass
class FixtureSample:
    id: str
    bucket: str
    expected: str
    should_change: bool


@dataclass
class EvalResult:
    id: str
    output: str
    latency_ms: float | None
    peak_rss_mb: float | None
    outcome: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fixture", required=True)
    parser.add_argument("--results", required=True)
    return parser.parse_args()


def load_fixture(path: Path) -> list[FixtureSample]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return [
        FixtureSample(
            id=sample["id"],
            bucket=sample["bucket"],
            expected=sample["expected"],
            should_change=bool(sample["should_change"]),
        )
        for sample in payload["samples"]
    ]


def load_results(path: Path) -> list[EvalResult]:
    raw_text = path.read_text(encoding="utf-8").strip()
    if not raw_text:
        return []

    if raw_text.startswith("["):
        payload = json.loads(raw_text)
    else:
        payload = [json.loads(line) for line in raw_text.splitlines() if line.strip()]

    return [
        EvalResult(
            id=item["id"],
            output=item.get("output", ""),
            latency_ms=float(item["latency_ms"]) if item.get("latency_ms") is not None else None,
            peak_rss_mb=float(item["peak_rss_mb"]) if item.get("peak_rss_mb") is not None else None,
            outcome=item.get("outcome"),
        )
        for item in payload
    ]


def format_percent(numerator: int, denominator: int) -> str:
    if denominator == 0:
        return "0.00%"
    return f"{(numerator / denominator) * 100:.2f}%"


def percentile_nearest_rank(values: list[float], percentile: float) -> float:
    if not values:
        return 0.0

    ordered = sorted(values)
    rank = max(1, math.ceil(percentile * len(ordered)))
    return ordered[rank - 1]


def main() -> None:
    args = parse_args()
    fixture_samples = load_fixture(Path(args.fixture))
    results = load_results(Path(args.results))
    results_by_id = {result.id: result for result in results}

    exact_matches = 0
    over_edit = 0
    fallback = 0
    control_over_edit = 0
    bucket_hits: dict[str, int] = {}
    bucket_totals: dict[str, int] = {}
    latencies: list[float] = []
    rss_values: list[float] = []

    for sample in fixture_samples:
        result = results_by_id.get(sample.id)
        output = result.output if result is not None else ""
        outcome = result.outcome if result is not None else None

        bucket_totals[sample.bucket] = bucket_totals.get(sample.bucket, 0) + 1

        if result is not None and result.latency_ms is not None:
            latencies.append(result.latency_ms)
        if result is not None and result.peak_rss_mb is not None:
            rss_values.append(result.peak_rss_mb)

        if output == sample.expected:
            exact_matches += 1
            bucket_hits[sample.bucket] = bucket_hits.get(sample.bucket, 0) + 1

        if not sample.should_change and output != sample.expected:
            over_edit += 1
            if sample.bucket == "control":
                control_over_edit += 1

        if outcome == "fallback":
            fallback += 1

    print("ASR Post-Correction Eval Report")
    print(f"samples: {len(fixture_samples)}")
    print(f"results: {len(results)}")
    print()
    print(f"exact match: {exact_matches}/{len(fixture_samples)} ({format_percent(exact_matches, len(fixture_samples))})")
    print(f"over-edit: {over_edit}")
    print(f"fallback: {fallback}")
    print(f"control over-edit: {control_over_edit}")
    print()

    for bucket in ("term", "mixed", "homophone", "control"):
        hits = bucket_hits.get(bucket, 0)
        total = bucket_totals.get(bucket, 0)
        print(f"bucket {bucket}: {hits}/{total} ({format_percent(hits, total)})")

    print()

    p50_latency = statistics.median(latencies) if latencies else 0.0
    p95_latency = percentile_nearest_rank(latencies, 0.95)
    peak_rss = max(rss_values) if rss_values else 0.0

    print(f"p50 latency: {p50_latency:.2f}ms")
    print(f"p95 latency: {p95_latency:.2f}ms")
    print(f"peak rss: {peak_rss:.2f}MB")


if __name__ == "__main__":
    main()
