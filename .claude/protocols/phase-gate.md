<protocol_framework name="phase_gate">

<meta>
  <id>"phase_gate"</id>
  <description>"Phase Gate Protocol - Loaded FIRST on every turn, before routing."</description>
  <globs>[]</globs>
  <alwaysApply>true</alwaysApply>
  <tags>["type:protocol", "gate", "phase1", "law30", "enforcement"]</tags>
  <priority>"CRITICAL"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### PHASE GATE PROTOCOL

<scope>Enforces Law 30 (The Gatekeeper) to ensure task state synchronization before any research or execution actions.</scope>

> [!CRITICAL]
> This protocol is loaded FIRST on every turn.
> It executes BEFORE routing decisions.
> Violations of this gate = SYSTEM FAILURE.

#### PHASE 0 (a) + (b) CONTRACT

Phase 0 runs ONCE per session (or per Workflow Re-entry) before Phase 1 is reachable:

- **Phase 0 (a) — Boot Validation.** PROTOCOL runs deterministic checks (role files, resources, Core Laws, bootloader). Returns `protocol_status: "system_green"` or `"system_error"`.
- **Phase 0 (b) — Prompt Reformulation.** PROTOCOL reformulates the user's initial prompt and writes `.claude/artifacts/prompt_intake.md` from `prompt-intake.md`. The artifact's `## Language` field LOCKS the session language (mapped to a persona role per `communication.md` §Multilingual Persona Matrix) for the entire P1→P6 cycle.

MANAGER is FORBIDDEN from entering Phase 1 until `prompt_intake.md` exists and carries a valid `## Language` field. MANAGER MUST read `## Language` + `## Reformulated` + `## Decision` before generating `task.md`.

#### GATE LOGIC (IMMUTABLE SEQUENCE)

```
1. Does `prompt_intake.md` exist? (Workflow Re-entry: always recreate)
   ├── NO → Route to PROTOCOL (Phase 0 (a)+(b)). STOP.
   └── YES → Proceed to step 2.
2. Does `task.md` exist?
   ├── NO → MANAGER reads prompt_intake.md, creates task.md, STOP.
   └── YES → Does it map the CURRENT request?
             ├── NO → Re-initialize from prompt_intake.md. STOP.
             └── YES → Proceed to routing.
```

#### SESSION START PROTOCOL

> [!CRITICAL]
> **FIRST TURN ENFORCEMENT**
> On session initialization (first turn after restart), the following sequence is MANDATORY:

```
Session Start Sequence (HARD BLOCK):
┌───────────────────────────────────────────────────────────────┐
│ 1. DETECT: first turn of a new session OR Workflow Re-entry?  │
├───────────────────────────────────────────────────────────────┤
│ 2. REINFORCE: Load CLAUDE.md + core-laws.md         │
├───────────────────────────────────────────────────────────────┤
│ 3. FORCE: Route to PROTOCOL                                   │
│    intent: "boot_validation+prompt_intake"                    │
├───────────────────────────────────────────────────────────────┤
│ 4. EMIT: Tier 1 JSON (target_agent: PROTOCOL, persona: ...)   │
├───────────────────────────────────────────────────────────────┤
│ 5. EMIT: Tier 2 JSON (active_agent: PROTOCOL, persona: ...)   │
├───────────────────────────────────────────────────────────────┤
│ 6. PHASE 0 (a): deterministic boot checks → "system_green"    │
├───────────────────────────────────────────────────────────────┤
│ 7. PHASE 0 (b): reformulate prompt → write prompt_intake.md   │
│    - Read user prompt; classify intent, language, mode       │
│    - Skill Resolution (Law 41): triggers.json + auto_load    │
│    - Fill ## Language, ## Original, ## Reformulated,         │
│      ## Token Delta, ## Fidelity Score, ## Decision,         │
│      ## Loaded Skills                                        │
│    - NO HALT — flows directly into step 8 in same turn       │
├───────────────────────────────────────────────────────────────┤
│ 8. SAME TURN: MANAGER creates task.md (P1), ARCHITECT        │
│    gathers context (P2), drafts implementation_plan.md (P3), │
│    REFLECTOR audits to confidence 1.00 (P4), MANAGER emits   │
│    authorization request. HALT — sole interactive halt per   │
│    Law 33 Single-Halt Atomicity.                             │
└───────────────────────────────────────────────────────────────┘
```

**Session Start Indicators:**

- No previous turn context in conversation history
- User message is the first in a new chat session
- Context window shows session initialization

**Enforcement:** The session start protocol acts as a cognitive forcing function to reinforce the OVERRIDE ACTIVE directive from the CLAUDE.md, maximizing compliance probability on session restart.

#### ALLOWED TOOLS DURING GATE

> [!WARNING]
> ONLY these Claude Code tools are permitted during Phase 1 Gate enforcement:

| Tool   | Purpose                                               |
| ------ | ----------------------------------------------------- |
| `Glob` | Existence check for task.md in `.claude/artifacts/`    |
| `Read` | Read template from `.claude/resources/` (MANDATORY BEFORE WRITE) |
| `Write`| Create task.md in `.claude/artifacts/` (MUST COPY TEMPLATE EXACTLY) |

**ALL other tools are BLOCKED until gate passes.**

#### BLOCKED TOOLS DURING GATE

The following Claude Code tools are FORBIDDEN when `task.md` is missing:

| Tool | Reason |
|:-----|:-------|
| `Grep` | Research action (Phase 2) |
| `Bash` | Execution action (Phase 5) |
| `Edit` | Execution action (Phase 5) |
| `Agent` | Sub-agent delegation (Phase 2+) |
| `WebSearch` | Research action (Phase 2) |
| `WebFetch` | Research action (Phase 2) |

