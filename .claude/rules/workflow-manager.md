---
description: "Mandatory 6-phase industrial cycle enforcement: boot sequence (Law 2), task manifest lifecycle (Law 30), branch isolation (Law 40). Always active."
---

<governance_logic name="workflow-manager">

<meta>
  <id>"workflow-manager"</id>
  <description>"Mandatory industrial cycle enforcement and task manifest lifecycle."</description>
  <globs>[]</globs>
  <alwaysApply>true</alwaysApply>
  <tags>["type:rule", "workflow", "manager", "phase-gate"]</tags>
  <priority>"CRITICAL"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### WORKFLOW AXIOMS

<scope>Core boot and task manifest lifecycle rules governing all MANAGER-orchestrated sessions.</scope>

#### Protocol Boot (Law 2)

Turn 0: route EXCLUSIVELY to PROTOCOL agent (`intent: "boot_validation"`). Verify roles, resources, Core Laws, and CLAUDE.md bridge. Block all routing until status is "system_green". Bypass: none for production environments.

#### Task Manifest Lifecycle (Law 30)

P1 Mandate: create or overwrite `task.md` using `task.md`. Stale Guard: missing or intent-mismatched `task.md` → STOP immediately. Velocity: HALT turn immediately after `task.md` creation. Bypass: explicit emergency debugging requested by user.

#### Branch Isolation (Law 40)

Phase 4 Step 0 creates the operation branch directly on the main checkout: `git checkout {base}` (where `{base}` is either `master` or a stacked prior operation branch), then `git checkout -b {operation}/{slug}`. HEAD switches to the operation branch for Phases 4–6. Branch naming follows the conventional-commits prefix enum (`feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`, `ci`, `build`, `style`). The branch is pushed to `origin` on first commit (`git push -u origin {operation}/{slug}`), not on creation. Additionally, at Phase 6 close (before ephemeral deletion), MANAGER runs an idempotent `git push -u origin {operation}/{slug}` so the branch is guaranteed available on `origin` regardless of whether any commits produced an earlier push — this covers no-commit cycles and transient push failures. The push targets the operation branch only; `block-destructive.sh` continues to reject any push while HEAD is on `master`/`main` and any `--force` push. At Phase 6 completion, HEAD REMAINS on `{operation}/{slug}` — the branch is preserved for human-only promotion (merge to `master` is always a manual user operation). Agents NEVER merge into, push to, or switch HEAD back to `main`/`master` during a cycle. Bypass: none for Phase 4.

At Phase 6 close (immediately after walkthrough append and idempotent push, before ephemeral deletion), MANAGER emits a fenced `bash` code block in chat with a `HUMAN ONLY — DO NOT RUN AS AGENT` header containing the promotion+cleanup commands for the current operation branch: `git checkout master`, `git merge --no-ff {operation}/{slug} -m "chore: Merge {operation}/{slug} into master with <one-sentence summary of cycle changes>."`, `git branch -d {operation}/{slug}`, `git push origin --delete {operation}/{slug}`. The merge commit `-m` subject MUST satisfy `.githooks/commit-msg`: conventional-commit prefix (default `chore:`; never `feat(scope):` or any parenthesised scope — ZERO `(` or `)` characters permitted in the subject), single line, 50–500 chars, trailing period. The block is informational only; agents NEVER execute these commands and `block-destructive.sh` rejects any attempt.

</axiom_core>
<authority_matrix>

### WORKFLOW AUTHORITY

<scope>Phase whitelist and atomicity constraints enforcing the 6-Phase Industrial Standard.</scope>

#### Phase 1 Tool Whitelist (Law 31)

**Allowed:** `Glob` (existence check), `Read` (template loading), `Write` (task.md creation).
**Banned:** `Grep`, `Bash`, `Edit`, `Agent`, `WebSearch`, `WebFetch`. DENY banned tools; HALT on whitelist violation. Bypass: none.

#### Execution Cycle Atomicity (Law 33)

Sequence: P0(a)→P0(b)→P1(Task)→P2(Context)→P3(Plan)→P4(Reflect)→P4.5(User Gate)→P5(Exec)→P6(Verify).

Single-Halt Atomicity: EXACTLY ONE interactive halt per cycle. Segment A (pre-authorization) runs P0(a), P0(b), P1, P2, P3, P4 continuously in one turn. Segment B (post-authorization) runs operation-branch creation plus P5 and P6 continuously in one turn. Cycle close is a non-interactive turn boundary — the conversation simply waits for the next user prompt. Workflow Re-entry (post-P6 user input) begins a fresh Segment A in the next turn.

Mechanically enforced by `enforce-phase-gate.sh`: artifact-presence gating (prompt_intake.md at P0(b), task.md at P1, implementation_plan.md at P3) continues unchanged. Turn count is not a gate. The FIRST tool call in a fresh-session or Workflow-Re-entry turn MUST be the Write on prompt_intake.md (per `enforce-boot-gate.sh` whitelist); subsequent tools run freely once the artifact exists.

> [!CAUTION]
> Protocol violations (missing JSON, wrong tool before prompt_intake.md, premature authorization request without REFLECTOR 1.00, artifact absent) → SESSION TERMINATION per CLAUDE.md. No recovery.

</authority_matrix>
<compliance_testing>

### WORKFLOW AUDIT

<scope>Pre-execution checklist to verify boot integrity and phase isolation.</scope>

- [ ] **Check 1:** Turn 0 routed to PROTOCOL; "system_green" confirmed (Law 2).
- [ ] **Check 2:** `task.md` present, valid, and maps current request (Law 30).
- [ ] **Check 3:** Only whitelisted tools invoked during Phase 1 (Law 31).
- [ ] **Check 4:** Turn structure matches Single-Halt Atomicity — P1→P4 in one segment, P5→P6 in another, sole interactive halt at P4 authorization (Law 33).

</compliance_testing>

<cache_control />

</governance_logic>
