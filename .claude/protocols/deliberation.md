---
description: "Structured deliberation via Tripartite Council model for high-stakes architectural decisions. Three independent agents debate before synthesis."
---

### STRUCTURED DELIBERATION PROTOCOL

> Defines the Tripartite Council model for multi-perspective consensus on high-risk architectural decisions, preventing single-agent anchoring bias.

#### 1. When to Invoke the Council

**Trigger:** MANAGER identifies a decision that meets ANY of:
- Production architecture change affecting >3 services or modules.
- Security-critical design choice (authentication, encryption, access control).
- Irreversible infrastructure decision (database selection, API contract, data model).
- Conflicting trade-offs with no clear winner (performance vs. maintainability, cost vs. reliability).

**Do NOT invoke the Council for:**
- Standard implementation tasks.
- Bug fixes with clear root causes.
- Documentation or style changes.

#### 2. Council Composition

Three agents, each instantiated with a distinct directive and independent context (anti-anchoring by design):

| Council Member | Directive | Focus |
| :--- | :--- | :--- |
| **EVOLUTION** | Push boundaries. Suggest novel approaches. Optimize for future scalability and innovation. | What could this become? |
| **IMPROVEMENT** | Rigorous fact-checking. Ensure adherence to current best practices and proven patterns. | Is this correct and safe today? |
| **KEENNESS** | Identify blind spots, edge cases, failure modes, and systemic security risks the others missed. | What could go wrong? |

#### 3. Deliberation Protocol (2-Round Hard Stop)

```
Round 1 — Independent Analysis (Parallel)
┌─────────────────────────────────────────────────┐
│ MANAGER spawns 3 sub-agents simultaneously:     │
│ • EVOLUTION agent — independent analysis        │
│ • IMPROVEMENT agent — independent analysis      │
│ • KEENNESS agent — independent analysis         │
│                                                 │
│ Each returns a structured opinion (<500 tokens): │
│ • Position: [stance on the decision]            │
│ • Rationale: [supporting evidence]              │
│ • Risks: [identified concerns]                  │
│ • Recommendation: [specific action]             │
└─────────────────────────────────────────────────┘

Round 2 — Cross-Examination (Parallel)
┌─────────────────────────────────────────────────┐
│ MANAGER spawns 3 sub-agents again, each         │
│ receiving ALL Round 1 outputs:                  │
│                                                 │
│ Each agent:                                     │
│ • Reviews peer opinions                         │
│ • Challenges inconsistencies                    │
│ • Refines own stance                            │
│ • Returns revised opinion (<500 tokens)         │
└─────────────────────────────────────────────────┘

HARD STOP — No Round 3. Prevents infinite adversarial looping.
```

#### 4. Synthesis

After Round 2, MANAGER (or ARCHITECT) synthesizes the council's output:

1. **Identify consensus points** — where all 3 agents agree.
2. **Flag dissent** — where agents disagree, document both positions.
3. **Audit against checklist:**
   - [ ] Does the solution address EVOLUTION's scalability concerns?
   - [ ] Does it pass IMPROVEMENT's best-practice validation?
   - [ ] Does it mitigate KEENNESS's identified risks?
   - [ ] Is the solution reversible or does it have a rollback plan?
   - [ ] Are the trade-offs explicitly documented?
   - [ ] Is there a monitoring/observability plan for the decision?
4. **Emit final specification** to `.claude/artifacts/` as the architectural decision record.

#### 5. Sub-Agent Prompt Templates

**EVOLUTION prompt:**
```
You are the EVOLUTION council member. Your directive: push boundaries and optimize for future scalability.

Decision under review: [DECISION_CONTEXT]

Analyze this decision and provide your opinion in exactly this structure:
- Position: [your stance]
- Rationale: [evidence and reasoning]
- Risks: [concerns with your own position]
- Recommendation: [specific action]

Keep response under 500 tokens. Be bold but honest about trade-offs.
```

**IMPROVEMENT prompt:**
```
You are the IMPROVEMENT council member. Your directive: rigorous fact-checking and adherence to proven best practices.

Decision under review: [DECISION_CONTEXT]

Analyze this decision and provide your opinion in exactly this structure:
- Position: [your stance]
- Rationale: [evidence and reasoning]
- Risks: [concerns with current approach]
- Recommendation: [specific action]

Keep response under 500 tokens. Prioritize correctness and safety.
```

**KEENNESS prompt:**
```
You are the KEENNESS council member. Your directive: identify blind spots, edge cases, failure modes, and security risks.

Decision under review: [DECISION_CONTEXT]

Analyze this decision and provide your opinion in exactly this structure:
- Position: [your stance]
- Rationale: [evidence and reasoning]
- Risks: [failure modes and edge cases others will miss]
- Recommendation: [specific action]

Keep response under 500 tokens. Be adversarial — find what others overlook.
```

### DELIBERATION AUTHORITY

> Defines who can invoke the council and how synthesis is governed.

#### 6. Authority

- **MANAGER** is the ONLY agent authorized to invoke the Tripartite Council.
- **Council members** are ephemeral sub-agents — they terminate after returning their opinion.
- **Model tier:** Council members use Tier 2 (Sonnet) by default. MANAGER may escalate to Tier 1 (Opus) for critical security decisions.
- **Synthesis** is performed by MANAGER or ARCHITECT, never by a council member.

### DELIBERATION AUDIT

> Verification checks for structured deliberation compliance.

- [ ] **Check 1:** All 3 council members produced independent Round 1 opinions (no shared context).
- [ ] **Check 2:** Round 2 opinions reference and challenge peer outputs.
- [ ] **Check 3:** Hard stop enforced — no Round 3 occurred.
- [ ] **Check 4:** Synthesis addresses all 6 checklist items.
- [ ] **Check 5:** Final specification written to `.claude/artifacts/`.
