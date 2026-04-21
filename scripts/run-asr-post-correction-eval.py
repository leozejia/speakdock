#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import resource
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SYSTEM_PROMPT = """你是一个保守的语音转写纠错器。
你的任务是只修复明显识别错误。
只允许修正术语、人名、中英混输、同音误识别和极少量缺失标点。
如果原文已经正确，就原样返回。
不要润色，不要改写，不要删减，不要扩写。
不要改变结构、语气、顺序或信息密度。
输出时只返回修正后的正文，不要解释，不要加引号，不要加标题。
"""

FEWSHOT_EXAMPLES = """示例：
输入：project adults 已经完成
输出：Project Atlas 已经完成

输入：先跑 make smoke asr correction
输出：先跑 make smoke-asr-correction

输入：现在先把评测炸门写死
输出：现在先把评测闸门写死

输入：今天先补匿名夹具。
输出：今天先补匿名夹具。
"""


@dataclass
class FixtureSample:
    id: str
    input: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fixture", required=True)
    parser.add_argument("--results", required=True)
    parser.add_argument("--model-path")
    parser.add_argument("--mock-responses")
    parser.add_argument(
        "--prompt-profile",
        default="fewshot",
        choices=("conservative", "fewshot"),
    )
    parser.add_argument("--max-tokens", type=int, default=48)
    args = parser.parse_args()

    if not args.model_path and not args.mock_responses:
        parser.error("either --model-path or --mock-responses is required")
    if args.model_path and args.mock_responses:
        parser.error("use either --model-path or --mock-responses, not both")

    return args


def load_fixture(path: Path) -> list[FixtureSample]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return [
        FixtureSample(id=sample["id"], input=sample["input"])
        for sample in payload["samples"]
    ]


def make_user_prompt(text: str, prompt_profile: str) -> str:
    prefix = ""
    if prompt_profile == "fewshot":
        prefix = FEWSHOT_EXAMPLES + "\n"

    return (
        f"{prefix}请只修正下面转写文本里的明显识别错误；如果没有明显错误，就原样返回：\n\n"
        f"输入：{text}\n"
        "输出："
    )


def normalize_peak_rss(raw_value: float) -> float:
    if raw_value <= 0:
        return 0.0

    if raw_value > 10_000_000:
        return raw_value / 1024 / 1024

    return raw_value / 1024


def peak_rss_mb() -> float:
    usage = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return normalize_peak_rss(usage)


def clean_output(output: str) -> str:
    return output.replace("<|im_end|>", "").replace("<|endoftext|>", "").strip()


def run_mock_eval(
    samples: list[FixtureSample],
    mock_responses_path: Path,
) -> list[dict[str, Any]]:
    payload = json.loads(mock_responses_path.read_text(encoding="utf-8"))
    results: list[dict[str, Any]] = []

    for sample in samples:
        response = payload.get(sample.id, {})
        output = str(response.get("output", sample.input))
        latency_ms = response.get("latency_ms", 0.0)
        peak_rss = response.get("peak_rss_mb", 0.0)
        outcome = "corrected" if output != sample.input else "unchanged"
        results.append(
            {
                "id": sample.id,
                "output": output,
                "latency_ms": float(latency_ms),
                "peak_rss_mb": float(peak_rss),
                "outcome": outcome,
            }
        )

    return results


def run_model_eval(
    samples: list[FixtureSample],
    model_path: str,
    prompt_profile: str,
    max_tokens: int,
) -> list[dict[str, Any]]:
    try:
        from mlx_lm import generate, load
    except ImportError as error:
        raise SystemExit(
            "mlx_lm is required for --model-path runs; install mlx-lm or run with the project eval venv"
        ) from error

    model, tokenizer = load(model_path)
    results: list[dict[str, Any]] = []

    for sample in samples:
        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": make_user_prompt(sample.input, prompt_profile)},
        ]
        prompt = tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
            enable_thinking=False,
        )
        started = time.perf_counter()
        output = generate(
            model,
            tokenizer,
            prompt=prompt,
            max_tokens=max_tokens,
            verbose=False,
        )
        latency_ms = (time.perf_counter() - started) * 1000
        output = clean_output(output)
        outcome = "corrected" if output != sample.input else "unchanged"
        results.append(
            {
                "id": sample.id,
                "output": output,
                "latency_ms": round(latency_ms, 2),
                "peak_rss_mb": round(peak_rss_mb(), 2),
                "outcome": outcome,
            }
        )

    return results


def main() -> None:
    args = parse_args()
    fixture_path = Path(args.fixture)
    results_path = Path(args.results)
    results_path.parent.mkdir(parents=True, exist_ok=True)

    samples = load_fixture(fixture_path)

    if args.mock_responses:
        results = run_mock_eval(samples, Path(args.mock_responses))
        driver = "mock"
    else:
        results = run_model_eval(
            samples=samples,
            model_path=args.model_path,
            prompt_profile=args.prompt_profile,
            max_tokens=args.max_tokens,
        )
        driver = "mlx"

    results_path.write_text(
        json.dumps(results, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("ASR Post-Correction Eval Runner")
    print(f"samples: {len(samples)}")
    print(f"prompt profile: {args.prompt_profile}")
    print(f"driver: {driver}")
    print(f"results: {results_path}")


if __name__ == "__main__":
    main()
