<protocol_framework name="subagents">

<meta>
  <id>"subagents"</id>
  <description>"Sub-agent lifecycle, context isolation, semantic compression, and delegation patterns for Claude Code."</description>
  <globs>[]</globs>
  <alwaysApply>false</alwaysApply>
  <tags>["type:protocol", "subagents", "delegation", "isolation"]</tags>
  <priority>"HIGH"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### SUB-AGENT PROTOCOL

<scope>Defines when and how to spawn sub-agents via Claude Code's `Agent` tool, ensuring context isolation and token-efficient returns.</scope>

#### 1. Sub-Agent Architecture

Sub-agents are ephemeral Claude Code instances spawned via the `Agent` tool. Each sub-agent operates with:
- **Independent context window** — does not share the orchestrator's conversation history.
- **Custom system prompt** — provided in the `Agent` tool's `prompt` parameter.
- **Scoped tool access** — controlled by the agent type parameter.
- **Model selection** — set via `model` parameter per the 3-tier routing strategy (see `stack.md`).

**Trigger:** Task requires deep exploration, large data processing, or focused analysis that would bloat the orchestrator's context.
**Success:** Sub-agent completes task and returns a compressed summary under 500 tokens.
**Failure:** Sub-agent returns raw traces or exceeds 2K token return → orchestrator context degraded.
**Fallback:** If sub-agent fails, orchestrator performs the task directly with aggressive context pruning.

#### 2. Delegation Criteria

Spawn a sub-agent when ANY of:
- Task requires reading >5 files for exploration.
- Task involves iterative search/analysis cycles (>3 tool calls for a single question).
- Task output is read-only (no concurrent file modifications needed).
- Task is parallelizable with other independent work.

Do NOT spawn a sub-agent when:
- Task requires <3 tool calls.
- Task needs write access to files the orchestrator is actively modifying.
- Task is sequential and depends on orchestrator state.

#### 3. Semantic Compression Protocol

**CRITICAL:** Returning full execution traces from sub-agents is a CATASTROPHIC anti-pattern.

Sub-agent prompts MUST include this compression directive:
> "Before returning your result, distill your findings into a summary under 500 tokens covering: (1) architectural impact of findings, (2) final state/answer, (3) outstanding anomalies or risks. Do NOT return raw tool output, full file contents, or step-by-step traces."

**Trigger:** Every sub-agent return.
**Success:** Return is <500 tokens, contains only semantic findings.
**Failure:** Return contains raw bash output, full file reads, or iterative logs.
**Fallback:** Orchestrator truncates return to last 3 lines + error count.

#### 4. Sub-Agent Prompt Template

```
You are a [ROLE] sub-agent. Your task: [SPECIFIC_TASK].

Context: [MINIMAL_CONTEXT — only what's needed, not full conversation history].

Constraints:
- Read-only unless explicitly stated otherwise.
- Do NOT modify files outside your scope.
- Return a compressed summary (<500 tokens): findings, impact, anomalies.
- Do NOT return raw tool output or step-by-step traces.
```

#### 5. Background vs Foreground Execution

| Mode | When | How |
| :--- | :--- | :--- |
| Foreground | Result needed before next step | `Agent` tool, default |
| Background | Independent work, no dependency | `Agent` tool with `run_in_background: true` |

**Parallel rule:** Launch multiple independent sub-agents in a single message when their tasks have no dependencies.

</axiom_core>
<authority_matrix>

### SUB-AGENT AUTHORITY

<scope>Defines delegation ownership and model tier assignments for sub-agent spawning.</scope>

#### 6. Delegation Authority

- **MANAGER** is the ONLY agent authorized to decide sub-agent spawning.
- **Model tier** MUST match task complexity (see `stack.md` 3-Tier Strategy).
- **Sub-agents** MUST NOT spawn further sub-agents (max depth = 1).

</authority_matrix>
<compliance_testing>

### SUB-AGENT AUDIT

<scope>Verification checks for sub-agent lifecycle compliance.</scope>

- [ ] **Check 1:** Sub-agent prompt includes compression directive.
- [ ] **Check 2:** Sub-agent return is <500 tokens (semantic summary only).
- [ ] **Check 3:** Model tier matches task complexity.
- [ ] **Check 4:** No sub-agent spawned for tasks requiring <3 tool calls.

</compliance_testing>

<cache_control />

</protocol_framework>
