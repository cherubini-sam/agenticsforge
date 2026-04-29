---
description: "Standard Atomic Task Schema for 6-Phase Industrial Workflow (MANAGER)"
owner: MANAGER
target_path: "task.md"
ephemeral: true
---

# Task: {{Task Name}}

> [!CRITICAL]
> **SYSTEM INTEGRITY ALERT (LAW-30)**: Adherence to this schema is **NON-NEGOTIABLE**.
> Any deviation from the defined Input/Output chain constitutes a **SYSTEM FAILURE**.
> Strict structural compliance is required to maintain audit trail integrity.

> [!CRITICAL]
> **SINGLETON STATE DIRECTIVE**:
>
> 1. **EPHEMERAL**: This file is **PERMANENTLY ERASED** on new task initiation.
> 2. **ATOMIC**: Mark `[x]` and **SAVE** immediately after every step.
> 3. **TRUTH**: Do not rely on context window. If not saved here, **it did not happen**.
> 4. **TERMINAL**: `task.md`, `implementation_plan.md`, and `prompt_intake.md` are HARD-DELETED at the close of Phase 6. No archive, no rename, no move. Only `walkthrough.md` persists (append-only).
> 5. **REUSABLE**: Any post-Phase-6 user input triggers a fresh instantiation from this template. The `task.md` slot is single-occupancy — never two tasks alive at once.

> [!CRITICAL]
> **VERBATIM REPRODUCTION DIRECTIVE**: This template MUST be copied byte-for-byte to `.claude/artifacts/task.md`. Only `{{Task Name}}` and `[ISO-8601]` are substituted. Removing sections, renaming sections, paraphrasing CRITICAL callouts, or substituting an alternate manifest shape (free-form `## Context` + `T-###` list, etc.) is a LAW-30 violation. Use `bash .claude/hooks/stamp-task.sh "<title>"` to instantiate. Hand-authored manifests are rejected at write time by `.claude/hooks/validate-task-schema.sh` (PostToolUse).

## HALT POLICY

This cycle produces EXACTLY ONE interactive halt — the Phase 4 authorization request. Everything before the halt (boot validation, prompt intake, task manifest, context retrieval, implementation plan, REFLECTOR audit) runs in one continuous turn-segment. Everything after the halt (operation-branch creation, ENGINEER execution, VALIDATOR verification, walkthrough append, ephemeral deletion) runs in another continuous turn-segment.

Turn boundaries per cycle:

1. **Segment A (pre-authorization)** — one turn. Runs P0(a) + P0(b) + P1 + P2 + P3 + P4. Ends with MANAGER emitting the authorization request. User sees a REFLECTOR-approved plan and responds `yes` / `no` / `amend`.
2. **Segment B (post-authorization)** — one turn. Runs branch creation + P5 + P6. Ends with cycle close (walkthrough appended, ephemerals deleted, HEAD on operation branch). The conversation then waits for the next user prompt to begin Workflow Re-entry.

Cycle close is NOT an interactive halt — it is a natural terminus. The next user input triggers a fresh Segment A for the new cycle.

## PRE-FLIGHT INITIALIZATION

- [ ] **[LAW-1] Format Priority**: Output stream initialized with JSON.
- [ ] **[LAW-30] Schema Validation**: `task.md` structure matches current version requirements.
- [ ] **[LAW-34] Re-Iteration**: State re-captured from Phase 0 (b) `prompt_intake.md`.
- [ ] **[SEC-01] Path Isolation**: Write access constrained strictly to artifact sandbox.

> [!CRITICAL]
> **MANDATORY STATE VERIFICATION**:
> Review PRE-FLIGHT INITIALIZATION checks.
>
> - **IF ANY** are empty (`[ ]`): You are **FORBIDDEN** from proceeding and review the state.
> - **IF ALL** are checked (`[x]`): You are **ALLOWED** to proceed to OPERATIONAL RISK ASSESSMENT.

## OPERATIONAL RISK ASSESSMENT

- **Security Classification**: [LOW|MEDIUM|HIGH]
- **Data Sensitivity**: [PUBLIC|INTERNAL|CONFIDENTIAL]
- **Resource Impact**: [NEGLIGIBLE|MODERATE|CRITICAL]

## MISSION OBJECTIVES

- **Primary Directive**: [Concise Goal Statement]
- **Strategic Context**: [Business or System justification]
- **Definition of Done (DoD)**: [Specific, measurable completion criteria]

## 6-PHASE INDUSTRIAL WORKFLOW

