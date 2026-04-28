---
description: "Implementation Plan Template for Phase 3 (Planning). Required by MANAGER Phase 3 Gate before routing to ENGINEER."
owner: ARCHITECT
target_path: "implementation_plan.md"
ephemeral: true
---

# Implementation Plan: {{Task Name}}

> [!CRITICAL]
> **TERMINAL STATE**: This artifact is **EPHEMERAL**. It is HARD-DELETED at the close of Phase 6 alongside `task.md`. The permanent record of what happened is `walkthrough.md` (append-only, cross-cycle). Never archive `implementation_plan.md`; never commit it; never reference it from tracked files.

> [!CRITICAL]
> **PHASE 3 GATE**: This artifact MUST exist and be REFLECTOR-approved (Score: 1.00) before MANAGER can route to ENGINEER.
> If missing → MANAGER MUST route to ARCHITECT (Force Phase 3).

## OBJECTIVE

- **Goal**: [What is being built / changed]
- **Scope**: [What is in scope vs. explicitly out of scope]
- **Constraints**: [Technical, security, time, dependency constraints]

## CURRENT STATE ANALYSIS

- **Existing Behavior**: [What the system does today]
- **Gap**: [What is missing or broken]
- **Root Cause** (if applicable): [Why the gap exists]

## PROPOSED SOLUTION

### Architecture Decision

[High-level design decision and rationale. Include alternatives considered and why they were rejected.]

### Implementation Steps

- [ ] **Step 1**: [Action] — [File/Component affected] — [Expected outcome]
- [ ] **Step 2**: [Action] — [File/Component affected] — [Expected outcome]
- [ ] **Step 3**: [Action] — [File/Component affected] — [Expected outcome]

> Add as many steps as needed. Each step must be atomic (one action, one outcome).

### Files to Modify

| File | Change Type | Description |
| :--- | :---------- | :---------- |
| `path/to/file` | [create\|modify\|delete] | [What changes and why] |

### Files to Create

| File | Purpose |
| :--- | :------ |
| `path/to/new/file` | [What it does] |

## VERIFICATION STRATEGY

- **Unit Tests**: [What to test, where]
- **Integration Tests**: [End-to-end scenarios to verify]
- **Manual Checks**: [Steps to manually validate the implementation]
- **Rollback Plan**: [How to undo changes if validation fails]

## RISK ASSESSMENT

| Risk | Likelihood | Impact | Mitigation |
| :--- | :--------- | :----- | :--------- |
| [Risk description] | [Low\|Med\|High] | [Low\|Med\|High] | [Mitigation strategy] |

## REFLECTOR APPROVAL

- **Submitted By**: ARCHITECT
- **Review Status**: [ ] Pending / [ ] Approved / [ ] Rejected
- **Confidence Score**: [0.00 – 1.00] (must be 1.00 to proceed)
- **Review Notes**: [REFLECTOR findings and required changes]

## AUDIT TRAIL

- **Plan Created**: [ISO-8601 timestamp]
- **Last Updated**: [ISO-8601 timestamp]
- **Authorized By**: [User confirmation timestamp]
