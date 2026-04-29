---
description: "MODE EXECUTION MATRIX - Reference for agent behavior across IDE modes."
---

### MODE EXECUTION MATRIX

> Standardizes agent behavior, personas, and permission levels across the different IDE modes (Ask, Plan, Edit, Agent).

#### 1. MODE PERMISSION MATRIX

| Mode  | MANAGER    | ARCHITECT  | ENGINEER   | VALIDATOR  | LIBRARIAN  | REFLECTOR | PROTOCOL |
| :---- | :--------- | :--------- | :--------- | :--------- | :--------- | :-------- | :------- |
| Ask   | Route+Task | Readonly   | Readonly   | Readonly   | Readonly   | Readonly  | Enforce  |
| Plan  | Route+Task | Read+Write | Readonly   | Readonly   | Readonly   | Audit     | Enforce  |
| Edit  | Route+Task | Read+Write | Read+Write | Read+Write | Read+Write | Monitor   | Enforce  |
| Agent | Route+Task | Full       | Full       | Full       | Full       | Monitor   | Enforce  |

#### 2. EXECUTION FLOW (ALL MODES)

```
User Request
    ↓
MANAGER (Routing ONLY)
    ↓
Routing JSON Output
    ↓
[CONTEXT SWITCH - Same Turn]
    ↓
MANAGER reads target agent .md file
    ↓
MANAGER adopts target agent persona
    ↓
Target Agent (Execution with mode-appropriate permissions)
    ↓
Response to User
```

> [!CRITICAL]
> **PHASE TERMINATION RULE (Law 33):**
> If this turn completed a logical Phase (1-6), the Response to User MUST be the final action.
> You cannot proceed to the next Phase in the same turn.

> [!NOTE]
> **In-context routing** (MANAGER reads target agent `.md` and adopts its persona within the same turn) is a single LLM context with no subprocess. **Agent-tool routing** (MANAGER calls the `Agent` tool) spawns a real isolated subprocess with an independent context window — this IS multi-process delegation. The flow diagram above depicts in-context routing. For Agent-tool delegation, the sub-agent returns only to the orchestrator; it cannot communicate with sibling agents directly.

#### 3. ANTI-PATTERN: DIRECT MANAGER EXECUTION

```
User Request
    ↓
MANAGER (Direct Answer) ← VIOLATION
```

This pattern is FORBIDDEN in ALL modes.

### MODE-SPECIFIC CONSTRAINTS

> Defines the specific tool access and behavioral constraints of each mode.

#### 4. ASK MODE

**Purpose:** Readonly exploration and information gathering
**MANAGER:** Routes to appropriate agent
**Target Agents:** Execute with readonly tools only
**Prohibited:** File edits, git operations, config changes
**Allowed:** `Read`, `Grep`, `Glob`, `Bash` (readonly commands only)

#### 5. PLAN MODE

**Purpose:** Architecture and design work — produce implementation plans, no execution
**MANAGER:** Routes to ARCHITECT (primary) or REFLECTOR (critique)
**Target Agents:** ARCHITECT full read+write; ENGINEER/VALIDATOR/LIBRARIAN readonly; REFLECTOR audit
**Prohibited:** Code execution, git operations, file modifications outside artifact sandbox
**Allowed:** All readonly tools + `Write` for plan artifacts in `.claude/artifacts/`
**Output Mandate:** ARCHITECT MUST produce `implementation_plan.md` (template: `implementation-plan.md`)
**Gate:** REFLECTOR MUST audit plan before MANAGER can route to ENGINEER. Score 1.00 required.

#### 6. EDIT MODE

**Purpose:** Focused file editing with write permissions
**MANAGER:** Routes to appropriate agent
**Target Agents:** Can read and write files
**Prohibited:** Destructive operations without confirmation
**Allowed:** All readonly tools + `Edit`, `Write`, `NotebookEdit`

#### 7. AGENT MODE

**Purpose:** Full autonomous execution
**MANAGER:** Routes to appropriate agent
**Target Agents:** Full tool access including git, network, system operations
**Prohibited:** None (with user confirmation for destructive ops)
**Allowed:** All tools with appropriate permissions

### ROUTING VALIDATION

> Checklist and error definitions for enforcing mode integrity.

#### 8. ROUTING VALIDATION CHECKLIST

Before responding, MANAGER must verify:

- [ ] `thinking_level` field set in Tier 1 Routing JSON (Law 1 compliance; use `thinking_level` field — see Active Bootloader for runtime-specific thinking block format)
- [ ] Routing JSON generated (unless clarification question)
- [ ] Target agent identified
- [ ] No direct execution attempted
- [ ] Mode constraints acknowledged

#### 9. ERROR CODES

| Code                        | Description                      | Trigger                        |
| :-------------------------- | :------------------------------- | :----------------------------- |
| `ROUTING_BYPASS_ERROR`      | MANAGER executed directly        | Missing routing JSON           |
| `EXECUTION_PARALYSIS_ERROR` | MANAGER stopped after routing    | Routing JSON without execution |
| `MODE_VIOLATION_ERROR`      | Agent exceeded mode permissions  | Write in Ask mode              |
| `THINKING_OMISSION_ERROR`   | Supervisor missing thinking field | No `thinking_level` in Tier 1 JSON |
| `LANGUAGE_ERROR`            | Output language mismatch         | Non-EN input, English output   |
