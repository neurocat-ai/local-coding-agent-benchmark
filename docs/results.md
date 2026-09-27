# Results

## Reading the data

`results.csv` contains one row per primary run. Autonomous scores describe the first checkpoint. Final scores describe the accepted state after recorded feedback. A feedback cycle is part of the result because it measures how much operator guidance the configuration needed.

API measurements came from direct Ollama requests outside the agent shell. Missing values remain `N/A`; the benchmark does not interpolate them.

## Observations

### Model comparison in Qwen Code

Both local models completed ERP-003 and ERP-004 without semantic feedback. The concurrency task, ERP-001, separated them: Qwen needed four correction cycles and 1,762 seconds to acceptance; gpt-oss needed three cycles and 1,140 seconds.

On the measured API runs, Qwen used about 38.6 GiB peak VRAM and generated 102.6 to 116.2 tokens/s. gpt-oss used about 63.0 GiB and generated 113.1 to 119.1 tokens/s. TTFT for two gpt-oss runs exceeded 20 seconds despite higher steady-state throughput, so throughput alone does not describe interactive performance.

### Shell comparison on gpt-oss-120b

OpenHands reached clean acceptance across the three tasks in 544 active seconds. Qwen Code required 1,519 seconds on the same gpt-oss-120b model. OpenHands therefore won the shell comparison on active time, including its recorded cleanup cycles.

That speed came with operational costs. OpenHands created unrelated installer files on all three tasks, required technical setup work, and needed two functional feedback cycles on ERP-001. Its first ERP-001 result did not compile and used an ineffective test. Qwen Code had no equivalent installer artifacts in the captured evidence, although its earlier untracked-file capture was weaker.

The shell comparison also exposed a measurement gap: the requested reasoning setting did not reach the model in the OpenHands configuration. These runs remain useful shell observations, but they do not prove a controlled reasoning-mode comparison.

### Cloud reference

Codex solved ERP-003 and ERP-004 cleanly on review. Its first ERP-001 implementation missed the same concurrent check-then-add race that challenged the local configurations. One feedback cycle produced the accepted result.

Provider-side TTFT, generation rate, VRAM, and effective context were unavailable. The reference rows therefore support quality and workflow comparisons, not hardware-efficiency claims.

## Conclusion

The experiment made two separate choices. First, gpt-oss-120b beat Qwen3.6 Q8 when both ran through Qwen Code: it needed fewer corrections on ERP-001 and delivered higher measured throughput, at the cost of roughly 24 GiB more peak VRAM. Second, OpenHands beat Qwen Code on active time with gpt-oss-120b, 544 seconds versus 1,519 seconds across the three tasks.

The next stage therefore selected **gpt-oss-120b with OpenHands**. That choice accepts extra hygiene controls and setup work in exchange for faster accepted results. The architecture should isolate each workspace, restrict tool permissions, reject unrelated artifacts, and keep independent tests outside the agent. This conclusion separates model quality from shell behavior instead of treating them as one score.
