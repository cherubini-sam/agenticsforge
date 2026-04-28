---
name: refactoring
description: "Coverage-first safe refactoring: extract method, rename, DRY consolidation, dependency injection. Use when improving code structure, eliminating duplication, or restructuring modules without changing behavior."
---

# Refactoring

Coverage-first: establish a test baseline before touching production code. Stack-neutral; map commands to the project's tooling.

## Foundations

- **Definition (Fowler).** *Refactoring* preserves external behaviour. If the diff changes behaviour, it is a feature change, not a refactor.
- **Two Hats (Fowler).** At any moment you are either *adding capability* or *refactoring* — never both in one commit.
- **Tidy First (Beck).** Separate small "tidyings" from substantive changes; merge tidyings ahead so review focuses on the lines that actually matter.
- **Legacy = no tests (Feathers).** Before touching legacy code, add a *characterisation test* that pins current behaviour — even if wrong. Then it is safe to change.
- **Refactor under green.** Tests pass before, between every step, and after. A failing test mid-refactor is a signal to revert, not to debug.

## Pre-Refactor Checklist

- [ ] Run the existing test suite — confirm all pass.
- [ ] Record baseline coverage via the runner's coverage tool.
- [ ] `git stash` or commit current state — safety net.
- [ ] Identify the target: function / class / module / pattern.

## Core Patterns

### Extract Method

When a function does more than one thing, split each concern into its own function. The caller becomes a sequence of named steps; each step is independently testable.

### Rename / Move

- Rename to match the project's naming convention.
- Move to the correct layer in the dependency flow (e.g. `globals ← systems ← utilities ← integrations ← domain ← entry point`).
- Search all usages **before** AND **after** the rename — confirm zero zombies.

### DRY Consolidation

When the same logic appears in 3+ places: identify variation points, extract a shared utility parameterised on those points, replace call sites, run tests. If any test fails, the abstraction captured wrong assumptions — revert and reconsider.

### Dependency Injection

Replace hardcoded dependencies with constructor (or factory) injection so tests can swap them. Default the parameter to the production implementation; tests pass a stub.

### Constants Extraction

Move inline magic values to a dedicated constants module (`globals/`, `constants/`, `config/`):

```text
// Before
if (retryCount > 3) sleep(5)

// After
SERVICE_RETRY_MAX   = 3
SERVICE_RETRY_DELAY = 5.0
if (retryCount > SERVICE_RETRY_MAX) sleep(SERVICE_RETRY_DELAY)
```

## Post-Refactor Verification

1. Test suite passes.
2. Coverage matches or exceeds the recorded baseline.
3. Search all references to the old symbol — confirm zero remaining.
4. `git diff HEAD` shows only structural changes, no logic changes.

## Programmatic Refactoring

Manual refactoring does not scale past a few hundred files. The 2025 stack:

- **AST codemod tools** — OpenRewrite (JVM, multi-language recipes), `jscodeshift` / `ts-morph` (JS/TS), `bowler` / `LibCST` (Python), `ruff --fix` (Python lints/refactors), `gofmt` + `gopls` (Go). A recipe is reviewable code; running it across N repos is one CI job.
- **Strangler fig (Fowler — now dominant)** — route a subset of traffic to the new implementation behind a feature flag; grow the new path until the old is dead; remove. Never big-bang.
- **Type-system migrations** — `mypy --strict` ratcheting, TypeScript `strict: true` per-file, Sorbet. Add types module-by-module behind a CI gate that prevents regression.
- **Behavioural code analysis** — Tornhill hotspot maps (`code-maat`, CodeScene): focus effort on files that change frequently AND have high complexity. Refactoring a stable module is wasted effort.
- **LLM-assisted** — acceptable for mechanical transforms (rename, extract, format) under a passing test suite. NEVER acceptable without tests — the LLM will silently change behaviour.

## Law 16 — Legacy Code Purge

After a successful refactor, immediately delete the old function/class/file (never leave it commented out), drop dead imports, and delete the source file if empty.

## When NOT to Refactor

- No tests cover the code → add a characterisation test first (Feathers).
- Under time pressure → mark as tech debt, create a task.
- The change is actually a behaviour change → that is a feature, not a refactor (Fowler's Two Hats).

## Source

Fowler, Refactoring, 2nd ed., 2018; Tornhill, Your Code as a Crime Scene, 2nd ed., 2024.
