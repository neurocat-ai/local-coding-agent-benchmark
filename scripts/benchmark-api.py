#!/usr/bin/env python3
"""Stream one Ollama request and record latency, throughput, and GPU memory."""
import argparse
import csv
import json
import os
import subprocess
import threading
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


def gpu_sample():
    try:
        raw = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=timestamp,memory.used,utilization.gpu,power.draw", "--format=csv,noheader,nounits"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
        fields = [item.strip() for item in raw.splitlines()[0].split(",")]
        return fields
    except (OSError, subprocess.SubprocessError, IndexError):
        return None


parser = argparse.ArgumentParser()
parser.add_argument("--model", required=True)
parser.add_argument("--prompt", required=True)
parser.add_argument("--label", default="api-benchmark")
parser.add_argument("--run-id", help="Attach metrics to an existing .results/RUN_ID directory")
parser.add_argument("--context", type=int, default=int(os.environ.get("OLLAMA_CONTEXT_LENGTH", "32768")))
parser.add_argument("--max-output-tokens", type=int, default=8192)
parser.add_argument("--reasoning", choices=("auto", "on", "off", "low", "medium", "high"), default="auto")
args = parser.parse_args()

reasoning = args.reasoning
if reasoning == "auto":
    reasoning = "medium" if "gpt-oss" in args.model else "on"
think_value = {"on": True, "off": False}.get(reasoning, reasoning)

safe_label = "".join(c if c.isalnum() or c in "-_" else "-" for c in args.label)
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
if args.run_id:
    run_result_dir = Path(".results") / args.run_id
    if not (run_result_dir / "metadata.env").exists():
        parser.error(f"unknown run ID: {args.run_id}")
    out_dir = run_result_dir / "api" / f"{stamp}-{safe_label}"
else:
    out_dir = Path(".results") / f"{stamp}-{safe_label}"
out_dir.mkdir(parents=True, exist_ok=False)
samples = []
sampling = True


def monitor():
    while sampling:
        sample = gpu_sample()
        if sample:
            samples.append([time.time(), *sample])
        time.sleep(0.25)


thread = threading.Thread(target=monitor, daemon=True)
thread.start()
body = {
    "model": args.model,
    "stream": True,
    "think": think_value,
    "options": {"num_ctx": args.context, "num_predict": args.max_output_tokens},
    "messages": [{"role": "user", "content": args.prompt}],
}
request = urllib.request.Request(
    f"http://127.0.0.1:{os.environ.get('OLLAMA_PORT', '11434')}/api/chat",
    data=json.dumps(body).encode(),
    headers={"Content-Type": "application/json"},
)
started = time.perf_counter()
first_token = None
first_answer_token = None
chunks = []
thinking_chunks = []
final = {}
try:
    with urllib.request.urlopen(request, timeout=1800) as response:
        for line in response:
            event = json.loads(line)
            text = event.get("message", {}).get("content", "")
            thinking_text = event.get("message", {}).get("thinking", "")
            if (text or thinking_text) and first_token is None:
                first_token = time.perf_counter()
            if text and first_answer_token is None:
                first_answer_token = time.perf_counter()
            chunks.append(text)
            thinking_chunks.append(thinking_text)
            if event.get("done"):
                final = event
finally:
    sampling = False
    thread.join(timeout=2)
finished = time.perf_counter()

with (out_dir / "gpu.csv").open("w", newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["epoch", "nvidia_timestamp", "memory_used_mib", "gpu_util_percent", "power_w"])
    writer.writerows(samples)
(out_dir / "response.txt").write_text("".join(chunks), encoding="utf-8")
(out_dir / "thinking.txt").write_text("".join(thinking_chunks), encoding="utf-8")
(out_dir / "request.json").write_text(json.dumps(body, ensure_ascii=False, indent=2), encoding="utf-8")

eval_count = final.get("eval_count")
eval_duration_ns = final.get("eval_duration")
metrics = {
    "label": args.label,
    "model": args.model,
    "context": args.context,
    "max_output_tokens": args.max_output_tokens,
    "reasoning_mode_requested": reasoning,
    "wall_seconds": round(finished - started, 3),
    "time_to_first_token_seconds": round(first_token - started, 3) if first_token else None,
    "time_to_first_answer_token_seconds": round(first_answer_token - started, 3) if first_answer_token else None,
    "reasoning_trace_observed": any(thinking_chunks),
    "prompt_tokens": final.get("prompt_eval_count"),
    "output_tokens": eval_count,
    "generation_tokens_per_second": round(eval_count / (eval_duration_ns / 1e9), 3) if eval_count and eval_duration_ns else None,
    "load_seconds": round(final.get("load_duration", 0) / 1e9, 3),
    "gpu_peak_memory_mib": max((int(row[2]) for row in samples), default=None),
    "created_at": datetime.now(timezone.utc).isoformat(),
}
(out_dir / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(metrics, ensure_ascii=False, indent=2))
print(out_dir)
