# Scoring guide

Use the same clean repository, task text, context limit, and time limit for comparable runs.

## Repetition policy

- Run every planned model/task/shell combination once (`a1`).
- Add `a2` only when the first result needs verification: it finished implausibly quickly; its final claim conflicts with the diff or test output; a tool or infrastructure failure may have affected it; or the result is an unexpected outlier compared with the other tasks.
- A clear quality failure with normally working tools is a valid result and is not automatically repeated.
- If `a2` reproduces the same anomaly as `a1`, do not run `a3`: record the behavior as reproducible and diagnose whether it belongs to the model, shell, or infrastructure layer.
- If `a2` does not reproduce the anomaly and therefore materially disagrees with `a1`, run `a3` as the deciding attempt. Material disagreement means that one attempt completes the task and the other does not, or their correctness scores differ by 2 or more.
- A confirmed infrastructure failure is not a model result. Mark it separately, fix the environment, and repeat with a new run ID.
- Never reuse an edited working copy. Each attempt must be created with `prepare-run.sh`.
- Name repeats by replacing `-a1` with `-a2` or `-a3`; they do not need permanent rows in the initial matrix.
- OpenHands receives all three tasks and the same adaptive repetition rule. Failure on one task does not stop the remaining tasks.

- Correctness: 5 = all requirements and edge cases pass; 3 = core behavior works with a material omission; 1 = incorrect or unusable.
- Code quality: 5 = focused, idiomatic, maintainable; 3 = works but has avoidable complexity; 1 = unsafe or broadly disruptive.
- Test quality: 5 = relevant positive and boundary cases; 3 = only the happy path; 1 = missing or misleading tests.
- Tool-use stability: 5 = completes autonomously without malformed calls; 3 = one or two recoverable failures; 1 = repeated failures or chatbot-only behavior.
- Usability: 5 = progress is clear and no operator attention is needed; 3 = understandable but requires monitoring; 1 = confusing, blocking, or intervention-heavy.

Store agreed manual values in `.results/RUN_ID/review.json`. Scores are integers from 1 to 5; `task_completed` is `yes`, `partial`, or `no`; `unnecessary_changes` is `none`, `minor`, or `major`; `repeat_decision` is `no`, `a2`, or `a3`. Leave a field `null` until it has actually been reviewed rather than guessing a value.

## Assisted acceptance hypothesis

Preserve the first autonomous result and its scores before giving feedback. If the
change is not acceptable, the operator may give the same kind of concise review a
developer would normally give. Continue in the same repository and conversation;
this is a feedback cycle, not a clean repeat (`a2`).

Before feedback, run `checkpoint-run.sh RUN_ID autonomous`. Time each correction as
`feedback-1`, `feedback-2`, and so on. Record the feedback text or a concise faithful
summary. Stop when the change is accepted or the operator decides further work is
not worthwhile.

Report both outcomes:

- autonomous quality and time, before any human hint;
- final accepted quality, number of feedback cycles, feedback time, and total work
  time to acceptance;
- operator minutes and estimated active-run compute cost. Reconcile the latter with
  the provider invoice because parallel work and idle rental time are billed too.

Apply the same feedback standard to local agents and Codex. Do not paste another
agent's implementation or reveal its solution. This assisted metric is exploratory
in sprint one and must not replace the autonomous comparison.

Primary ranking order: correctness, stability, task completion time, code quality, then raw token speed. A faster model does not win if it produces a worse or less autonomous result.

## Functional versus hygiene-only feedback

Classify every feedback cycle as either functional or hygiene-only. Functional
feedback changes behavior, safety, compilation, or meaningful test coverage.
Hygiene-only feedback removes unrelated artifacts without changing task
behavior. Record their counts and seconds separately, together with:

- functional result time: autonomous time plus functional feedback time;
- hygiene cleanup time;
- total time to acceptance.

Hygiene-only feedback does not reduce correctness or task-completion scores.
It does affect `unnecessary_changes`, tool-use quality, usability, and total
time to an accepted clean patch.

The earlier Qwen Code and Codex runs used a weaker untracked-file capture path.
When comparing them with runs captured after the fix, the absence of recorded
hygiene feedback in those earlier runs means `not measured reliably`, not a
proven zero.

For each combination report task success, end-to-end duration, TTFT, generation speed, peak VRAM, and the number of manual interventions. If repeats were needed, keep every attempt visible and also report their median; do not hide instability behind an average.
