---
name: code-review
description: "Systematic code review for quality, security, and protocol compliance. Use when reviewing PRs, auditing diffs, validating code against quality gates, or performing OWASP security checks."
---

# Code Review

Systematic review methodology aligned with the VALIDATOR agent role.

## Foundations

- **Goal of review** — improve long-term codebase health, not enforce perfection. Approve a change that leaves the codebase strictly better, even if other improvements remain (Google Engineering Practices).
- **Optimise for latency, not throughput** — small, frequently-merged changes beat large late ones. Defect-detection effectiveness collapses past ~200–400 changed lines (Cohen; Bacchelli & Bird).
- **Reviews are a design conversation, not a bug net** — most review value is understanding, knowledge transfer, and design clarity; only a minority of comments concern defects (Bacchelli & Bird).
- **Author responsibility** — split into reviewable units, write a meaningful PR description, self-review the diff before requesting human review.

## Automated Gate

Manual review is one layer. Stack automated checks ahead of human eyes:

- **Supply chain** — SBOM (CycloneDX or SPDX) on every build; sign artefacts with Sigstore/cosign; SLSA provenance ≥ 2. Watch for dependency-confusion (typo-squat, internal-name leak).
- **Secret scanning** — `gitleaks` / `trufflehog` pre-commit AND CI; a hit blocks merge until the secret is rotated AND scrubbed from history.
- **SAST + DAST** — Semgrep or CodeQL on diff in PR CI; DAST against staging deploy. Findings ≥ MEDIUM block merge.
- **Dependency policy** — pin versions; scan with OSV-Scanner / Snyk / Dependabot; fail on known CVEs.
- **OWASP LLM Top 10 (2025)** — for LLM-calling code: prompt injection, insecure output handling, model DoS, supply-chain, excessive agency, sensitive-info disclosure.

## Review Checklist

### Security (OWASP Top 10)
- [ ] **Injection**: parameterized queries only — never string concat
- [ ] **Broken Auth**: no hardcoded credentials, no weak session management
- [ ] **Sensitive Data**: secrets masked (`******`), no PII in logs, no `.env` committed
- [ ] **XXE / SSRF**: external inputs validated before XML parsers or URL fetchers
- [ ] **Access Control**: privilege checks present, no path traversal via user input
- [ ] **Security Misconfiguration**: no debug mode in prod, no default credentials
- [ ] **XSS**: user input escaped before HTML rendering
- [ ] **Insecure Deserialization**: untrusted data validated before deserialization
- [ ] **Known Vulnerabilities**: dependencies not pinned to CVE-affected versions
- [ ] **Logging**: errors logged with context; no secrets in log output

### Code Quality
- [ ] No inline magic values — all thresholds in constants
- [ ] No nested loops for O(N²) cross-reference — use hash maps
- [ ] No `pass`, `TODO`, `...` markers in production code
- [ ] No silent exception swallows
- [ ] No raw stdout logging — use the project's logging utility
- [ ] No commented-out code blocks
- [ ] Async I/O wrapped with timeout
- [ ] Type annotations on all function signatures

### Protocol Compliance
- [ ] Commit message matches `^(feat|fix|refactor|docs|chore|test|perf|ci|build|style): [A-Z].+\.$`
- [ ] No `--no-verify` bypass in git commands
- [ ] Writes stay inside designated R/W zones (no writes to `.git/`, `/`)

## PR Diff Analysis

1. `git diff base...HEAD` — identify all changed files
2. Classify each change: new feature / bug fix / refactor / test / config
3. For each changed file: run security + quality checklists above
4. Confirm every changed source module has a corresponding test change
5. Verify no secrets, temp files, or build artifacts included

## Severity Levels

| Level | Action |
|-------|--------|
| CRITICAL | Block merge — security vulnerability or data loss risk |
| HIGH | Block merge — correctness bug or protocol violation |
| MEDIUM | Require fix before merge — quality or maintainability |
| LOW | Suggest fix — style, naming, missing test |

## Output Format

```
## Code Review: <branch-name>

### Summary
[1-2 sentence overall assessment]

### CRITICAL (block merge)
- [file:line] [description]

### HIGH (block merge)
- [file:line] [description]

### MEDIUM (fix before merge)
- [file:line] [description]

### LOW (suggestions)
- [file:line] [description]

### Verdict: APPROVE | REQUEST CHANGES | BLOCK
```

## Source

Google, Engineering Practices — Code Review Developer Guide, 2020; OWASP Top 10 for LLM Applications, 2025.
