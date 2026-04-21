---
description: "Technical stack specifications: supported models, 4-tier routing, token budget, and cost controls. Always active."
---

<governance_logic name="stack">

<meta>
  <id>"stack"</id>
  <description>"Technical stack specifications and token budget policing."</description>
  <globs>[]</globs>
  <alwaysApply>true</alwaysApply>
  <tags>["type:rule", "stack", "performance", "environment"]</tags>
  <priority>"HIGH"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### TOKEN & COST AXIOMS

<scope>Core token budget and cost thresholds governing all agent inference operations across supported model families.</scope>

#### LLM Runtime — Supported Models

Model is detected per session via `CLAUDE.md` and loaded as an immutable shard.

| Shard | Model ID | Context In | Max Out | Reasoning | Default Effort | Pricing (Input/Output per MTok) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `claude-haiku-4` | `claude-haiku-4-5` | 200K | 64K | Budget-controlled (opt-in, 4K–16K budget) | Disabled | $1.00 / $5.00 |
| `claude-sonnet-4` | `claude-sonnet-4-6` | 200K | 128K | Adaptive (low/medium/high/max) | `medium` | $3.00 / $15.00 |
| `claude-opus-4` | `claude-opus-4-6` | 200K (1M beta) | 128K | Adaptive (low/medium/high/max) | `high` | $5.00 / $25.00 |

Cache minimum: 1024 tokens. Cached input: 90% discount (5-min or 1-hour TTL). Tiered pricing applies above 200K context.

#### 4-Tier Model Routing Strategy

| Tier | Model | Use Case | Trigger |
| :--- | :--- | :--- | :--- |
| Tier 1 | Claude Opus 4.6 | Architecture, security audits, complex orchestration, production code review | MANAGER routes tasks classified as `system_design`, `security_audit`, `complex_reasoning` |
| Tier 2 | Inherit/Dynamic | Complex tasks where orchestrator selects model based on load; defaults to Sonnet 4.6 | MANAGER sets `model: "inherit"` in sub-agent config |
| Tier 3 | Claude Sonnet 4.6 | Standard implementation, debugging, unit tests, bulk engineering | MANAGER routes `implementation`, `refactor`, `bug_fix`, `test_generation` |
| Tier 4 | Claude Haiku 4.5 | Fast read-only tasks: codebase search, doc generation, SEO, exploration | MANAGER routes `exploration`, `documentation`, `analysis` via `Agent` tool with `model: "haiku"` |

**Routing rule:** Expensive models plan and orchestrate; efficient models execute in parallel.

#### Cost Controls

| Threshold | Action |
| :--- | :--- |
| Single request > 50K tokens | LOG WARNING |
| Session total > 500K tokens | STOP + REQUEST CHECKPOINT |

Bypass: manual user override for large-scale codebase migrations.

</axiom_core>
<authority_matrix>

### STACK AUTHORITY

<scope>Authoritative stack configuration. Deviations require user approval.</scope>

LOG WARNING and notify user on any stack deviation. Bypass: explicit user override for environment-specific configurations.

</authority_matrix>
<compliance_testing>

### STACK AUDIT

<scope>Pre-execution checklist to validate stack and token budget compliance.</scope>

- [ ] **Check 1:** Active model matches a recognized shard; shard loaded and immutable for session.
- [ ] **Check 2:** Request token count < 50K; session total < 500K.
- [ ] **Check 3:** Pytest suite present for all Python source code.
- [ ] **Check 4:** Infrastructure targets match authoritative stack configuration.

</compliance_testing>

<cache_control />

</governance_logic>
