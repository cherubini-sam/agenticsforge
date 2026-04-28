---
description: "Security redlines, context boundaries, filesystem firewall (Law 5), and phase isolation (Law 33). Always active."
---

### SECURITY AXIOMS

> Core security constraints and context limits governing all agent operations.

#### Security Redlines

REDACT all secrets: keys, passwords, and sensitive identifiers MUST be masked (`******`). Zero External Access: NO network access without explicit user permission (Law 7). Destruction Guard: structural commands (`rm`, `delete`, `drop`) REQUIRE Dry Run verification before execution. BLOCK unauthorized access; DENY destructive commands without Dry Run.

#### Network Access Authorization Record

The "explicit user permission" required by Law 7 is configured via the `permissions` block in `~/.claude/settings.json`. The `additionalDirectories` key grants the agent access to paths outside the active working directory.

Authorization scope:

- PreToolUse hooks (`enforce-boot-gate.sh`, `enforce-phase-gate.sh`, `block-destructive.sh`) remain the authoritative safety layer regardless of any permission configuration. Permission settings gate Claude Code's interactive prompts only, not hook exit-2 rejections.
- Any change to the permissions block MUST be logged in `.claude/artifacts/walkthrough.md` with the cycle number and rationale (Law 7 audit trail).

Portable deployment form (safe to replicate across production machines):

```json
{
  "permissions": {
    "additionalDirectories": ["${HOME}/.claude"]
  }
}
```

`${HOME}` is substituted by Claude Code at load time. Never hardcode absolute user paths — they break on every other machine. Per-project artifact sandboxes do not need to appear in `additionalDirectories`; Claude Code grants the active working directory automatically.

#### Context Boundaries

Per-role file limits are the authority (defined in each role's `memory_access` section). Phase 2 initialization is exempt from role caps when loading protocol/role/config files (10-20 system files are legitimate). Cap resumes at Phase 3. Bypass: manual user override for batch operations.

### BOUNDARY AUTHORITY

> Filesystem zones and phase transition rules enforcing Law 5 and Law 33.

#### Filesystem Firewall (Law 5)

| Zone | Path | Access |
| :--- | :--- | :--- |
| Artifact Sandbox | `.claude/artifacts/` (task.md, implementation_plan.md, reports, walkthroughs) | R/W |
| Workspace | `./` (source code, configs, tests) | R/W |
| Agent Config | `.claude/protocols/`, `.claude/agents/`, `.claude/rules/` | READ ONLY |
| User Global Config | `~/.claude/` (settings.json, CLAUDE.md, rules, hooks, skills) | AUTHORIZED (see §Network Access Authorization Record) |
| Forbidden | `/`, `.git/` | BLOCK |

BLOCK tool execution in forbidden zones; REJECT writes outside designated R/W paths. Writes under `~/.claude/` require a task.md line item and are logged in `walkthrough.md` — the global permissions block authorizes the tool layer, not the decision to edit.

#### Phase Firewall (Law 33)

Legal turn-segments under Single-Halt Atomicity: (a) Segment A = P0(a)+P0(b)+P1+P2+P3+P4 together (pre-authorization), (b) Segment B = P5+P6 together (post-authorization). Illegal: any segment straddling the P4 authorization gate (Segment A continuing into P5 without user `yes`). Safety: if terminal output is `[OUTPUT NOT AVAILABLE]`, mandatory fetch (Loop 2) required before acting. No bypass — phase-gate enforcement is the SSOT in `workflow-manager.md`, mechanically enforced by `enforce-phase-gate.sh`.

### BOUNDARY AUDIT

> Pre-action checklist to verify security and isolation constraints.

- [ ] **Check 1:** No secrets exposed in any output stream (Law 6).
- [ ] **Check 2:** Active file count ≤ 5 (Phase 2 exemption applied if applicable).
- [ ] **Check 3:** All writes target authorized zones only (Law 5).
- [ ] **Check 4:** No illegal phase combinations in current turn (Law 33).
