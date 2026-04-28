---
description: "Technical stack specifications: supported models, 3-tier routing, token budget, and cost controls. Always active."
---

### TOKEN & COST AXIOMS

> Core token budget and cost thresholds governing all agent inference operations across supported model families.

#### LLM Runtime — Current Models (Recommended)

Model is detected per session via `CLAUDE.md` and loaded as an immutable shard.

| Shard | Model ID | Context In | Max Out | Reasoning | Default Effort | Pricing (Input/Output per MTok) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `claude-haiku-4-5` | `claude-haiku-4-5-20251001` | 200K | 64K | Extended — budget-controlled (4K–16K budget_tokens) | Disabled | $1.00 / $5.00 |
| `claude-sonnet-4-6` | `claude-sonnet-4-6` | 1M | 64K | Adaptive (low/medium/high/max); interleaved automatic | `medium` | $3.00 / $15.00 |
| `claude-opus-4-7` | `claude-opus-4-7` | 1M | 128K | Adaptive only (low/medium/high/xhigh/max); extended thinking not supported | `high` | $5.00 / $25.00 |

#### LLM Runtime — Legacy Models (Available, Not Deprecated)

| Shard | Model ID | Context In | Max Out | Reasoning | Default Effort | Pricing (Input/Output per MTok) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `claude-sonnet-4-5` | `claude-sonnet-4-5-20250929` | 200K | 64K | Extended — budget-controlled | Disabled | $3.00 / $15.00 |
| `claude-opus-4-5` | `claude-opus-4-5-20251101` | 200K | 64K | Extended — budget-controlled | Disabled | $5.00 / $25.00 |
| `claude-opus-4-6` | `claude-opus-4-6` | 1M | 128K | Adaptive (extended thinking deprecated — migrate to adaptive) | `high` | $5.00 / $25.00 |

Non-existent versions (do not request): `claude-haiku-4-6`, `claude-haiku-4-7`, `claude-sonnet-4-7`.

Cache minimum: 1024 tokens. Cached input: ~90% discount (5-min or 1-hr TTL). Batch API: 50% discount on input + output.

#### Shard Fallback Resolution

When the running model ID is not found in the tables above, apply this deterministic chain (no LLM-based matching):

1. Parse the model family from the ID prefix: `haiku` | `sonnet` | `opus`.
2. Select the highest available **current** shard for that family.
3. If the family cannot be identified, default to `claude-sonnet-4-6`.

| Unknown Shard Family | Fallback Shard |
| :--- | :--- |
| Any unrecognized Haiku version | `claude-haiku-4-5` |
| Any unrecognized Sonnet version | `claude-sonnet-4-6` |
| Any unrecognized Opus version | `claude-opus-4-7` |
| Unknown family | `claude-sonnet-4-6` |

Emit `LOG WARNING` when fallback resolution is triggered.

#### 3-Tier Model Routing Strategy

**Parent session model is IMMUTABLE.** The model is fixed at `claude` launch and cannot change mid-conversation. The `Agent` tool's `model` parameter is the ONLY mechanism to delegate work to a different model within a session.

| Tier | Model | `Agent` tool `model` param | Use Case | Trigger |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 | Claude Opus 4.7 | `"opus"` | Architecture, security audits, complex orchestration, production code review | MANAGER routes `system_design`, `security_audit`, `complex_reasoning` |
| Tier 2 | Claude Sonnet 4.6 | `"sonnet"` | Standard implementation, debugging, unit tests, bulk engineering | MANAGER routes `implementation`, `refactor`, `bug_fix`, `test_generation` |
| Tier 3 | Claude Haiku 4.5 | `"haiku"` | Fast read-only tasks: codebase search, doc generation, SEO, exploration | MANAGER routes `exploration`, `documentation`, `analysis` |

**Routing rule:** Expensive models plan and orchestrate; efficient models execute in parallel.

**Inherit semantics:** when MANAGER omits the `model` param, the sub-agent inherits the parent session shard. This is orthogonal to tier numbering — the spawn's `tier` field reflects the executing model's tier (the parent's tier when inheriting).

**Delegation syntax examples** (notation: tool-call signature, language-agnostic):

```text
# Tier 1 — architecture task
Agent(subagent_type="architect", model="opus", prompt="...")

# Tier 2 — standard implementation
Agent(subagent_type="engineer", model="sonnet", prompt="...")

# Tier 3 — read-only exploration
Agent(subagent_type="Explore", model="haiku", prompt="...")

# Inherit parent shard (omit model param) — tier reflects parent's tier
Agent(subagent_type="engineer", prompt="...")
```

#### Sub-Agent Spawn Transparency

Every `Agent` tool call MUST be preceded by a spawn-transparency JSON block in conversation output (Law 1 extension). This makes sub-agent model delegation as visible as any other agent turn.

**Required format:**

```json
{
  "event": "sub_agent_spawn",
  "tier": 2,
  "subagent_type": "engineer",
  "model_param": "sonnet",
  "resolved_shard": "claude-sonnet-4-6",
  "task_ref": "T-005"
}
```

**Field rules:**

| Field | Type | Constraint |
| :--- | :--- | :--- |
| `event` | string | Always `"sub_agent_spawn"` |
| `tier` | integer | `1` \| `2` \| `3` |
| `subagent_type` | string | Matches the `subagent_type` passed to `Agent` |
| `model_param` | string | `"opus"` \| `"sonnet"` \| `"haiku"` \| `"inherit"` (use `"inherit"` when param omitted) |
| `resolved_shard` | string | The concrete model ID that will execute (apply Shard Fallback Resolution if needed) |
| `task_ref` | string | Task ID from `task.md`; use `"—"` when outside a formal task cycle |

Omitting this block before an `Agent` call = Law 1 violation → SESSION TERMINATION.

**Mechanical enforcement:** `.claude/hooks/enforce-spawn-transparency.sh` is a `PreToolUse` hook scoped to `Agent`/`Task` that reads the active session transcript, locates the most recent assistant text output, and validates that it contains a JSON object with `event == "sub_agent_spawn"` and the full required schema. Missing block, schema violation, or `subagent_type` mismatch = exit 2 (BLOCK). Wired in `.claude/settings.json` under `hooks.PreToolUse` with matcher `"Agent|Task"`.

#### Cost Controls

| Threshold | Action |
| :--- | :--- |
| Single request > 50K tokens | LOG WARNING |
| Session total > 500K tokens | STOP + REQUEST CHECKPOINT |

Bypass: manual user override for large-scale codebase migrations.

### STACK AUTHORITY

> Authoritative stack configuration. Deviations require user approval.

LOG WARNING and notify user on any stack deviation. Bypass: explicit user override for environment-specific configurations.

### STACK AUDIT

> Pre-execution checklist to validate stack and token budget compliance.

- [ ] **Check 1:** Active model matches a recognized shard; shard loaded and immutable for session.
- [ ] **Check 2:** Request token count < 50K; session total < 500K.
- [ ] **Check 3:** Automated test suite present for all source code in the project's primary language.
- [ ] **Check 4:** Infrastructure targets match authoritative stack configuration.
- [ ] **Check 5:** Every `Agent` tool call preceded by a spawn-transparency JSON block in conversation output.
