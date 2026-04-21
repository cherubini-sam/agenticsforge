<protocol_framework name="concurrency">

<meta>
  <id>"concurrency"</id>
  <description>"Execution-model constraints under Law 40 v2 (Branch Isolation): sequential single-agent on operation branch; concurrent multi-agent isolation NOT supported."</description>
  <globs>[]</globs>
  <alwaysApply>false</alwaysApply>
  <tags>["type:protocol", "concurrency", "git", "branch-isolation", "sequential"]</tags>
  <priority>"MEDIUM"</priority>
  <version>"2.0.0"</version>
</meta>

<axiom_core>

### CONCURRENCY CONTROL PROTOCOL

<scope>Defines the current execution model (sequential single-agent on the operation branch) and the constraints under which concurrent multi-agent work is FORBIDDEN.</scope>

#### 1. Current Model: Sequential Single-Agent Execution

The 6-Phase Industrial Workflow is single-agent and single-branch. Phase 4 creates `{operation}/{slug}` via `git checkout -b`, HEAD switches to that branch, and every Phase 5 tool call mutates files under that HEAD. No parallel branch work is possible in one checkout: git enforces one HEAD per working tree.

**Trigger:** MANAGER receives a user request.
**Success:** One agent progresses phases sequentially; all writes land on the operation branch.
**Failure:** Attempting to spawn a parallel agent that switches HEAD mid-phase → race condition → data loss risk.
**Fallback:** Serialize — the current cycle finishes (P6) before a new cycle begins.

#### 2. Concurrent Multi-Agent Execution — NOT SUPPORTED

The prior protocol version exposed `isolation: "worktree"` on the `Agent` tool to allow parallel sub-agent work on separate worktrees. This mode is REMOVED under Law 40 v2 (Branch Isolation). Rationale:

- Worktree abstraction hid agent work from the user's IDE (single checkout reality).
- Parallel agents raced on HEAD if two sub-agents attempted concurrent checkouts.
- Merge protocol required manual diff review per branch — expensive orchestration cost for rare benefit.

If future work demands true parallel isolation, revisit via a separate RFC (do NOT re-introduce `isolation: "worktree"` implicitly).

#### 3. File Locking — Residual

If a future cycle reintroduces a worker-pool pattern (e.g., a MANAGER that dispatches validation to VALIDATOR while ARCHITECT plans a follow-up), apply file-scope discipline:

| Rule | Description |
| :--- | :--- |
| Exclusive write | Only one agent may write to a given file per phase |
| Scope declaration | Each agent declares its file scope in `task.md §Scope` before starting |
| Conflict detection | MANAGER verifies no scope overlap before delegation |
| Lock timeout | If an agent holds scope >5 minutes without progress, escalate to REFLECTOR |

This § is DORMANT under the current sequential model but preserved as reference for future architecture work.

#### 4. Recovery Points

Phase-based execution creates natural recovery points:
- **After Phase 3 (Plan):** plan validated. If implementation fails, revert to plan without re-running expensive reasoning.
- **After Phase 5 (Execute):** code committed to `{operation}/{slug}`. If validation fails, revert via `git reset --hard {operation}/{slug}^` (destructive; requires user confirmation).
- **Git state:** operation branches persist until user merges or deletes. Rollback via `git branch -D {operation}/{slug}` (destructive; user-initiated only).

</axiom_core>
<authority_matrix>

### CONCURRENCY AUTHORITY

<scope>Execution-model authority under the single-checkout branch-isolation model.</scope>

- **MANAGER** enforces sequential execution. Parallel `Agent` calls that would mutate HEAD are FORBIDDEN.
- **REFLECTOR** audits plans for implicit concurrency assumptions (e.g., "parallel sub-agents refactor modules X and Y") and REJECTS them.
- **VALIDATOR** reviews branch diffs before signalling Phase 6 PASS.
- **No agent** may promote `{operation}/{slug}` to `master`/`main` — human-only operation.

</authority_matrix>
<compliance_testing>

### CONCURRENCY AUDIT

<scope>Verification checks for execution-model compliance.</scope>

- [ ] **Check 1:** No `Agent(isolation: "worktree")` call in any protocol or agent definition.
- [ ] **Check 2:** No two agents mutate the same file in one phase (scope declaration honored).
- [ ] **Check 3:** HEAD stays on `{operation}/{slug}` for the full P4–P6 duration.
- [ ] **Check 4:** Operation branches preserved post-P6 for human-only promotion.

</compliance_testing>

<cache_control />

</protocol_framework>
