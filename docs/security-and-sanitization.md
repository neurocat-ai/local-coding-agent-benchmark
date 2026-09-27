# Security and sanitization

## Included

- benchmark protocol, task prompts, scoring rubric, and completed matrix;
- compact result rows needed to audit the stated conclusions;
- model profiles and scripts needed to reproduce the harness;
- localhost-bound Compose configuration;
- the synthetic fixture.

## Excluded

- `.env` and runtime credentials;
- raw agent conversations, prompts captured by shells, and terminal transcripts;
- `.results`, `.runs`, quarantine copies, and exported evidence archives;
- container inspection documents, Docker state, process lists, and service logs;
- hostnames, container addresses, private or ephemeral URLs, and local absolute paths;
- server import bundles and provider-specific infrastructure artifacts;
- second-stage platform architecture and roadmap documents;
- macOS metadata and build outputs.

The reduced result table omits free-form notes because they can carry paths, operator details, infrastructure identifiers, and copied conversation content. It retains the fields needed to check the public claims.

## Runtime warning

The OpenHands service mounts the Docker socket. Binding its web port to localhost limits network exposure but does not make the container a strong security boundary. Run the benchmark on a disposable host with no unrelated credentials or workloads.