- [ ] Phase 1: Task Breakdown (Gap Analysis)
  - [ ] [MANAGER] Initialize Task Manifest (instantiate template from `.claude/resources/task.md`).
  - [ ] [MANAGER] Verify and confirm Phase 0 gate passed.
  - [ ] [MANAGER] `touch .claude/artifacts/.session-lock` — belt-and-suspenders; lock is normally created automatically by `.claude/hooks/create-session-lock.sh` (PostToolUse) the moment `prompt_intake.md` is written at P0(b), so this step is a no-op in healthy sessions.
  - [ ] [ARCHITECT] Define scope and confirm loaded skills from `prompt_intake.md §Loaded Skills` (Law 37).
  - **DoD**: Task manifest is initialized, granular, and scope is locked.

- [ ] Phase 2: Context Retrieval (Research)
  - [ ] [ARCHITECT] Analyze requirements and gather content.
  - [ ] [LIBRARIAN] Aggregate knowledge base assets and fetch files.
  - **DoD**: All required context is loaded into active memory.

- [ ] Phase 3: Planning (Architect Design)
  - [ ] [ARCHITECT] Draft Implementation Plan.
  - [ ] [ARCHITECT] Define verification steps and strategy.
  - **DoD**: Plan is fully documented, feasible, and verifiable.

- [ ] Phase 4: Critique (Reflector Audit)
  - [ ] [REFLECTOR] Conduct compliance audit and review Implementation Plan.
  - [ ] [ARCHITECT] Review Implementation Plan and remediate deficiencies.
  - [ ] [MANAGER] Request user authorization to proceed (output authorization request directly to user).
  - [ ] [MANAGER] `git checkout {base}` (where `{base}` is `master` or a stacked prior operation branch) then `git checkout -b {operation}/{slug}` — create operation branch on main checkout (Law 40). HEAD now tracks `{operation}/{slug}`.
  - **DoD**: Plan is validated by Reflector, authorized by User, and operation branch is active on the main checkout.

- [ ] Phase 5: Execution (Engineer Build)
  - [ ] [ENGINEER] Execute implementation.
  - [ ] [PROTOCOL] Enforce Security Standards.
  - [ ] [LIBRARIAN] Synchronize Documentation.
  - **DoD**: Code is implemented, audited, and documented.

- [ ] Phase 6: System verification (Validator Test)
  - [ ] [VALIDATOR] Execute validation and test suite.
  - [ ] [MANAGER] `git push -u origin {operation}/{slug}` — idempotent publish of operation branch to origin (Law 40). Guarded by `block-destructive.sh` which rejects push on master/main and any `--force` push. No-op if already published and up-to-date.
  - [ ] [MANAGER] **Append** to `walkthrough.md` with header `## Cycle N — {{Task Name}}` (multi-cycle session support; never overwrite prior cycles). Record the push ref under a "Remote Publication" bullet.
  - [ ] [MANAGER] Emit HUMAN-ONLY merge+cleanup command block in chat for `{operation}/{slug}` — fenced `bash`, `HUMAN ONLY — DO NOT RUN AS AGENT` header, commands: `git checkout master`, `git merge --no-ff {operation}/{slug} -m "chore: Merge {operation}/{slug} into master with <one-sentence summary>."`, `git branch -d {operation}/{slug}`, `git push origin --delete {operation}/{slug}`. Merge subject MUST contain ZERO parentheses, 50–500 chars, trailing period, no Claude/Anthropic attribution (Law 40 + `.githooks/commit-msg` compliance).
  - [ ] [MANAGER] `rm -f .claude/artifacts/.session-lock` — release cycle lock so the next session's SessionStart purge resumes.
  - [ ] [MANAGER] **HARD DELETE** `.claude/artifacts/task.md`, `.claude/artifacts/implementation_plan.md`, and `.claude/artifacts/prompt_intake.md` (TERMINAL STATE per Singleton Directive clause 4).
  - [ ] [MANAGER] Do NOT switch HEAD. Operation branch `{operation}/{slug}` is preserved on main checkout for human-only merge (Law 40).
  - [ ] [MANAGER] Verify sandbox clean: `ls .claude/artifacts/` contains only `walkthrough.md` + any local-only reports.
  - **DoD**: System passes all validations, walkthrough.md updated, task.md + implementation_plan.md + prompt_intake.md deleted, HEAD preserved on `{operation}/{slug}`, sandbox verified clean.

## SKILL OVERRIDES

> Skills are auto-loaded by MANAGER every turn from `.claude/skills/triggers.json` per Law 37.
> Use this block ONLY to override automatic resolution.

```yaml
force_load: []    # skills to add regardless of trigger match
force_skip: []    # skills to exclude even if triggers match
```

Leave both lists empty for default auto-resolution.

## AUDIT TRAIL

- **Timestamp Created**: [ISO-8601]
