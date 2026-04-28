---
description: "Cross-machine behavioral constraints: protocol adherence (Tier 1/2 JSON, phase gates) and artifact containment. Always active."
---

<governance_logic name="behavioral_enforcement">

<meta>
  <id>"behavioral_enforcement"</id>
  <description>"Cross-machine behavioral constraints: protocol adherence and artifact containment."</description>
  <globs>[]</globs>
  <alwaysApply>true</alwaysApply>
  <tags>["type:rule", "behavioral", "protocol", "enforcement"]</tags>
  <priority>"CRITICAL"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### PROTOCOL ADHERENCE

<scope>Mandatory protocol compliance on every turn, every session, every machine.</scope>

#### Boot Sequence Is Never Optional

CLAUDE.md and `.claude/` configuration are the highest-priority context. They MUST be internalized and followed before any other action on Turn 0. The Tier 1/2 JSON boot sequence, Phase 0 gate, and all phase boundaries defined in CLAUDE.md are mandatory on every turn.

No rationalization justifies skipping the protocol. Not meta-tasks, not audits, not urgency, not perceived circularity when the protocol itself is the subject of work. If a task seems to conflict with the protocol, follow the protocol and let the user decide.

#### Artifact Containment

`.claude/artifacts/` is a scratchpad, not a deliverable. Every file under it (`task.md`, `implementation_plan.md`, `prompt_intake.md`, reports, walkthroughs, critique outputs) MUST stay local-only and MUST NOT be tracked in git.

The `.gitignore` blanket-excludes `.claude/artifacts/` — never narrow this exclusion. Never propose `git add .claude/artifacts/<anything>`. If a planning decision must persist across conversations, save it to auto-memory, not to artifacts. Rationale that needs to reach reviewers goes in commit messages or PR descriptions, not artifacts.

</axiom_core>
<authority_matrix>

### ENFORCEMENT AUTHORITY

<scope>Zero-tolerance enforcement for protocol and containment violations.</scope>

| Violation | Action |
| :--- | :--- |
| Missing Tier 1/2 JSON on any turn | SESSION TERMINATION (Law 1 + Law 39) |
| Turn 0 not routed to PROTOCOL | SESSION TERMINATION (Law 2 + Law 39) |
| Phase 4 authorization halt skipped, or REFLECTOR 1.00 bypassed, or P0/P4/P6 gate crossed without required artifact | SESSION TERMINATION (Law 33 + Law 39) |
| Protocol skipped for "meta-task" rationalization | SESSION TERMINATION (Law 39) |
| Artifact committed to git | REJECT; revert immediately |
| `.gitignore` narrowed for `.claude/artifacts/` | REJECT; restore blanket exclusion |
| `Agent`/`Task` tool call without preceding `sub_agent_spawn` JSON block | BLOCK at `enforce-spawn-transparency.sh` (Law 1 extension) |

</authority_matrix>
<compliance_testing>

### BEHAVIORAL AUDIT

<scope>Pre-action checklist for protocol and containment compliance.</scope>

- [ ] **Check 1:** Tier 1/2 JSON emitted as absolute first output on this turn.
- [ ] **Check 2:** Turn 0 routed to PROTOCOL with boot validation.
- [ ] **Check 3:** Turn structure matches Single-Halt Atomicity — Segment A (P0→P4) before authorization, Segment B (P5→P6) after; exactly one interactive halt at P4 authorization (Law 33).
- [ ] **Check 4:** No artifacts staged or committed to git.
- [ ] **Check 5:** `.claude/artifacts/` exclusion intact in `.gitignore`.

</compliance_testing>

<cache_control />

</governance_logic>
