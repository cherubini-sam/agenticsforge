---
name: code-review
description: "Systematic code review for quality, security, and protocol compliance. Use when reviewing PRs, auditing diffs, validating code against quality gates, or performing OWASP security checks."
---

# Code Review

Systematic review methodology aligned with the VALIDATOR agent role.

## Review Checklist

### Security (OWASP Top 10)
- [ ] **Injection**: No SQL/command/LDAP injection — use parameterized queries, never string concat
- [ ] **Broken Auth**: Credentials not hardcoded, no weak session management
- [ ] **Sensitive Data**: Secrets masked (`******`), no PII in logs, no `.env` committed
- [ ] **XXE / SSRF**: External inputs validated before use in XML parsers or URL fetchers
- [ ] **Access Control**: Privilege checks present, no path traversal via user input
- [ ] **Security Misconfiguration**: No debug mode in prod, no default credentials
- [ ] **XSS**: User input escaped before rendering in HTML
- [ ] **Insecure Deserialization**: Untrusted data not deserialized without validation
- [ ] **Known Vulnerabilities**: Dependencies not pinned to CVE-affected versions
- [ ] **Logging**: Errors logged with context; no secrets in log output

### Code Quality
- [ ] No inline magic values — all thresholds in constants
- [ ] No nested loops for O(N²) cross-reference — use hash maps
- [ ] No `pass`, `TODO`, `...` markers in production code
- [ ] No silent exception swallows (`except: pass`)
- [ ] No `print()` for logging — use logging utility
- [ ] No commented-out code blocks
- [ ] Async I/O wrapped with timeout
- [ ] Type annotations on all function signatures

### Protocol Compliance
- [ ] Commit message matches `^(feat|fix|refactor|docs|chore|test|perf|ci|build|style): [A-Z].+\.$`
- [ ] No `--no-verify` bypass in git commands
- [ ] Writes stay inside designated R/W zones (no writes to `.git/`, `/`)

## PR Diff Analysis Pattern

1. Read `git diff base...HEAD` — identify all changed files
2. Classify each change: new feature / bug fix / refactor / test / config
3. For each changed file: run security + quality checklists above
4. Check test coverage: every changed source module should have a corresponding test change
5. Verify no accidental inclusion of secrets, temp files, or build artifacts

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
