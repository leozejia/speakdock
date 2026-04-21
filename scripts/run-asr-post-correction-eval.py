#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import resource
import subprocess
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

TERM_STYLE_HINT = "尤其注意产品名、仓库名、命令名、字段名、环境变量、路径、模型 ID 的大小写、连字符、下划线、斜杠和数字格式。"

TERM_STYLE_EXAMPLES = """示例：
输入：speak doc 今天更稳定
输出：SpeakDock 今天更稳定

输入：open ai compatible 接口先留着
输出：OpenAI-compatible 接口先留着

输入：codex cli 保持在 path 里
输出：Codex CLI 保持在 PATH 里

输入：这个 commit 先 push 到 dev internal
输出：这个 commit 先 push 到 dev/internal

输入：把 base url api key model 先补齐
输出：把 baseURL / apiKey / model 先补齐

输入：先看 qwen three asr zero point six b
输出：先看 Qwen3-ASR-0.6B
"""

HOMOPHONE_HINT = "如果某个中文词明显是同音误识别，且改正后更符合当前工程语境，应直接修正。"

HOMOPHONE_EXAMPLES = """示例：
输入：现在先把评测炸门写死
输出：现在先把评测闸门写死

输入：这里不要再票移了
输出：这里不要再漂移了

输入：先把诊断毛点补上
输出：先把诊断锚点补上

输入：把首轮街果贴出来
输出：把首轮结果贴出来
"""

ENGINEERING_FRAGMENT_HINTS: list[tuple[str, str]] = [
    ("should change", "should_change"),
    ("mlx community", "mlx-community"),
    ("make asr sample report", "make asr-sample-report"),
    ("qwen three point five", "Qwen3.5"),
    ("qwen slash qwen", "Qwen/Qwen"),
    ("zero point eight b", "0.8B"),
    ("two b", "2B"),
    ("opt iq", "OptiQ"),
    ("four bit", "4bit"),
    ("gemma three one b it four bit", "Gemma 3 1B it 4bit"),
    ("base url", "baseURL"),
    ("api key", "apiKey"),
    ("dev internal", "dev/internal"),
    ("codex cli", "Codex CLI"),
    ("open ai compatible", "OpenAI-compatible"),
]


@dataclass
class FixtureSample:
    id: str
    input: str


def prompt_profiles() -> list[str]:
    return [
        "conservative",
        "fewshot",
        "fewshot_terms",
        "fewshot_terms_homophone",
    ]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fixture", required=True)
    parser.add_argument("--results", required=True)
    parser.add_argument("--model-path")
    parser.add_argument("--mock-responses")
    parser.add_argument("--base-url")
    parser.add_argument("--api-key")
    parser.add_argument("--api-key-env", default="OPENAI_API_KEY")
    parser.add_argument("--model")
    parser.add_argument(
        "--prompt-profile",
        default="fewshot_terms_homophone",
        choices=prompt_profiles(),
    )
    parser.add_argument("--max-tokens", type=int, default=48)
    parser.add_argument("--request-timeout-seconds", type=float, default=60)
    args = parser.parse_args()

    remote_selected = any(
        value is not None and str(value).strip()
        for value in (args.base_url, args.api_key, args.model)
    )
    driver_count = sum(
        [
            bool(args.model_path),
            bool(args.mock_responses),
            bool(remote_selected),
        ]
    )

    if driver_count == 0:
        parser.error("either --model-path or --mock-responses is required")
    if driver_count > 1:
        parser.error("use exactly one driver: --model-path, --mock-responses, or openai-compatible config")

    resolved_api_key = args.api_key
    if remote_selected and not resolved_api_key and args.api_key_env:
        resolved_api_key = os.environ.get(args.api_key_env)

    if remote_selected:
        if not args.base_url or not args.model or not resolved_api_key:
            parser.error("openai-compatible runs require --base-url, --model, and an API key")
        setattr(args, "resolved_api_key", resolved_api_key)

    return args


def load_fixture(path: Path) -> list[FixtureSample]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return [
        FixtureSample(id=sample["id"], input=sample["input"])
        for sample in payload["samples"]
    ]


