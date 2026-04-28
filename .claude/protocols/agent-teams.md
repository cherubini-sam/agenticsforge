---
description: "Agent Team coordination: initialization, file locking, task claiming, race condition prevention for Claude Code."
---

### AGENT TEAM PROTOCOL

> Governs collaborative multi-agent execution using Claude Code Agent Teams, including initialization, task distribution, file safety, and anti-anchoring.

#### 0. HARD GATE — Default Is Single-Agent

> [!CRITICAL]
> **Agent Teams are OFF by default.** Single-agent execution with deterministic hooks is the canonical pattern for this project. Teams are only permitted when ALL of the following conditions hold:
>
> 1. The task spans **≥3 genuinely independent domains** (e.g., backend API + frontend UI + database schema, with no shared source files between the domains).
> 2. Sub-agent sequential execution has been evaluated and rejected with a written rationale in `implementation_plan.md` §Architecture Decision.
> 3. MANAGER obtains explicit user authorization in Phase 4 (not Phase 3) before team initialization.
> 4. Every team member writes EXCLUSIVELY to `.claude/artifacts/` OR to a pre-declared file scope that is disjoint from every other member's scope.
>
> **Rubber-Stamp Reviewer LLMs are BANNED.** A team member whose sole role is to "approve" another member's work (without independent execution authority) constitutes theatrical review and MUST NOT be instantiated. Use the REFLECTOR agent in the standard workflow instead.
>
> **Team writes outside the artifact sandbox** require the same branch-isolation guards as single-agent writes (Law 40). Teams do not bypass containment.

#### 1. Agent Team Architecture

Agent Teams are collaborative mesh networks of independent Claude Code instances. Unlike sub-agents (hierarchical, report to orchestrator), team members:
- Communicate via the orchestrator — sub-agents spawned via the `Agent` tool have isolated context windows and return only to their caller; they cannot message each other directly.
- Self-coordinate objectives through orchestrator-mediated task assignment.
- Each maintain independent context windows (anti-anchoring by design).

**Trigger:** Complex interdependent tasks requiring continuous synchronization across **≥3 independent domains** AND satisfying §0 hard gate. Below 3 domains, use sub-agents.
**Success:** All team tasks complete without file conflicts or stale data.
**Failure:** Race condition on shared files, or task deadlock.
**Fallback:** Dissolve team, revert to sequential sub-agent execution under orchestrator control.

#### 2. Initialization

**Prerequisites:**
- Agent Teams feature enabled in Claude Code environment.
- Team configuration defined with distinct roles per member.

**Team structure template:**
- Member 1: Domain specialist A (e.g., Backend Engineer)
- Member 2: Domain specialist B (e.g., Frontend Engineer)
- Member 3: Evaluator/Reviewer (independent quality check)

**Anti-anchoring guarantee:** Each member starts with an independent context, generating divergent approaches before synthesis.

#### 3. File Locking and Race Condition Prevention

| Mechanism | Description |
| :--- | :--- |
| Dynamic file locking | When a teammate claims a task, lock files in scope via orchestrator-tracked task state in `task.md` |
| Dependency blocking | Tasks with prerequisites are blocked until prerequisite tasks complete |
| Automatic unblocking | When a prerequisite task completes, dependent tasks unblock automatically |

**Trigger:** Any team member attempts to modify a file.
**Success:** File lock acquired, modification proceeds, lock released on task completion.
**Failure:** Lock conflict detected → team member waits for lock release.
**Fallback:** If lock held >5 minutes, escalate to orchestrator for manual resolution.

**CRITICAL:** Two agents MUST NEVER modify the same file concurrently. The file locking mechanism is the primary defense.

#### 4. Task Claiming Protocol

1. Orchestrator decomposes work into discrete tasks with explicit file scopes.
2. Each task specifies: description, file scope, dependencies, estimated complexity.
3. Team members claim tasks from the shared queue.
4. Claimed tasks are locked — no other member can claim the same task.
5. On completion, member marks task done; dependent tasks unblock.

#### 5. When NOT to Use Agent Teams

- Simple tasks solvable by a single agent.
- Tasks with heavy sequential dependencies (use sub-agents instead).
- Tasks where all work touches the same files (use single agent with phase-based execution).

### TEAM AUTHORITY

> Defines team lifecycle ownership and escalation paths.

#### 6. Authority

- **MANAGER** decides when to initialize a team vs. use sub-agents vs. single agent.
- **Team members** are autonomous within their task scope but CANNOT modify files outside their locked scope.
- **Escalation:** Any unresolvable conflict → MANAGER dissolves team and takes direct control.

### TEAM AUDIT

> Verification checks for Agent Team safety and coordination.

- [ ] **Check 1:** No two team members modified the same file.
- [ ] **Check 2:** All task dependencies respected (no task executed before prerequisites complete).
- [ ] **Check 3:** Team dissolved cleanly — no orphaned locks or stale tasks.
- [ ] **Check 4:** Final output integrated and verified by Evaluator member or VALIDATOR agent.
