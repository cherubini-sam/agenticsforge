<protocol_framework name="cicd">

<meta>
  <id>"cicd"</id>
  <description>"Headless mode integration, CI/CD pipeline patterns, and automated agent execution for Claude Code."</description>
  <globs>[]</globs>
  <alwaysApply>false</alwaysApply>
  <tags>["type:protocol", "cicd", "headless", "automation"]</tags>
  <priority>"LOW"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### CI/CD INTEGRATION PROTOCOL

<scope>Defines patterns for running Claude Code in non-interactive (headless) mode within CI/CD pipelines, automated review flows, and scheduled tasks.</scope>

#### 1. Headless Mode

Claude Code supports non-interactive execution via `claude -p` (print mode). In headless mode:
- No interactive terminal session.
- Input provided as a single prompt string or piped from stdin.
- Output returned as text to stdout.
- No user confirmation prompts — all tool calls must be pre-authorized or use `--allowedTools`.

**Trigger:** Automated pipeline event (PR creation, commit push, scheduled cron, webhook).
**Success:** Headless agent completes task and outputs structured result.
**Failure:** Agent requires interactive confirmation → hangs or times out.
**Fallback:** Fail the pipeline step with a structured error message.

#### 2. CI/CD Pipeline Patterns

##### 2.1 Automated Code Review (On PR Creation)

```yaml
# Trigger: Pull request opened or updated
# Agent: Security Reviewer (Tier 3 — Haiku for speed)
# Scope: Review only the git diff, not the entire codebase
# Output: Structured review comment posted to PR
```

**Workflow:**
1. CI extracts `git diff` for the PR.
2. Claude Code headless agent receives diff + review instructions.
3. Agent scans for: security vulnerabilities, code quality issues, style violations.
4. Agent outputs structured review as GitHub PR comment via `gh` CLI.

##### 2.2 Automated Documentation Sync (On Merge to Main)

```yaml
# Trigger: Merge to main branch
# Agent: LIBRARIAN (Tier 3 — Haiku)
# Scope: Detect changed source files, update corresponding docs
# Output: Documentation PR or direct commit to docs branch
```

##### 2.3 Nightly Security Scan (Scheduled Cron)

```yaml
# Trigger: Nightly cron (e.g., 02:00 UTC)
# Agent: VALIDATOR (Tier 3 — Sonnet)
# Scope: Full dependency audit, SAST scan, secrets detection
# Output: Report to `.claude/artifacts/security_report.md` + Slack notification
```

#### 3. Headless Agent Configuration

| Parameter | Purpose | Required |
| :--- | :--- | :--- |
| `--print` / `-p` | Non-interactive mode | Yes |
| `--allowedTools` | Pre-authorize specific tools | Yes (no confirmation prompts in CI) |
| `--model` | Select model tier | Recommended |
| `--max-turns` | Limit execution turns | Recommended (prevent runaway) |
| `--output-format` | Structured output (json, text) | Optional |

#### 4. Safety Constraints for Headless Execution

- **No destructive operations** without explicit pipeline configuration (no `rm -rf`, no force push).
- **Scoped file access** — headless agents MUST operate within the repo checkout directory only.
- **Timeout enforcement** — all headless runs MUST have a maximum execution time (default: 10 minutes).
- **Artifact output** — headless agents write results to `.claude/artifacts/` or stdout. No other write locations.
- **Exit codes** — 0: success, 1: error, 2: validation failure (matches `references.md` contract).

#### 5. Process Lifecycle

- **Dangling process prevention:** CI pipeline MUST clean up Claude Code processes on timeout or cancellation.
- **Idempotency:** Headless runs MUST be safe to retry (Law 15).
- **State isolation:** Each headless run starts with a fresh context. No session carryover.

</axiom_core>
<authority_matrix>

### CI/CD AUTHORITY

<scope>Defines who configures and approves headless agent pipelines.</scope>

#### 6. Authority

- **Pipeline configuration** requires USER (repository admin) approval.
- **Tool allowlists** for headless agents MUST be explicitly defined in CI config — no blanket `--allowedTools "*"`.
- **Production deployments** via headless agents are BLOCKED without explicit `FORCE_DEPLOY=true` environment variable.

</authority_matrix>
<compliance_testing>

### CI/CD AUDIT

<scope>Verification checks for headless execution safety.</scope>

- [ ] **Check 1:** Headless agent has explicit `--allowedTools` (no wildcard).
- [ ] **Check 2:** Maximum execution time configured.
- [ ] **Check 3:** No destructive operations in tool allowlist unless explicitly approved.
- [ ] **Check 4:** Exit codes match contract (0/1/2).

</compliance_testing>

<cache_control />

</protocol_framework>
