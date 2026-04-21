---
description: "Hygiene, formatting, and implementation standards: language lock (Law 18), zero-fluff output, code standards, artifact schema. Always active."
---

<governance_logic name="style">

<meta>
  <id>"style"</id>
  <description>"Hygiene, formatting, and implementation standards for artifacts and code."</description>
  <globs>[]</globs>
  <alwaysApply>true</alwaysApply>
  <tags>["type:rule", "style", "formatting", "hygiene"]</tags>
  <priority>"HIGH"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### STYLE AXIOMS

<scope>Core language, formatting, and code hygiene standards governing all agent output and artifact generation.</scope>

#### Language (Law 18)

Session language is detected at Phase 0 and locked for the entire P1→P6 cycle. Canonical source: `communication.md` §Multilingual Persona Matrix. Each language maps to a role voice (e.g. EN = Senior Peer, IT = Senior Mentor — see Persona Matrix for all). Structural exemption for Tier 1/2 JSON, code identifiers, comments, commit messages, and CLI commands (always canonical English). Mid-cycle implicit drift = **Language Drift** → REGENERATE in locked language. Explicit user switch rewrites `prompt_intake.md` and resumes from current phase.

#### Formatting (Law 19)

Zero Fluff. `thinking_process` tag MANDATORY for complex reasoning and multi-tool logic. No emojis in source code, filenames, or system artifacts. Standard: GitHub Flavored Markdown (GFM). Bypass: UI mockup generation or explicitly creative requests.

#### Code Standards

Type hints mandatory (static analysis compatibility). Docstrings: Google Style. `try/except` required on all file and network I/O. Prohibited: `pass`, `TODO`, commented-out blocks, `...` markers in production. Delete old files immediately after successful refactor.

</axiom_core>
<authority_matrix>

### ARTIFACT AUTHORITY

<scope>Enforcement hierarchy for artifact schema compliance and coding standard violation handling.</scope>

#### Artifact Schema (Law 33)

Scope: `task.md` and `implementation_plan.md` in the artifact sandbox. H2 (`##`) for major logical sections. Checkbox syntax (`- [ ]` pending, `- [x]` complete) for status. Plan updates MUST append a "Revision History" section — never truncate design history. REJECT update if structural hierarchy is broken or history is truncated.

#### Violation Consequences

| Violation | Action |
| :--- | :--- |
| Language mismatch | REGENERATE in correct language; LOG WARNING |
| Emoji in critical path | LOG WARNING + strip |
| Placeholder / pass-zombie in production | HALT execution; DENY commit |
| Artifact hierarchy or history broken | REJECT update |

</authority_matrix>
<compliance_testing>

### STYLE AUDIT

<scope>Pre-output checklist to enforce hygiene standards on every agent turn.</scope>

- [ ] **Check 1:** Output language matches session language (Law 18).
- [ ] **Check 2:** No emojis in code, filenames, or system artifacts (Law 19).
- [ ] **Check 3:** No TODO / TBD / `...` / `pass` in production code (Law 11).
- [ ] **Check 4:** Artifact hierarchy uses H2 + checkbox syntax (Law 33).

</compliance_testing>

<cache_control />

</governance_logic>
