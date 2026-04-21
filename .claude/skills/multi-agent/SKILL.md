---
name: multi-agent
description: "Framework-agnostic mapping of the 7-role governance architecture to any multi-agent system. Use when building, deploying, or reasoning about orchestrator/worker agent topologies that implement MANAGER/ARCHITECT/ENGINEER/VALIDATOR/LIBRARIAN/REFLECTOR/PROTOCOL roles."
---

# Multi-Agent Architecture — Framework-Agnostic Role Mapping

## Role Reference

| Role | Layer | Responsibilities |
|:---|:---|:---|
| MANAGER | Supervisor | Intent classification, Tier 1/2 JSON emission, agent routing, phase-gate enforcement |
| PROTOCOL | Supervisor | Deterministic boot checks, language lock, `prompt_intake.md` write |
| ARCHITECT | Worker | Context research, implementation plan authoring, ADR decisions |
| REFLECTOR | Worker | Plan critique, confidence scoring, approval gate |
| ENGINEER | Worker | Code implementation, shell execution, branch isolation |
| VALIDATOR | Worker | Test execution, security scan, diff review before merge |
| LIBRARIAN | Worker | Documentation authoring, changelog maintenance, walkthrough append |

## Phase-to-Role Routing

| Phase | Owner | Gate artifact |
|:---|:---|:---|
| P0(a) Boot Validation | PROTOCOL | — |
| P0(b) Prompt Intake | PROTOCOL | `prompt_intake.md` |
| P1 Task Manifest | MANAGER | `task.md` |
| P2 Context Research | ARCHITECT | — |
| P3 Implementation Plan | ARCHITECT | `implementation_plan.md` |
| P4 Plan Critique | REFLECTOR | Confidence 1.00 required |
| P4.5 Authorization Halt | MANAGER | User `yes` required |
| P5 Execution | ENGINEER | Operation branch |
| P6 Verification + Close | VALIDATOR + MANAGER | `walkthrough.md` append |

## Single-Halt Atomicity (Law 33)

Every orchestration cycle has **exactly one** interactive halt — the Phase 4 authorization request.

```
Segment A (one turn, no user input):
  P0(a) → P0(b) → P1 → P2 → P3 → P4 → [HALT — emit authorization request]

User approves → Segment B (one turn, no user input):
  branch_create → P5 → P6 → [cycle close — non-interactive]
```

The I/O boundary is the Phase 4 authorization request. No other turn boundary is permitted within a cycle. Enforce via `max_turns=1` per segment in any framework that supports it.

## Tier 1/2 JSON Contract

Every turn, the orchestrator emits routing JSON as **absolute first output** before any tool call or prose.

```
// Tier 1 — MANAGER routing
{
  "target_agent": "<ROLE>",
  "intent": "<classification>",
  "model_shard": "<detected_shard>",
  "language_check": "<ISO-639-1 code>",
  "persona": "<Language>-<Role>"
}

// Tier 2 — Worker execution
{
  "active_agent": "<ROLE>",
  "task_type": "<classification>",
  "execution_mode": "readonly | write | full"
}
```

Missing JSON on any turn = Law 1 violation → SESSION TERMINATION.

## Generic Orchestrator/Worker Pattern

```
orchestrator_turn(user_input):
  tier1 = classify_and_route(user_input)     // emit JSON first
  tier2 = select_worker(tier1.target_agent)  // emit JSON second
  gate  = read_gate_artifact(current_phase)  // prompt_intake / task / impl_plan
  result = delegate(tier1.target_agent, pruned_context(gate))
  return compress(result)                    // <500 tokens back to orchestrator

worker_turn(context):
  execute_phase(context.phase)
  write_artifact(context.artifact_path)      // artifact sandbox only
  return structured_summary()               // final state + anomalies
```

Workers receive **pruned context only** — not the full conversation history. Orchestrator compresses sub-agent returns before they re-enter the main context (anti-pattern: Trace Bloat).

## PROTOCOL Hook Table

PROTOCOL is a **deterministic shell layer**, not an LLM worker. It gates tool calls via pre-tool-use hooks:

| Hook | Blocks when |
|:---|:---|
| `enforce-boot-gate.sh` | Any tool call before `prompt_intake.md` exists |
| `enforce-phase-gate.sh` | Phase artifact absent for the current phase |
| `block-destructive.sh` | Write/Edit outside artifact sandbox on `master`/`main`; `--force` push; destructive commands |

These hooks enforce protocol correctness mechanically — the LLM cannot reason its way past them.

## Role Communication Rules

- MANAGER → workers: structured context bundle (task summary + phase artifacts), NOT full chat history
- Workers → MANAGER: structured summary (<500 tokens), final state, outstanding anomalies ONLY
- REFLECTOR → MANAGER: `{"confidence": 0.0-1.0, "severity": "NONE|LOW|MEDIUM|HIGH|CRITICAL", "issues": [...]}`
- Confidence < 1.00 or severity == CRITICAL → route back to ARCHITECT for plan revision
- Workers NEVER communicate peer-to-peer; all routing goes through MANAGER

## Model Tier Assignment

| Tier | Use case | Trigger |
|:---|:---|:---|
| Tier 1 (most capable) | Architecture, security audits, complex orchestration | `system_design`, `security_audit`, `complex_reasoning` |
| Tier 3 (balanced) | Standard implementation, debugging, tests | `implementation`, `refactor`, `bug_fix` |
| Tier 4 (fastest) | Read-only exploration, documentation | `exploration`, `documentation`, `analysis` |

Expensive models plan and orchestrate; efficient models execute in parallel.

## Validation Checklist

When implementing this architecture in any framework:

- [ ] Tier 1 JSON emitted as absolute first token of every orchestrator turn
- [ ] Segment A and Segment B each run as a single non-interactive invocation
- [ ] Workers receive pruned context, not full history
- [ ] Sub-agent returns compressed to <500 tokens before re-entering orchestrator context
- [ ] PROTOCOL hooks implemented as pre-tool-use interceptors (not LLM reasoning)
- [ ] Artifact sandbox isolated from source tree
- [ ] Operation branch created at P4, HEAD preserved at P6
