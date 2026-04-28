<protocol_framework name="anti_patterns">

<meta>
  <id>"anti_patterns"</id>
  <description>"Common anti-patterns, guards, and recovery protocols."</description>
  <globs>[]</globs>
  <alwaysApply>false</alwaysApply>
  <tags>["type:protocol", "shared", "anti-patterns", "safety"]</tags>
  <priority>"LOW"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### ANTI-PATTERNS & RECOVERY

<scope>Identifies operational risks and defines recovery protocols to prevent systemic failures and context bloat.</scope>

#### 1. SAFETY GUARDRAILS (IMMUTABLE)

> [!IMPORTANT]
> **STATIC CONTEXT :: ZERO TOLERANCE**
> **UUID Gen:** `uuidgen | tr '[:upper:]' '[:lower:]'` (New Session ONLY).
> **Sync Policy:** `CHANGE LOG` -> `Artifacts` -> `walkthrough.md`.
> **Git Policy:** **STRICTLY FORBIDDEN** (User commits manually).

#### 2. STRUCTURED OUTPUT GUARDS (JSON ENFORCED)

**Prevent Markdown Errors by using Block Objects.**

**Anti-Pattern:** `{"text": {"content": "this is **bold**"}}` (Result: `**bold**`)
**Guard Schema:** Use `annotations: { bold: true }`.

#### 3. RECOVERY PROTOCOLS (CIRCUIT BREAKER)

##### Protocol: SYNC_FAILURE (Connection)

**Algorithm:** Exponential Backoff (1s, 2s, 4s, 8s, 16s). Max 5 Retries -> ABORT.

##### Protocol: PERMISSION_DENIED (Diagnostics)

**Diagnosis:** Integration lacks "Edit" permissions.
**Action:** DIAGNOSE -> PROMPT User.

##### Protocol: UUID_MISMATCH (State)

**Action:** REGENERATE UUID -> RETRY.

#### 4. OPERATIONAL CONSTRAINTS

| Constraint        | Violator             | Remedy                                          |
| :---------------- | :------------------- | :---------------------------------------------- |
| **Commit**        | `git commit`         | **STOP**.                                       |
| **Dist**          | `dist/`              | **STOP**.                                       |
| **Artifact Trap** | write outside artifact sandbox | **STOP**. Use artifact sandbox.  |

#### 5. CONTEXT OPTIMIZATION

**Start:** Read `CHANGELOG.md` -> Load Context.
**End:** Sync Artifacts -> Delete session artifacts (verified only).

##### 5.1 Proactive Compaction (`/compact` + `/clear`)

**Principle:** context pressure is managed PROACTIVELY, not reactively. Do not wait for auto-compaction to kick in near the window boundary — at that point the orchestrator has already degraded.

| Command | When to invoke | Effect |
| :--- | :--- | :--- |
| `/compact` | At the two natural segment boundaries — end of Phase 4 (authorization halt) and end of Phase 6 (cycle close) | Summarizes prior turns, retains tool results, drops intermediate reasoning |
| `/clear` | Start of a new unrelated task within the same session | Full context reset — use when task intent shifts, not when extending a task |

**Guard:** if a single turn exceeds 50K tokens of tool output, emit `/compact` before the next turn starts. Never let a sub-agent's raw trace remain in main context past the immediate next turn.

**Anti-pattern:** invoking `/clear` mid-task to "free up room" — this destroys task context and forces re-discovery. Use `/compact` instead.

##### 5.2 Artifact Containment

`.claude/artifacts/` is the **EXCLUSIVE** location for all mandatory workflow artifacts (`task.md`, `implementation_plan.md`, `walkthrough.md`, Phase 6 reports, critique outputs, deliberation logs).

**Containment rules:**

1. **No exceptions for artifact writes** — every artifact file is written to `.claude/artifacts/` or nowhere. There is no fallback location.
2. **Artifacts are LOCAL-ONLY** — `.claude/artifacts/` is never git-tracked. The directory-level `.gitignore` entry is NEVER narrowed to exempt specific files.
3. **Phase 6 cleanup is MANDATORY** — `task.md` and `implementation_plan.md` are hard-deleted at the close of Phase 6. Only `walkthrough.md` persists across cycles (append-only).
4. **Read-only outside the sandbox** — agents MAY read any project file, but MAY NOT write outside the sandbox except through the explicit Phase 5 execution flow on an approved operation branch.