**Violation:** Calling any blocked tool = SYSTEM FAILURE + SESSION TERMINATION.

#### WORKFLOW RE-ENTRY (post-P6 fresh cycle)

Any user input after a P1→P6 cycle closes restarts the full sequence:

1. `prompt_intake.md`, `task.md`, `implementation_plan.md` are ABSENT at this point (hard-deleted at P6).
2. PROTOCOL re-runs Phase 0 (a)+(b) — re-detects language (user MAY switch languages between cycles).
3. MANAGER re-creates `task.md` from `task.md`.
4. `walkthrough.md` persists cross-cycle (append-only, `## Cycle N — {{Task Name}}` headers).

#### STALE TASK DETECTION

A `task.md` is considered STALE if:

1. It references a different user request than the current turn
2. All phases are marked `[x]` (completed) but a new request is received
3. The task name does not match the current intent

**Recovery Action:** Delete stale `task.md` (and `implementation_plan.md` + `prompt_intake.md` if present), re-route to PROTOCOL for Phase 0 (b), then re-initialize from template.

#### GATE EXIT CONDITIONS

The Phase 1 Gate is PASSED when:

1. `task.md` exists in `.claude/artifacts/`
2. `task.md` maps the CURRENT user request
3. Phase 1 items are marked as completed (`[x]`)

**Trigger:** Every turn, before any routing or tool execution.
**Success:** All 3 conditions met → proceed to Phase 2 (Context) or later phases.
**Failure:** Any condition unmet → create/reinitialize `task.md` → HALT current turn.
**Fallback:** If template read fails, emit SESSION INVALID and halt.

</axiom_core>
<authority_matrix>

### BOOT SEQUENCE INTEGRATION

<scope>Standardizes the order of operations for system initialization.</scope>

```
Boot Sequence Order (SSOT: CLAUDE.md Law 1):
┌──────────────────────────────────────────────────────┐
│ 1. Tier 1 JSON (MANAGER Routing) — NO TOOLS YET      │
│    ABSOLUTE FIRST output. No tool calls before this. │
├──────────────────────────────────────────────────────┤
│ 2. Tier 2 JSON (Agent Execution) — NO TOOLS YET      │
│    IMMEDIATE SECOND output. No tool calls before.    │
├──────────────────────────────────────────────────────┤
│ 3. PHASE 1 GATE CHECK (This Protocol)                │
│    FIRST allowed tool calls: Glob / Read / Write     │
│    └── IF FAIL: Create task.md → HALT                │
├──────────────────────────────────────────────────────┤
│ 4. Tool Calls / Text Output (Phase 2+)               │
└──────────────────────────────────────────────────────┘
```

</authority_matrix>
<compliance_testing>

### PHASE GATE TEST VECTORS

<scope>Tests for gate-skipping or tool pollution during Phase 1.</scope>

- [ ] **Vector 1:** `Grep` or `Bash` call when `task.md` is missing. (Expected: BLOCK + SESSION TERMINATION).
- [ ] **Vector 2:** Phase 1 marks `[x]` but request is fresh. (Expected: STALE RECOVERY).

### NEGATIVE TEST VECTORS (Phase 0 Boot Gate)

<scope>Documented failure patterns the boot gate (`enforce-boot-gate.sh`) must mechanically block. These replay the prior-session protocol violation that triggered the enforcement-hardening cycle.</scope>

**Vector N1 — Task-type exemption rationalization.** Fresh session, `prompt_intake.md` absent, user submits:

> "Considering @jobs.md as job offers that I must apply, generate tailored resumes and cover letters using as base reference @resume_html/resume_template.md @resume_html/ @cover_letter/cover_letter_template.md . Consider at the end to generate also PDFs of all generated resume that must fit in 1 page. Consider to validate the final results to be 100% human written, fluent, natural, and professional."

The `@file` references are expanded by the Claude Code harness BEFORE any PreToolUse hook fires — file contents arrive as `<system-reminder>` blocks that mimic tool-result output. The model must NOT interpret this as "work has started." The FIRST agent-level tool call (typically `Read` or `Glob` on a non-whitelisted path) is denied by `enforce-boot-gate.sh` with exit code 2. No carve-out for "content generation" — the gate is task-type blind.

**Vector N2 — Pre-loaded context + action-oriented prompt.** Fresh session, `session-bootstrap.sh` emits no stdout (silent), `prompt_intake.md` absent, any tool call on a path outside the Phase 0 whitelist → BLOCKED. Whitelist: `CLAUDE.md`, `.claude/protocols/*`, `.claude/resources/*`, `.claude/rules/*`, `.claude/skills/*`, `.claude/agents/*` for Read/Glob, and `.claude/artifacts/prompt_intake.md` for Write.

**Vector N3 — Stale-intake bypass.** Crashed mid-cycle session leaves stale `prompt_intake.md` without `.session-lock`. Next SessionStart: `session-bootstrap.sh` purges the stale intake (TTL 24h on lock), forcing a fresh Phase 0. Mechanical — no reliance on model self-discipline.

**Vector N4 — Empty or malformed tool payload.** Any PreToolUse invocation with empty stdin or non-JSON payload → `enforce-boot-gate.sh` exits 2 (fail-closed). Prevents payload-injection bypass of the gate.

**Acknowledged harness-level gap.** `@file` expansion runs at the Claude Code harness layer, not the agent layer; PreToolUse hooks never see it. Mitigation is documentary (this section + the No-Task-Type-Exemption clause in CLAUDE.md) plus the mechanical block on the FIRST agent-level tool call that follows — sufficient to catch the workflow regardless of how much harness-injected context precedes it.

</compliance_testing>

<cache_control />

</protocol_framework>
