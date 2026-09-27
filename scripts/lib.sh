#!/usr/bin/env bash

lab_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$lab_root"

if [[ ! -f .env ]]; then
  cp .env.example .env
fi
set -a
# shellcheck disable=SC1091
source .env
set +a

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "Required command is missing: $1" >&2; exit 1; }
}

wait_for_ollama() {
  local attempts=0
  until curl --fail --silent "http://127.0.0.1:${OLLAMA_PORT}/api/tags" >/dev/null; do
    attempts=$((attempts + 1))
    if (( attempts >= 90 )); then echo "Ollama did not become ready in time." >&2; return 1; fi
    sleep 2
  done
}

resolve_model() {
  case "${1:-}" in
    qwen|qwen-q8|qwen36-q8) printf '%s\n' "$QWEN_MODEL_PROFILE" ;;
    qwen-q4|qwen36-q4) printf '%s\n' "$QWEN_Q4_MODEL_PROFILE" ;;
    qwen-coding-q4|qwen36-coding-q4) printf '%s\n' "$QWEN_CODING_Q4_MODEL_PROFILE" ;;
    gpt-oss|gptoss|gpt-oss-120b) printf '%s\n' "$GPTOSS_MODEL_PROFILE" ;;
    gpt-oss-20b|gptoss-20b) printf '%s\n' "$GPTOSS_LITE_MODEL_PROFILE" ;;
    *) echo "Unknown model '$1'. Use qwen, gpt-oss, qwen-q4, qwen-coding-q4, or gpt-oss-20b." >&2; return 2 ;;
  esac
}

baseline_commit_for_run() {
  local run_dir="$1"
  local result_dir="$2"
  local baseline=""

  if [[ -f "$result_dir/metadata.env" ]]; then
    baseline="$(sed -n 's/^BASELINE_COMMIT=//p' "$result_dir/metadata.env" | tail -n 1)"
  fi
  if [[ -z "$baseline" ]]; then
    baseline="$(git -C "$run_dir" rev-list --max-parents=0 --reverse HEAD | head -n 1)"
  fi
  git -C "$run_dir" cat-file -e "${baseline}^{commit}" 2>/dev/null || {
    echo "Cannot resolve baseline commit for $run_dir" >&2
    return 1
  }
  printf '%s\n' "$baseline"
}

capture_git_evidence() {
  local run_dir="$1"
  local output_dir="$2"
  local baseline
  local untracked_file
  local status

  baseline="$(baseline_commit_for_run "$run_dir" "${3:-$output_dir}")"
  mkdir -p "$output_dir"
  printf '%s\n' "$baseline" > "$output_dir/baseline-commit.txt"
  git -C "$run_dir" rev-parse HEAD > "$output_dir/final-head.txt"
  git -C "$run_dir" status --short > "$output_dir/git-status.txt"
  git -C "$run_dir" log --reverse --format='%H %s' "${baseline}..HEAD" > "$output_dir/commits-since-baseline.txt"
  git -C "$run_dir" ls-files --others --exclude-standard > "$output_dir/untracked-files.txt"
  git -C "$run_dir" diff --binary "$baseline" -- > "$output_dir/changes.patch"

  while IFS= read -r -d '' untracked_file; do
    set +e
    (cd "$run_dir" && git diff --no-index --binary -- /dev/null "$untracked_file") >> "$output_dir/changes.patch"
    status="$?"
    set -e
    if [[ "$status" -ne 0 && "$status" -ne 1 ]]; then
      echo "Failed to capture untracked file: $untracked_file" >&2
      return "$status"
    fi
  done < <(git -C "$run_dir" ls-files --others --exclude-standard -z)

  git apply --stat < "$output_dir/changes.patch" > "$output_dir/diff-stat.txt" || true
  git apply --numstat < "$output_dir/changes.patch" > "$output_dir/diff-numstat.txt" || true
}
