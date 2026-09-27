#!/usr/bin/env python3
"""Merge automated evidence and human reviews into a Google Sheets-ready CSV."""

import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
RESULTS_DIR = ROOT / ".results"
MATRIX_PATH = ROOT / "experiments" / "test-matrix.csv"
OUTPUT_PATH = RESULTS_DIR / "summary.csv"

FIELDS = [
    "phase", "run_id", "task_id", "attempt", "candidate", "model_profile",
    "quantization", "shell", "reasoning_mode", "context", "max_output_tokens",
    "time_limit_minutes", "started_at", "finished_at", "autonomous_seconds",
    "feedback_seconds", "total_work_seconds", "feedback_cycles_recorded",
    "functional_feedback_seconds", "hygiene_feedback_seconds",
    "functional_result_seconds", "total_acceptance_seconds",
    "functional_feedback_cycles", "hygiene_only_feedback_cycles",
    "server_hourly_price", "cost_currency", "estimated_active_run_cost",
    "agent_session_logged", "agent_responses_recorded", "diagnostic_snapshots",
    "autonomous_checkpoint_saved",
    "baseline_tests", "final_tests", "changed_files", "lines_added", "lines_deleted",
    "ttft_seconds", "first_answer_token_seconds", "generation_tokens_per_second",
    "prompt_tokens", "output_tokens", "gpu_peak_memory_mib", "gpu_avg_util_percent",
    "gpu_peak_util_percent", "gpu_avg_power_w", "gpu_peak_power_w",
    "reasoning_trace_observed", "task_completed", "correctness_score",
    "code_quality_score", "test_quality_score", "tool_stability_score",
    "usability_score", "unnecessary_changes", "manual_interventions_count",
    "manual_interventions_notes", "maximum_stable_context_observed",
    "repeat_decision", "repeat_reason", "verdict", "main_reason", "uncertainty",
    "notes", "feedback_used", "feedback_cycles", "operator_minutes", "accepted_change",
    "final_correctness_score", "final_code_quality_score", "final_test_quality_score",
    "feedback_summary", "acceptance_notes", "hygiene_measurement_note",
]


def read_env(path):
    values = {}
    if not path.exists():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def read_text(path, default=""):
    return path.read_text(encoding="utf-8").strip() if path.exists() else default


def matrix_rows():
    if not MATRIX_PATH.exists():
        return [], {}
    with MATRIX_PATH.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    return rows, {row["run_id"]: row for row in rows}


def matrix_row_for(run_id, lookup):
    if run_id in lookup:
        return lookup[run_id]
    base_id = re.sub(r"-a[23]$", "-a1", run_id)
    row = dict(lookup.get(base_id, {}))
    if row:
        row["attempt"] = run_id.rsplit("-a", 1)[-1]
        row["phase"] = "repeat"
    return row


def diff_counts(run_dir):
    changed = len([line for line in read_text(run_dir / "git-status.txt").splitlines() if line])
    added = deleted = 0
    path = run_dir / "diff-numstat.txt"
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            parts = line.split("\t", 2)
            if len(parts) >= 2:
                if parts[0].isdigit():
                    added += int(parts[0])
                if parts[1].isdigit():
                    deleted += int(parts[1])
    return changed, added, deleted


def latest_api_metrics(run_dir):
    gpu = {"avg_util": "", "peak_util": "", "avg_power": "", "peak_power": ""}
    paths = list((run_dir / "api").glob("**/metrics.json"))
    if not paths:
        return {}, gpu
    path = max(paths, key=lambda item: item.stat().st_mtime)
    metrics = json.loads(path.read_text(encoding="utf-8"))
    gpu_path = path.parent / "gpu.csv"
    if gpu_path.exists():
        with gpu_path.open(newline="", encoding="utf-8") as handle:
            samples = list(csv.DictReader(handle))
        utils = [float(row["gpu_util_percent"]) for row in samples if row.get("gpu_util_percent")]
        powers = [float(row["power_w"]) for row in samples if row.get("power_w")]
        if utils:
            gpu["avg_util"] = round(sum(utils) / len(utils), 2)
            gpu["peak_util"] = round(max(utils), 2)
        if powers:
            gpu["avg_power"] = round(sum(powers) / len(powers), 2)
            gpu["peak_power"] = round(max(powers), 2)
    return metrics, gpu


