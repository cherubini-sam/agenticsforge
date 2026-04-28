---
name: multi-agent
description: "Framework-agnostic mapping of the 7-role governance architecture to any multi-agent system. Use when building, deploying, or reasoning about orchestrator/worker agent topologies that implement MANAGER/ARCHITECT/ENGINEER/VALIDATOR/LIBRARIAN/REFLECTOR/PROTOCOL roles."
---

# Multi-Agent — Framework-Agnostic Role Mapping

Standard for multi-agent systems 7-role architecture.

## Foundations

- **Agent (AIMA).** Autonomous entity that perceives an environment via sensors and acts via actuators in pursuit of an objective. Every role below satisfies this.
- **Properties (Wooldridge).** Autonomy, reactivity, proactiveness, social ability — PROTOCOL is reactive, ARCHITECT/ENGINEER proactive, MANAGER social.
- **Orchestrator-worker pattern (Anthropic).** Lead agent decomposes the goal, delegates sub-tasks to workers in independent context windows, synthesises their results. Anthropic reports >90% improvement over single-agent baseline at 4–5× tokens.

## Agent Stack

- **MCP (Model Context Protocol).** Anthropic 2024, industry-standard by 2025 (OpenAI, Microsoft, GitHub, Linux Foundation). Workers consume tools/resources/prompts through one JSON-RPC contract; prefer an MCP server over bespoke glue whenever the integration outlives one prompt.
- **Memory tiers.** Short-term (in-context), working (turn-summarised), long-term (vector RAG / `walkthrough.md`). Pick the cheapest tier that satisfies recall.
- **Evaluation harnesses.** SWE-bench, τ-bench, AgentBench, or a project-specific golden set. Regress on every model or prompt change.
- **Code execution over JSON tool calls.** For data pipelines, generate code and execute via `Bash`/sandbox; returning tool-call traces consumes context, running code returns only the result.

## Role Reference

| Role      | Layer      | Responsibilities                                                            |
| :-------- | :--------- | :-------------------------------------------------------------------------- |
| MANAGER   | Supervisor | Intent classification, Tier 1/2 JSON, agent routing, phase-gate enforcement |
| PROTOCOL  | Supervisor | Boot checks, language lock, `prompt_intake.md` write                        |
| ARCHITECT | Worker     | Context research, `implementation_plan.md` authoring                        |
| REFLECTOR | Worker     | Plan critique, confidence scoring, approval gate                            |
| ENGINEER  | Worker     | Code implementation, shell execution, branch isolation                      |
| VALIDATOR | Worker     | Test execution, security scan, diff review                                  |
| LIBRARIAN | Worker     | Documentation, changelog, walkthrough append                                |

## Phase → Role

| Phase | Owner               | Gate artifact            |
| :---- | :------------------ | :----------------------- |
| P0(a) | PROTOCOL            | —                        |
| P0(b) | PROTOCOL            | `prompt_intake.md`       |
| P1    | MANAGER             | `task.md`                |
| P2    | ARCHITECT           | —                        |
| P3    | ARCHITECT           | `implementation_plan.md` |
| P4    | REFLECTOR           | Confidence 1.00          |
| P4.5  | MANAGER             | User `yes`               |
| P5    | ENGINEER            | Operation branch         |
| P6    | VALIDATOR + MANAGER | `walkthrough.md` append  |

## Single-Halt Atomicity (Law 33)

Exactly **one** interactive halt per cycle — the Phase 4 authorization request.

```
Segment A (one turn): P0(a) → P0(b) → P1 → P2 → P3 → P4 → [HALT]
User yes → Segment B (one turn): branch_create → P5 → P6 → [cycle close]
```

## Tier 1/2 JSON Contract

Every turn, the orchestrator emits routing JSON as **absolute first output** before any tool call or prose. Missing JSON = SESSION TERMINATION.

```
// Tier 1 — MANAGER
{ "target_agent": "<ROLE>", "intent": "<class>", "model_shard": "<id>",
  "language_check": "<ISO-639-1>", "persona": "<Lang>-<Role>" }

// Tier 2 — Worker
{ "active_agent": "<ROLE>", "task_type": "<class>",
  "execution_mode": "readonly | write | full" }
```

