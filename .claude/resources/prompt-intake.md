---
description: "Strict template for the Phase 0 (b) prompt_intake.md artifact. PROTOCOL-owned. Captures the original user prompt, the Claude-optimized reformulation, token delta, fidelity score, session language, and the routing decision."
owner: PROTOCOL
target_path: "prompt_intake.md"
ephemeral: true
---

# Prompt Intake: {{Session Slug}}

> [!CRITICAL]
> **TERMINAL STATE**: This artifact is **EPHEMERAL**. HARD-DELETED at the close of Phase 6 alongside `task.md` and `implementation_plan.md`. Fresh per cycle on Workflow Re-entry. The permanent cross-cycle record is `walkthrough.md`.

> [!CRITICAL]
> **OWNERSHIP**: PROTOCOL is the sole author. No sub-agent delegation, no REFLECTOR cycle. Single inference step at Phase 0 (b).

> [!CRITICAL]
> **SCOPE GATE**: MANDATORY at Phase 0 (session start) and at Workflow Re-entry (post-P6 fresh cycle). FORBIDDEN mid-session during Phases 2–6 — mid-session user messages pass through verbatim.

## Language

- **Detected**: `<ISO-639-1 code, e.g. EN | IT | ES | FR>`
- **Persona Lock**: `SeniorPeer` — see `communication.md` §Persona Matrix
- **Source**: Phase 0 language detection on the Original prompt below.
- **Authority**: This value is the canonical source for every downstream agent and every Tier 1/2 JSON `persona` field for the entire P1→P6 cycle. Mid-cycle implicit drift = Language Drift anti-pattern → REGENERATE. Explicit user switch (e.g. `"switch to English"`, `"passa all'italiano"`) rewrites this field and resumes from the current phase.

## Original

```
{{Verbatim user prompt — byte-for-byte, no trimming, no paraphrase}}
```

## Reformulated

```xml
<goal>{{one-sentence goal}}</goal>
<scope>
  <in>{{in-scope items, bullet list}}</in>
  <out>{{explicitly out-of-scope items}}</out>
</scope>
<constraints>
  {{technical, security, time, dependency constraints resolved from the original}}
</constraints>
<acceptance>
  {{measurable acceptance criteria — Definition of Done}}
</acceptance>
<refs>
  {{files, functions, paths, error identifiers pulled from the original — never invented}}
</refs>
```

> Reformulation rules (hard):
>
> 1. Canonical structure + XML tags above — never decorative.
> 2. Strip zero-semantic tokens (greetings, hedging, filler, polite framing).
> 3. Target ≥30% token reduction when the original contains filler; 0% reduction allowed when already dense (return the original verbatim in that case).
> 4. Resolve `"this file"` / `"that function"` / `"the bug"` to concrete paths, symbols, or error identifiers. Never invent references.
> 5. Deterministic — identical input produces identical output. No synonym substitution, no creative rewording.
> 6. Language fidelity absolute — input language in → same language out. Never translate.

## Transformations

- [ ] Removed greetings / filler / hedging
- [ ] Disambiguated deictic references (`this`, `that`, `the bug`) to concrete paths/symbols
- [ ] Made implicit constraints explicit
- [ ] Normalized whitespace and structure
- [ ] Preserved all technical specifics (paths, errors, function names)
- [ ] Language preserved byte-for-byte (no translation)
- [ ] No scope drift, no new requirements, no new proper nouns

## Token Delta

| Metric                | Value                           |
| :-------------------- | :------------------------------ |
| `original_tokens`     | {{int}}                         |
| `reformulated_tokens` | {{int}}                         |
| `delta_pct`           | {{float, negative = reduction}} |

> **Rule:** if `delta_pct > 0` (reformulation is LONGER than original), reformulation is REJECTED and Decision is forced to `USE_ORIGINAL`.

## Fidelity Score

- **Score**: `{{0.00 – 1.00}}`
- **Added items** (MUST be empty for a valid reformulation):
  - {{list of anything in Reformulated that was not in Original}}
- **Lost items** (acceptable only if pure filler):
  - {{list of anything in Original that was dropped in Reformulated}}

## Decision

- [ ] `USE_REFORMULATED` — fidelity ≥ 0.9, token delta ≤ 0
- [ ] `USE_ORIGINAL` — fidelity 0.7–0.9, OR skip condition matched, OR token delta > 0, OR template load failed
- [ ] `HALT_FOR_CONFIRMATION` — fidelity < 0.7, OR `|delta_pct| > 40`, OR new proper noun / new file path appears that was not in the original

**Skip conditions** (force `USE_ORIGINAL`, reformulation bypassed):

- Prompt < 50 tokens
- Slash command invocation (`/commit`, `/review-pr`, ...)
- First token is a CLI/tool name
- Prompt contains `"verbatim"`, `"exact words"`, `"as-is"`, `"letterale"`, `"così com'è"`
- Single-word acknowledgment (`"proceed"`, `"yes"`, `"stop"`, `"continue"`, ...)

## Loaded Skills

> Populated by MANAGER after skill auto-load runs against `.claude/skills/index.json`. This section is the audit trail of which skills were resolved for the current cycle.

- {{skill_id}} — {{description}}
- ...

## Warnings

> Optional — only populated when PROTOCOL or MANAGER needs to surface a non-blocking advisory (e.g., skill-cap relaxation, template-load fallback, ambiguous language detection).

- ...

## Audit Trail

- **Created**: {{ISO-8601}}
- **Cycle**: {{N}}
- **Boot turn intent**: `boot_validation+prompt_intake`