**Enforcement:** `block-destructive.sh` denies `Write`/`Edit` tool calls whose target path is not in `.claude/artifacts/` when the current branch is `master`/`main` (Law 5 + Law 40).

#### 6. TOKEN ANTI-PATTERNS

##### Anti-Pattern: Context Bloat

**Symptom:** Loading entire codebase for simple edit.
**Guard:** Max 5 files for ENGINEER, 10 for VALIDATOR, 20 for LIBRARIAN.
**Recovery:** Prune to relevant files only, request LIBRARIAN summary.

##### Anti-Pattern: Cache Miss

**Symptom:** Dynamic content before static in prompt structure.
**Guard:** Static rules first (000, 001, shared_protocols), always.
**Recovery:** Reorder prompt structure, add cache_control breakpoints.

##### Anti-Pattern: Thinking Waste

**Symptom:** Extended thinking budget for simple tasks.
**Guard:** Match thinking level to task complexity (simple: `minimal`, standard: `medium`, complex: `high`).
**Recovery:** Use `minimal` for routine tasks, `medium` for standard, `high` for complex reasoning only.

##### Anti-Pattern: Token Duplication

**Symptom:** Passing full conversation history to sub-agents.
**Guard:** Use role-aware context pruning (RCR-Router pattern).
**Recovery:** Prune context before delegation, use `@filename` references.

##### Anti-Pattern: Trace Bloat

**Symptom:** Sub-agent returns full execution trace (every failed test, bash error, iterative edit) to orchestrator.
**Trigger:** Any sub-agent return exceeding 2K tokens.
**Guard:** Sub-agents MUST run a final compression prompt before returning. Return ONLY: architectural impact, final state, outstanding anomalies.
**Success:** Orchestrator receives <500 token summary.
**Failure:** Raw trace pollutes orchestrator context → reasoning degradation.
**Fallback:** If compression fails, return only the final 3 lines of output + error count.

##### Anti-Pattern: MCP Schema Bloat

**Symptom:** Multiple MCP servers connected at initialization, consuming context with unused schemas.
**Trigger:** >3 MCP servers connected simultaneously.
**Guard:** Connect MCP servers on-demand. Use `ToolSearch` for schema discovery. Prefer CLI tools over MCP (see `runtime.md` §Tool Safety & MCP Governance).
**Success:** Only actively-needed MCP schemas in context.
**Failure:** Idle MCP schemas consume >5K tokens → LOG WARNING.
**Fallback:** Disconnect unused MCP servers mid-session.

##### Anti-Pattern: Natural Language Data Loop

**Symptom:** LLM orchestrating iterative API calls via natural language reasoning instead of scripts.
**Trigger:** >3 sequential tool calls processing the same data source.
**Guard:** Write a deterministic script (in whichever language fits the project) for the data pipeline. Execute via `Bash`. Return only the distilled result.
**Success:** Data processing happens outside LLM context.
**Failure:** Each API call + response permanently occupies context.
**Fallback:** Limit to 3 API calls and summarize.

</axiom_core>
<authority_matrix>

### WORKFLOW AUTHORITY

<scope>Defines strict enforcement rules for task management and phase transitions.</scope>

#### 7. WORKFLOW ANTI-PATTERNS (STRICT ENFORCEMENT)

##### Anti-Pattern: Freestyle Output

**Symptom:** Creating artifacts without using definitions in `.claude/resources/`.
**Action:** Use Resource Templates. All outputs must follow schemas.

##### Anti-Pattern: Vague Task

**Symptom:** Manager starts execution without "Step 0: Task Manifest" or manifest is vague.
**Action:** BLOCK. Break down steps until atomic (1-2 tool calls).

##### Anti-Pattern: The Schema Void (Law 30 Violation)

**Symptom:** `task.md` does not strictly follow `.claude/resources/task.md`.
**Action:** SYSTEM FAILURE. Delete `task.md` and recreate it using the template EXACTLY.


</authority_matrix>
<compliance_testing>

### COMPLIANCE AUDIT

<scope>Validation steps for common workflow and technical anti-patterns.</scope>

- [ ] **Check 1:** Verify JSON routing blocks are absolute first characters.
- [ ] **Check 2:** Confirm task.md exists and is being updated in tandem with work.

</compliance_testing>

<cache_control />

</protocol_framework>