def make_user_prompt(text: str, prompt_profile: str) -> str:
    prefix_parts: list[str] = []
    if prompt_profile in {"fewshot", "fewshot_terms", "fewshot_terms_homophone"}:
        prefix_parts.append(FEWSHOT_EXAMPLES)
    if prompt_profile in {"fewshot_terms", "fewshot_terms_homophone"}:
        prefix_parts.append(TERM_STYLE_HINT)
        prefix_parts.append(TERM_STYLE_EXAMPLES)
    if prompt_profile == "fewshot_terms_homophone":
        prefix_parts.append(HOMOPHONE_HINT)
        prefix_parts.append(HOMOPHONE_EXAMPLES)

    engineering_hint_block = make_engineering_hint_block(text)
    if engineering_hint_block:
        prefix_parts.append(engineering_hint_block)

    prefix = ""
    if prefix_parts:
        prefix = "\n\n".join(prefix_parts) + "\n\n"

    return (
        f"{prefix}请只修正下面转写文本里的明显识别错误；如果没有明显错误，就原样返回：\n\n"
        f"输入：{text}\n"
        "输出："
    )


def make_engineering_hint_block(text: str) -> str:
    normalized_text = text.lower()
    seen_canonicals: set[str] = set()
    lines: list[str] = []

    for spoken, canonical in ENGINEERING_FRAGMENT_HINTS:
        if spoken in normalized_text and canonical not in seen_canonicals:
            seen_canonicals.add(canonical)
            lines.append(f"- {spoken} -> {canonical}")

    if not lines:
        return ""

    return (
        "以下工程片段如果明显是在指向固定写法，优先恢复成右侧格式：\n"
        + "\n".join(lines)
        + "\n不要把右侧写法改成自然语言、空格写法或别的大小写形式。"
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
    cleaned = output.replace("<|im_end|>", "").replace("<|endoftext|>", "").strip()

    if cleaned.startswith("输入：") and "\n输出：" in cleaned:
        cleaned = cleaned.split("\n输出：")[-1].strip()
    elif cleaned.startswith("输出："):
        cleaned = cleaned.removeprefix("输出：").strip()

    return cleaned


def endpoint_url(base_url: str) -> str:
    trimmed = base_url.strip()
    if trimmed.endswith("/chat/completions"):
        return trimmed
    return trimmed.rstrip("/") + "/chat/completions"


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


def run_openai_eval(
    samples: list[FixtureSample],
    base_url: str,
    api_key: str,
    model: str,
    prompt_profile: str,
    timeout_seconds: float,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    url = endpoint_url(base_url)

    for sample in samples:
        started = time.perf_counter()
        try:
            payload = json.dumps(
                {
                    "model": model,
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {
                            "role": "user",
                            "content": make_user_prompt(sample.input, prompt_profile),
                        },
                    ],
                    "temperature": 0,
                },
                ensure_ascii=False,
            )
            completed = subprocess.run(
                [
                    "curl",
                    "-sS",
                    "--max-time",
                    str(timeout_seconds),
                    "-H",
                    f"Authorization: Bearer {api_key}",
                    "-H",
                    "Content-Type: application/json",
                    "--data-binary",
                    "@-",
                    "-o",
                    "-",
                    "-w",
                    "\n__HTTP_STATUS__:%{http_code}",
                    url,
                ],
                input=payload,
                capture_output=True,
                text=True,
                check=False,
            )

            if completed.returncode != 0:
                raise SystemExit(
                    f"openai-compatible request failed for sample {sample.id}: {completed.stderr.strip() or 'curl failed'}"
                )

            marker = "\n__HTTP_STATUS__:"
            if marker not in completed.stdout:
                raise SystemExit(
                    f"openai-compatible request failed for sample {sample.id}: invalid response"
                )

            response_body, status_text = completed.stdout.rsplit(marker, 1)
            status_code = int(status_text.strip())
            if not 200 <= status_code <= 299:
                raise SystemExit(
                    f"openai-compatible request failed for sample {sample.id}: HTTP {status_code}"
                )

            response_payload = json.loads(response_body)
            content = str(
                response_payload.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
            )
            output = clean_output(content)
            if output:
                outcome = "corrected" if output != sample.input else "unchanged"
            else:
                output = sample.input
                outcome = "fallback"
        except (subprocess.TimeoutExpired, json.JSONDecodeError, KeyError, IndexError, ValueError) as error:
            raise SystemExit(
                f"openai-compatible request failed for sample {sample.id}: invalid response"
            ) from error

        latency_ms = (time.perf_counter() - started) * 1000
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
    elif args.base_url:
        results = run_openai_eval(
            samples=samples,
            base_url=args.base_url,
            api_key=args.resolved_api_key,
            model=args.model,
            prompt_profile=args.prompt_profile,
            timeout_seconds=args.request_timeout_seconds,
        )
        driver = "openai-compatible"
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
