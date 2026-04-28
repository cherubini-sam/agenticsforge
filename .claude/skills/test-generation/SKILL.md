---
name: test-generation
description: "Unit and integration test generation, language-agnostic. Use when writing new tests, expanding coverage, generating fixtures, or setting up the test infrastructure for any project regardless of stack."
when_to_use: "When writing new unit or integration tests, expanding coverage for an under-tested module, generating fixtures, setting up test infrastructure, or adding property-based or mutation testing layers."
allowed-tools: [Bash, Read]
---

# Test Generation

Stack-neutral patterns. Map to whichever runner the project uses (pytest, jest, vitest, go test, RSpec, JUnit, etc.).

## Foundations

- **TDD cycle (Beck).** Red → green → refactor. Smallest failing test → smallest passing change → refactor under green. Never skip red — a test that has never failed is unproven.
- **Test pyramid (Cohn).** Many fast unit tests, fewer integration, very few end-to-end. The inverted "ice-cream cone" is slow, flaky, expensive.
- **Four-phase test (Meszaros).** *Setup → Exercise → Verify → Teardown*. Group by concern, not by source-file mirror.
- **Test smells (Meszaros).** Watch for Obscure Test, Fragile Test, Conditional Test Logic, Test Code Duplication, Slow Tests.
- **Tests as documentation.** Names specify behaviour, not implementation. `test_returns_failure_after_max_retries` documents a contract; `test_calls_retry_three_times` rots.

## Beyond the Pyramid

Example-based tests (the patterns above) cover the cases the author thought of. Three orthogonal layers extend coverage:

- **Property-based testing.** Hypothesis (Python), fast-check (JS/TS), QuickCheck/Hedgehog (Haskell), jqwik (Java), `proptest` (Rust). Specify *invariants* — "for all inputs in this range, property P holds" — and let the framework generate adversarial inputs including shrunk minimal counter-examples. Especially powerful for parsers, encoders, state machines, and any code with a round-trip identity (`decode(encode(x)) == x`).
- **Mutation testing.** Stryker (JS/TS, C#, Scala), `mutmut`/`cosmic-ray` (Python), PIT (JVM). Validates that your test suite *would actually catch a bug*: the tool perturbs the production code, re-runs the tests, and reports which mutants survived. A 100%-coverage suite with low mutation score is a false sense of security.
- **Contract testing.** Pact, Spring Cloud Contract. For service boundaries, codify the contract as a shared artefact; consumer and provider verify against it independently. Replaces brittle end-to-end tests for inter-service correctness.
- **LLM-assisted test generation.** Agents produce candidate tests; mutation testing evaluates whether they actually exercise behaviour. Never ship LLM-generated tests without a mutation-score gate — they are prone to tautologies (asserting what the code did, not what it should do).

## Directory Layout

```
tests/
  shared/                       # shared fixtures, factories, markers
  unit/<module>.test.<ext>      # mirror source tree
  integration/<module>.test.<ext>
```

## Naming

- **File:** mirrors source path with a test qualifier (`<module>.test.<ext>` or sibling `tests/unit/<module>`).
- **Group:** `Test<ModuleName><Concern>` — class in OO, `describe` in JS-style, function group elsewhere. One group per concern (Success / Retry / Error).
- **Case:** `test_<expected_behaviour>` — outcome, not implementation.

## Fixtures

Use the runner's native fixture/setup mechanism with **session scope** for expensive shared resources (DB, browser, large data). Tear down in reverse order. Register an `integration` marker (or equivalent tag) so unit-only runs can exclude it.

## Parametrised / Table-Driven Tests

For one assertion across many inputs, use parametrised tests (`parametrize`, `it.each`, table-driven `t.Run`):

```text
parametrise status in [408, 429, 500, 502, 503, 504]:
  test_retries_on_retryable_transport_error(status)
```

## Async

Use the runner's async mode (auto-detection or `async/await` support). Configure once in the runner; never decorate per-test.

## Mocking — Two Universal Rules

1. **Never let real delays run.** Stub the sleep/timer primitive in retry tests; assert call count, not wall-clock time.
2. **Never mutate process environment directly.** Use the runner's environment-isolation helper (`monkeypatch`, scoped `setenv`) so tests cannot leak state.

## Assertions

For retry tests, assert BOTH the **return value** AND the **call count**:

```text
result = service.call_with_retry()
assert result is failure_sentinel
assert transport.call_count == RETRY_COUNT
```

## Integration Tests

Tag with `@integration` (or equivalent). Pre-commit excludes them; CI runs unit + integration.

## Quality Gates

- Every source module has a corresponding test file.
- Priority: utilities/shared libs → business logic → integration points.
- Tests pass in pre-commit and CI.
- Coverage threshold project-defined; enforce via the runner's coverage tool.

## Source

Beck, Test-Driven Development: By Example, 2002; MacIver, Hypothesis: A New Approach to Property-Based Testing (JOSS), 2019.
