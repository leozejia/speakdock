#!/usr/bin/env python3
from __future__ import annotations
import argparse
import math
import re
import statistics
import subprocess
import sys
from collections import Counter

TRACE_PREDICATE = 'subsystem == "com.leozejia.speakdock" AND category == "trace"'
TRACE_FIELD_PATTERN = re.compile(r"([A-Za-z]+)=([^\s]+)")
LATENCY_FIELDS = ("total", "press", "recognition", "commit")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--last", default="20m")
    parser.add_argument("--stdin", action="store_true")
    return parser.parse_args()


def load_trace_lines(window: str, read_stdin: bool) -> list[str]:
    if read_stdin:
        return sys.stdin.read().splitlines()

    result = subprocess.run(
        [
            "/usr/bin/log",
            "show",
            "--predicate",
            TRACE_PREDICATE,
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


def parse_trace_fields(line: str) -> dict[str, str] | None:
    if "trace.finish" not in line:
        return None

    payload = line.split("trace.finish", 1)[1]
    fields = dict(TRACE_FIELD_PATTERN.findall(payload))
    if not {"kind", "origin", "result"}.issubset(fields):
        return None
    return fields


def percentile_nearest_rank(values: list[float], percentile: int) -> int:
    sorted_values = sorted(values)
    index = max(0, math.ceil((percentile / 100) * len(sorted_values)) - 1)
    return milliseconds(sorted_values[index])


def milliseconds(value: float) -> int:
    return int(round(value * 1000))


def summarize_latency(values: list[float]) -> str:
    median_value = milliseconds(statistics.median(values))
    average_value = milliseconds(sum(values) / len(values))
    p95_value = percentile_nearest_rank(values, 95)
    max_value = milliseconds(max(values))
    return (
        f"count={len(values)} avg={average_value}ms "
        f"p50={median_value}ms p95={p95_value}ms max={max_value}ms"
    )


def emit_counter_section(title: str, counter: Counter[str]) -> None:
    if not counter:
        return

    print(title)
    for key, value in sorted(counter.items()):
        print(f"- {key}: {value}")
    print()


def main() -> None:
    args = parse_args()
    lines = load_trace_lines(args.last, args.stdin)
    traces = [fields for line in lines if (fields := parse_trace_fields(line)) is not None]

    print("Trace Report")
    print(f"window: {'stdin' if args.stdin else args.last}")
    print(f"events: {len(traces)}")
    print()

    if not traces:
        print("No trace.finish events found.")
        return

    kind_counter: Counter[str] = Counter()
    result_counter: Counter[str] = Counter()
    origin_counter: Counter[str] = Counter()
    route_counter: Counter[str] = Counter()
    latency_values: dict[str, list[float]] = {field: [] for field in LATENCY_FIELDS}

    for trace in traces:
        kind_counter.update([trace["kind"]])
        result_counter.update([trace["result"]])
        origin_counter.update([trace["origin"]])
        if route := trace.get("route"):
            route_counter.update([route])

        for field in LATENCY_FIELDS:
            raw_value = trace.get(field)
            if raw_value is None:
                continue
            try:
                latency_values[field].append(float(raw_value))
            except ValueError:
                continue

    emit_counter_section("kind", kind_counter)
    emit_counter_section("result", result_counter)
    emit_counter_section("origin", origin_counter)
    emit_counter_section("route", route_counter)

    print("latency")
    for field in LATENCY_FIELDS:
        values = latency_values[field]
        if not values:
            continue
        print(f"- {field}: {summarize_latency(values)}")


if __name__ == "__main__":
    main()
