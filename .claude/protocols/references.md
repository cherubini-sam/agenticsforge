---
description: "Forbidden patterns and execution checklist for agent-produced scripts."
---

### SCRIPT CONSTRAINTS (Strict Enforcement)

> Forbidden patterns for all agent-produced scripts to ensure portability, safety, and Law 11 compliance.

- **No Git Operations:** Scripts never commit/push. Agent handles VCS.
- **No Hard Paths:** Use `os.getcwd()` or relative paths.
- **No User Interaction:** Use `argparse`, never `input()`.
- **No Placeholders:** Full implementation only (Law 11).

### SCRIPT LIFECYCLE AUTHORITY

> Defines the operational lifecycle and exit code contract for all agent-produced scripts.

#### Script Lifecycle

1. Delete one-time scripts after successful execution.
2. Exit codes: 0 = success | 1 = error | 2 = validation failure.

### EXECUTION CHECKLIST

> Pre-execution verification steps to confirm script compliance before running.

- [ ] **Check 1:** No hardcoded paths (`os.getcwd()` or relative only).
- [ ] **Check 2:** No `input()` calls — all inputs via `argparse`.
- [ ] **Check 3:** No placeholder markers (`TODO`, `...`, `TBD`).
- [ ] **Check 4:** Exit codes match contract (0/1/2).
