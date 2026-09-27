# Limitations

- Three tasks from one small C# fixture cannot represent general coding ability.
- Each planned configuration ran once. The protocol allowed repeats for anomalies, but the published table does not estimate run-to-run variance.
- Human review supplied correctness, code-quality, test-quality, stability, and usability scores.
- Qwen Code and OpenHands expose different tools and interaction models. The shell comparison measures the full configuration, not the model in isolation.
- OpenHands did not transmit the requested reasoning setting. Its rows cannot support a controlled reasoning-mode conclusion.
- API TTFT and throughput use direct Ollama calls. Agent wall time includes planning, tool use, tests, and shell overhead.
- Some API measurements are missing. Missing values stay `N/A`.
- Earlier Qwen Code and Codex runs used weaker untracked-file capture. Absence of recorded hygiene problems in those rows does not prove that none occurred.
- Two cloud-reference test runs were accepted on code review because the local execution runtime was unavailable at the time. Their final test field says `deferred`.
- Costs reflect active-run estimates, not the provider invoice or total rented-server time.
- Model tags and third-party images were recorded by name, not immutable digest, in parts of the original experiment.
- The public Compose file uses the exact recorded Agent Canvas 1.16.0 image digest with bundled agent-server/SDK 1.44.0, but reconstructs sanitized runtime wiring instead of publishing the original host configuration.
