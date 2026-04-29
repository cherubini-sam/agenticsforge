---
description: "Hygiene, formatting, and implementation standards: language lock (Law 18), zero-fluff output, code standards, artifact schema. Always active."
---

### STYLE AXIOMS

> Core language, formatting, and code hygiene standards governing all agent output and artifact generation.

#### Language (Law 18)

Session language is detected at Phase 0 and locked for the entire P1→P6 cycle. Canonical source: `communication.md` §Multilingual Persona Matrix. Persona is always SeniorPeer; output language matches the user's detected input language — see Persona Matrix for the `<LANG>-SeniorPeer` enum pattern. Structural exemption for Tier 1/2 JSON, code identifiers, comments, commit messages, and CLI commands (always canonical English). Mid-cycle implicit drift = **Language Drift** → REGENERATE in locked language. Explicit user switch rewrites `prompt_intake.md` and resumes from current phase.

#### Formatting (Law 19)

Zero Fluff. `thinking_process` tag MANDATORY for complex reasoning and multi-tool logic. No emojis in source code, filenames, or system artifacts. Standard: GitHub Flavored Markdown (GFM). Bypass: UI mockup generation or explicitly creative requests.

#### Code Standards

Type hints mandatory (static analysis compatibility). Docstrings: Google Style. `try/except` required on all file and network I/O. Prohibited: `pass`, `TODO`, commented-out blocks, `...` markers in production. Delete old files immediately after successful refactor.

### ARTIFACT AUTHORITY

> Enforcement hierarchy for artifact schema compliance and coding standard violation handling.

#### Artifact Schema (Law 33)

Scope: `task.md` and `implementation_plan.md` in the artifact sandbox. H2 (`##`) for major logical sections. Checkbox syntax (`- [ ]` pending, `- [x]` complete) for status. Plan updates MUST append a "Revision History" section — never truncate design history. REJECT update if structural hierarchy is broken or history is truncated.

#### Violation Consequences

| Violation | Action |
| :--- | :--- |
| Language mismatch | REGENERATE in correct language; LOG WARNING |
| Emoji in critical path | LOG WARNING + strip |
| Placeholder / pass-zombie in production | HALT execution; DENY commit |
| Artifact hierarchy or history broken | REJECT update |

### STYLE AUDIT

> Pre-output checklist to enforce hygiene standards on every agent turn.

- [ ] **Check 1:** Output language matches session language (Law 18).
- [ ] **Check 2:** No emojis in code, filenames, or system artifacts (Law 19).
- [ ] **Check 3:** No TODO / TBD / `...` / `pass` in production code (Law 11).
- [ ] **Check 4:** Artifact hierarchy uses H2 + checkbox syntax (Law 33).
