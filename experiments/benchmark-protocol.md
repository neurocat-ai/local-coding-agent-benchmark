# Benchmark protocol

## Immutable baseline

`demo/guard-erp` is the canonical baseline. No evaluated agent may work in it directly.
Do not merge one agent's solution into the baseline during the benchmark.

Before every attempt, the operator runs `scripts/prepare-run.sh`. It creates a fresh
repository under `.runs/`, inserts the selected task as `TASK.md`, records metadata,
and commits the starting state. The evaluated agent works only in that prepared copy.

## Comparable branches

Every model and shell receives the same baseline, task text, time limit, and external
rules. Results form independent branches rather than a sequence of agents continuing
each other's work. Chronology is preserved through run IDs, timestamps, commits,
patches, test logs, and result reviews.

Run IDs follow this pattern:

```text
<candidate>-<task-lowercase>-a<attempt>
```

Examples: `qwen-q8-erp001-a1`, `gptoss120-erp001-a1`, `codex-erp001-a1`.

## Prompt boundary

The coding agent receives the prepared repository and the contents of `TASK.md`.
Repository-wide instructions live in `AGENTS.md` for Codex and `QWEN.md` for Qwen
Code. Do not ask the evaluated agent to create its own benchmark copy, measure its
own infrastructure, grade its own work, or compare itself with another candidate.

The operator controls timing and evidence collection outside the evaluated agent.
After completion, `finish-run.sh` records the diff and final tests. Human review uses
`scoring-guide.md`.

## Result lifecycle

1. `prepare-run.sh` creates `.results/RUN_ID`, metadata, and an empty `review.json`.
2. `benchmark-api.py --run-id RUN_ID` stores preflight metrics under that same run.
3. `timer.sh` records the autonomous stage and any later feedback cycles separately.
4. `checkpoint-run.sh RUN_ID autonomous` freezes the first result before any feedback.
5. If feedback is needed, continue in the same branch and record checkpoints such as
   `feedback-1`; a clean `a2` remains reserved for anomaly verification.
6. `finish-run.sh` records the final tests and patch, then rebuilds `.results/summary.csv`.
7. After the operator and reviewer agree on an assessment, update `review.json` and
   run `scripts/build-summary.py` again.
8. `export-results.sh` performs one final rebuild before creating the archive.
9. Import `.results/summary.csv` into Google Sheets only after the experiment ends.

The run ID is the join key for automatic evidence, observations, review scores, and
repeats. `review.json` is the structured source for human judgments. `review.md` may
hold free-form rationale but is not parsed into the summary.

## Diagnostic logs

Run terminal-based agents through `capture-agent-session.sh`; it gives the process a
pseudo-terminal and stores its output, command, timestamps, and exit status under
`.results/RUN_ID/agent-session/`. Store each visible final response with
`save-agent-response.sh`.

Preparation, checkpoints, and finalization call `collect-run-logs.sh` automatically.
Each snapshot includes host capacity, GPU state, Compose state and images, Ollama
logs and loaded models, and OpenHands event logs when that service is active. Logs
are collected from the run start time and stored under `.results/RUN_ID/logs/LABEL`.
The export step also creates a complete end-of-day infrastructure snapshot.

Use metrics to identify the symptom and logs plus tests, patches, and checkpoints to
attribute it to the model, shell, or infrastructure. Do not infer a root cause from
one metric alone.

## Cloud Codex reference

Cloud Codex is a reference for task quality, autonomy, tool stability, tests, diff,
and end-to-end completion time. Provider-side TTFT, token throughput, GPU memory,
power, and maximum effective context are unavailable and must be marked `N/A`, not
estimated or requested from the agent.

The Codex model name and reasoning effort actually selected in the app must be added
to the result metadata at run time. A different model or effort is a different
reference configuration.
