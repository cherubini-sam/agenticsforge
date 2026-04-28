---
description: "Inter-session memory persistence hierarchy: User, Project, and Local memory tiers with pointer-based indexing."
---

### MEMORY PERSISTENCE PROTOCOL

> Defines the 3-tier memory hierarchy, pointer-based indexing, and append-only write model for inter-session state persistence in Claude Code.

#### 1. Memory Hierarchy

| Tier | Scope | Storage Path | Shared | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| User Memory | All projects on machine | `~/.claude/agent-memory/<name>/` | No (personal) | Cross-project learnings, user preferences, workflow patterns |
| Project Memory | Current project, all team members | `.claude/agent-memory/<name>/` | Yes (version controlled) | Project-specific decisions, architecture rationale, team conventions |
| Local Project Memory | Current project, current user only | `.claude/agent-memory-local/<name>/` | No (gitignored) | Private project learnings, experimental findings, personal notes |

**Trigger:** Agent completes a session and has learnings worth preserving.
**Success:** Learnings persisted to appropriate tier, retrievable in future sessions.
**Failure:** Memory written to wrong tier (e.g., personal preferences in project memory).
**Fallback:** Default to Local Project Memory if tier is ambiguous.

#### 2. Pointer-Based Memory Index

Each memory tier uses a `memory.md` file as a structured pointer index — NOT a raw storage repository.

**Index structure:**
```markdown
# Memory Index
## Architecture Decisions
- [ADR-001: API Gateway Selection](DECISIONS.md#adr-001) — chose Kong over Nginx for plugin ecosystem
## Corrections
- [CORR-001: Test isolation](CORRECTIONS.md#corr-001) — integration tests must not share DB state
## Handoffs
- [HAND-001: Auth refactor](HANDOFF.md#hand-001) — OAuth2 migration in progress, blocked on cert renewal
```

**Domain files:**
| File | Purpose |
| :--- | :--- |
| `STATE.md` | Current project state snapshot |
| `DECISIONS.md` | Architecture Decision Records (ADRs) |
| `CORRECTIONS.md` | User corrections and learned constraints |
| `HANDOFF.md` | Unresolved work, blocked tasks, session continuations |

#### 3. Write Model

**Append-only event log:** Agents write discrete events to domain files. Never overwrite existing entries.

**Event format:**
```markdown
## [ISO-8601 Timestamp] — [Agent] — [Event Type]
**Context:** [What prompted this entry]
**Decision/Finding:** [The actual content]
**Impact:** [How this affects future work]
```

**Trigger:** End of any session where decisions were made, corrections received, or work left unfinished.
**Success:** Event appended to correct domain file; index updated with pointer.
**Failure:** Overwrite of existing entries → data loss.
**Fallback:** If append fails, write to `HANDOFF.md` as a catch-all.

#### 4. Memory Retrieval

At session start, orchestrator:
1. Reads `memory.md` index (lightweight — pointers only).
2. Loads domain files relevant to current task (on-demand, not bulk).
3. Applies corrections from `CORRECTIONS.md` as behavioral constraints.
4. Checks `HANDOFF.md` for unfinished work related to current request.

**Token budget:** Memory loading MUST NOT exceed 2K tokens. Use pointers, not full file contents.

#### 5. Memory Hygiene

- Stale entries (>30 days without reference) → archive to `ARCHIVE.md`.
- Contradictory entries → resolve in favor of most recent, annotate the older entry.
- Project Memory entries MUST be reviewed before committing to version control.

### MEMORY AUTHORITY

> Defines which agents can read and write to each memory tier.

#### 6. Access Control

| Agent | User Memory | Project Memory | Local Project Memory |
| :--- | :--- | :--- | :--- |
| MANAGER | Read | Read/Write | Read/Write |
| LIBRARIAN | Read | Read/Write | Read/Write |
| ARCHITECT | Read | Read | Read |
| ENGINEER | No | Read | Read |
| VALIDATOR | No | Read | No |
| REFLECTOR | No | Read | No |
| PROTOCOL | No | Read | No |

### MEMORY AUDIT

> Verification checks for memory persistence compliance.

- [ ] **Check 1:** Memory index (`memory.md`) is pointer-based, not content-heavy (<500 tokens).
- [ ] **Check 2:** Domain files use append-only writes (no overwrites of existing entries).
- [ ] **Check 3:** Memory tier matches content scope (personal → User, team → Project, private → Local).
- [ ] **Check 4:** Stale entries (>30 days) archived.