def build_row(run_dir, lookup):
    run_id = run_dir.name
    metadata = read_env(run_dir / "metadata.env")
    matrix = matrix_row_for(run_id, lookup)
    review_path = run_dir / "review.json"
    review = json.loads(review_path.read_text(encoding="utf-8")) if review_path.exists() else {}
    metrics, gpu = latest_api_metrics(run_dir)
    changed, added, deleted = diff_counts(run_dir)
    autonomous_text = read_text(run_dir / "task-wall-seconds.txt")
    feedback_paths = sorted((run_dir / "timers").glob("feedback-*-seconds.txt"))
    feedback_values = [int(read_text(path, "0")) for path in feedback_paths]
    autonomous_value = int(autonomous_text) if autonomous_text.isdigit() else None
    feedback_seconds = sum(feedback_values)
    total_work_seconds = (
        autonomous_value + feedback_seconds if autonomous_value is not None else ""
    )
    hourly_price_text = metadata.get("SERVER_HOURLY_PRICE", "")
    try:
        estimated_cost = round(float(hourly_price_text) * float(total_work_seconds) / 3600, 4)
    except (TypeError, ValueError):
        estimated_cost = ""

    row = {
        "phase": matrix.get("phase", "unplanned"),
        "run_id": run_id,
        "task_id": metadata.get("TASK_ID", matrix.get("task", "")),
        "attempt": matrix.get("attempt", ""),
        "candidate": matrix.get("model", ""),
        "model_profile": metadata.get("MODEL", ""),
        "quantization": matrix.get("quantization", ""),
        "shell": metadata.get("SHELL", matrix.get("shell", "")),
        "reasoning_mode": metadata.get("REASONING_MODE", matrix.get("reasoning_mode", "")),
        "context": metrics.get("context", matrix.get("context", "")),
        "max_output_tokens": metrics.get("max_output_tokens", matrix.get("max_output_tokens", "")),
        "time_limit_minutes": matrix.get("time_limit_minutes", ""),
        "started_at": metadata.get("STARTED_AT", ""),
        "finished_at": metadata.get("FINISHED_AT", ""),
        "autonomous_seconds": autonomous_text,
        "feedback_seconds": feedback_seconds if feedback_paths else "",
        "total_work_seconds": total_work_seconds,
        "feedback_cycles_recorded": len(feedback_paths),
        "server_hourly_price": hourly_price_text,
        "cost_currency": metadata.get("COST_CURRENCY", ""),
        "estimated_active_run_cost": estimated_cost,
        "agent_session_logged": "yes" if (run_dir / "agent-session" / "terminal.log").exists() else "no",
        "agent_responses_recorded": len(list((run_dir / "agent-responses").glob("*.txt"))),
        "diagnostic_snapshots": len([path for path in (run_dir / "logs").glob("*") if path.is_dir()]),
        "autonomous_checkpoint_saved": "yes" if (run_dir / "checkpoints" / "autonomous").exists() else "no",
        "baseline_tests": read_text(run_dir / "baseline-test-status.txt", "unknown"),
        "final_tests": read_text(run_dir / "final-test-status.txt", "not-finished"),
        "changed_files": changed,
        "lines_added": added,
        "lines_deleted": deleted,
        "ttft_seconds": metrics.get("time_to_first_token_seconds", ""),
        "first_answer_token_seconds": metrics.get("time_to_first_answer_token_seconds", ""),
        "generation_tokens_per_second": metrics.get("generation_tokens_per_second", ""),
        "prompt_tokens": metrics.get("prompt_tokens", ""),
        "output_tokens": metrics.get("output_tokens", ""),
        "gpu_peak_memory_mib": metrics.get("gpu_peak_memory_mib", ""),
        "gpu_avg_util_percent": gpu["avg_util"],
        "gpu_peak_util_percent": gpu["peak_util"],
        "gpu_avg_power_w": gpu["avg_power"],
        "gpu_peak_power_w": gpu["peak_power"],
        "reasoning_trace_observed": metrics.get("reasoning_trace_observed", ""),
    }
    for field in FIELDS:
        if field in review:
            row[field] = review[field]
    if matrix.get("phase") == "reference":
        for field in (
            "context", "max_output_tokens", "ttft_seconds", "first_answer_token_seconds",
            "generation_tokens_per_second", "prompt_tokens", "output_tokens",
            "gpu_peak_memory_mib", "gpu_avg_util_percent", "gpu_peak_util_percent",
            "gpu_avg_power_w", "gpu_peak_power_w", "reasoning_trace_observed",
        ):
            row[field] = "N/A"
        row["server_hourly_price"] = "N/A"
        row["cost_currency"] = "N/A"
        row["estimated_active_run_cost"] = "N/A"
    return {field: "" if row.get(field) is None else row.get(field, "") for field in FIELDS}


def main():
    RESULTS_DIR.mkdir(exist_ok=True)
    ordered_matrix, lookup = matrix_rows()
    order = {row["run_id"]: index for index, row in enumerate(ordered_matrix)}
    run_dirs = [path for path in RESULTS_DIR.iterdir() if path.is_dir() and (path / "metadata.env").exists()]
    run_dirs.sort(key=lambda path: (order.get(re.sub(r"-a[23]$", "-a1", path.name), 10_000), path.name))
    rows = [build_row(path, lookup) for path in run_dirs]
    temporary = OUTPUT_PATH.with_suffix(".csv.tmp")
    with temporary.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(OUTPUT_PATH)
    print(f"Summary updated: {OUTPUT_PATH} ({len(rows)} runs)")


if __name__ == "__main__":
    main()
