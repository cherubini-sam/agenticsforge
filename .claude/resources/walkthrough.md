---
description: "Strict template for the walkthrough.md artifact. MANAGER-owned. Append-only cycle log: one section per completed P1-P6 cycle recording the summary, the changes landed, the pushed ref, permissions-change audit entries, and verification results. The sole artifact that survives Phase 6 teardown."
owner: MANAGER
target_path: "walkthrough.md"
ephemeral: false
---

# Walkthrough

> [!CRITICAL]
> **NON-EPHEMERAL / APPEND-ONLY**: unlike `task.md`, `implementation_plan.md`, and
> `prompt_intake.md`, this artifact is NOT hard-deleted at Phase 6 close. It is the
> sole survivor in `.claude/artifacts/` and persists across cycles.
> **NEVER overwrite, truncate, or re-order a prior cycle's section.** Every cycle
> APPENDS a new `## Cycle N — {{Task Name}}` section below the last one. Rewriting
> history here destroys the only durable record the sandbox keeps.

> [!IMPORTANT]
> **Cycle numbering**: `N` is the previous highest cycle number plus one, read from
> the existing sections in this file. When this file does not yet exist, the first
> appended section is `## Cycle 1`.

---

## Cycle {{N}} — {{Task Name}}

### Summary

One short paragraph: what the cycle set out to do and what it actually delivered.
State any scope that was descoped or handed to the user, so the deviation is
auditable rather than silent.

### Changes Landed

One row per changed path. Paths are repo-relative.

| Path | Change Type | What changed |
| :--- | :---------- | :----------- |
| {{path}} | modify \| create \| delete \| rename | {{one-line description}} |

### Remote Publication

- **Operation branch**: `{{operation}}/{{slug}}`
- **Pushed ref**: `{{refs/heads/operation/slug}}` (or `NOT PUSHED — <reason>`)
- **Promotion**: PR-only via `gh pr create --base main`; merge is human-only and
  never performed by an agent.

### Permissions-Change Audit

Every change to the `permissions` block in `settings.json` is recorded here with its
rationale (Law 7 audit trail). Write `NONE` when the cycle changed no permission.

| Change | Rationale |
| :--- | :--- |
| {{added/removed key or path}} | {{why it was required}} |

### Verification Results

| Check | Result | Evidence |
| :--- | :--- | :--- |
| {{check name}} | PASS \| FAIL | {{observed output or exit code}} |

**Outstanding at cycle close**: anything left open, and who owns it. Write `NONE`
when the cycle closed clean.

---