## Orchestrator/Worker Pseudocode

```
orchestrator_turn(input):
  emit tier1 = classify_and_route(input)
  emit tier2 = select_worker(tier1.target_agent)
  result = delegate(tier1.target_agent, pruned_context(gate_artifact))
  return compress(result)                   # <500 tokens back to orchestrator

worker_turn(context):
  execute_phase(context.phase)
  write_artifact(context.artifact_path)     # artifact sandbox only
  return structured_summary()               # final state + anomalies
```

## PROTOCOL Hooks

PROTOCOL is a **deterministic shell layer**, not an LLM worker:

| Hook                            | Blocks when                                                            |
| :------------------------------ | :--------------------------------------------------------------------- |
| `enforce-boot-gate.sh`          | Any tool call before `prompt_intake.md` exists                         |
| `enforce-phase-gate.sh`         | Phase artifact absent                                                  |
| `block-destructive.sh`          | Write/Edit on protected branches; `--force` push; destructive commands |
| `enforce-spawn-transparency.sh` | `Agent`/`Task` call without preceding `sub_agent_spawn` JSON           |

The LLM cannot reason past these.

## Communication Rules

- MANAGER → workers: structured context bundle (task summary + phase artifacts), NOT full history.
- Workers → MANAGER: structured summary <500 tokens, final state, anomalies only.
- REFLECTOR → MANAGER: `{"confidence": 0.0-1.0, "severity": "NONE|LOW|MEDIUM|HIGH|CRITICAL"}`. <1.00 or CRITICAL → re-route to ARCHITECT.
- Workers never communicate peer-to-peer; routing always via MANAGER.

## Model Tier

| Tier   | Model  | Use case                                             |
| :----- | :----- | :--------------------------------------------------- |
| Tier 1 | Opus   | Architecture, security audits, complex orchestration |
| Tier 2 | Sonnet | Standard implementation, debugging, tests            |
| Tier 3 | Haiku  | Read-only exploration, documentation                 |

Expensive models orchestrate; efficient models execute in parallel.

## Validation Checklist

- [ ] Tier 1 JSON + `sub_agent_spawn` block precede every orchestrator turn / spawn.
- [ ] Segment A and Segment B each run as a single non-interactive invocation.
- [ ] Workers receive pruned context; returns compressed to <500 tokens.
- [ ] PROTOCOL hooks block at the tool layer, never at LLM reasoning.
- [ ] Operation branch created at P4, HEAD preserved at P6.

## Sub-Agent Spawn Mechanism

In Claude Code, every `Agent`/`Task` tool call spawns a worker in an **isolated context window** with its own model shard. The session shard is immutable; the `Agent` tool's `model` parameter (`opus` | `sonnet` | `haiku` | omit-to-inherit) is the ONLY way to delegate to a different model mid-session.

Every spawn MUST be preceded in the orchestrator's text output by a `sub_agent_spawn` JSON block (Law 1 extension). Mechanically enforced by `enforce-spawn-transparency.sh`:

```json
{
  "event": "sub_agent_spawn",
  "tier": 4,
  "subagent_type": "Explore",
  "model_param": "haiku",
  "resolved_shard": "claude-haiku-4-5",
  "task_ref": "T-007"
}
```

Required fields: `event` (always `sub_agent_spawn`), `tier` (1–4), `subagent_type` (must match the `Agent` call), `model_param` (one of the 4 enum values), `resolved_shard` (concrete model ID), `task_ref` (Task ID from `task.md`, or `"—"` outside a formal cycle). Missing or malformed → hook exits 2 → tool call BLOCKED.

Spawned workers return only to their caller — no peer-to-peer messaging. The orchestrator compresses the worker's return to <500 tokens before it re-enters the main context.

## Source

Anthropic, Building Effective AI Agents, 2024; Model Context Protocol Specification (modelcontextprotocol.io), 2025.
