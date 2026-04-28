---
name: debugging
description: "Systematic debugging workflow: stack trace analysis, hypothesis-driven root cause investigation, bisection, and minimal-repro authoring. Use when diagnosing bugs, tracing failures, or analyzing exceptions."
when_to_use: "When diagnosing a specific bug from a stack trace, running git bisect to find a regression commit, reproducing a failure in isolation, or authoring a minimal repro for an intermittent failure."
allowed-tools: [Bash, Read, Grep]
---

# Debugging

Stack-neutral methodology aligned with the ENGINEER role. Map debugger commands and trace formats to the project's actual runtime.

## Foundations

Two canonical frames, equivalent in spirit:

- **Agans' 9 Rules.** (1) Understand the system, (2) Make it fail, (3) Quit thinking and look, (4) Divide and conquer, (5) Change one thing at a time, (6) Keep an audit trail, (7) Check the plug, (8) Get a fresh view, (9) If you didn't fix it, it ain't fixed.
- **Zeller's scientific method.** Debugging is falsification: hypothesis → experiment that would refute it → observe → refine. A bug is fixed only when its cause is **explained**, not when the symptom disappears.

## Observability-First

For any non-trivial production system, the *first* move is "open the trace," not "attach a debugger":

- **Distributed tracing** — OpenTelemetry spans across services. Pin the failure to a span; read the parent chain to recover the request context the debugger can no longer reach.
- **Continuous profiling** — Pyroscope, Parca, or vendor profilers (Datadog, Grafana). Compare flame graphs between a healthy and a degraded window — regression localises to the diverging stack.
- **Dynamic instrumentation** — eBPF (`bpftrace`, `bcc`, Pixie) for kernel- and syscall-level tracing without recompilation. Vendor equivalents: Datadog Dynamic Instrumentation, Honeycomb, Sentry breadcrumbs.
- **Time-travel** — `rr` (Linux), Replay.io (browser), Pernosco (cloud). Record once, replay deterministically, step backwards from the failure to its cause.
- **LLM/agent traces** — LangSmith, Langfuse, Anthropic console. Replay before patching prompt logic — most "model bugs" are wiring or tool-output drift, not code.

## 5-Step Process

1. **Reproduce** — minimal, isolated repro case.
2. **Isolate** — narrow to a single function, line, or condition.
3. **Hypothesize** — falsifiable cause.
4. **Test** — design an experiment that would refute it.
5. **Fix** — minimal change that removes the root cause.

Never skip to step 5. A fix without a confirmed hypothesis creates new bugs.

## Stack Trace Parsing

Convention varies, analysis is universal: the **innermost** frame raised the error; the **outermost** is the entry point. Re-order the chain mentally so it reads entry → failure site.

Key questions:

- What kind of failure (type mismatch, missing key, null deref, async-context violation)?
- Your code or a library? Library → check your inputs; your code → check the logic.
- What is the receiver / `this` / `self` at the failure point? Wrong type = upstream bug.

## Interactive Debugger

Use the language's native debugger (`breakpoint()` Python, `debugger;` JS/TS, `dlv` Go, `byebug`/`pry` Ruby, IDE breakpoints, `node --inspect`). Disable test-runner output capture so prompts reach the terminal (`pytest -s`, `jest --runInBand`, etc.).

Universal commands every debugger supports under some name:

| Action | Typical command |
| :--- | :--- |
| Step over | `next` / `n` |
| Step into | `step` / `s` |
| Return from current frame | `finish` / `r` |
| Print expression | `print <expr>` / `p <expr>` |
| List code | `list` / `l` |
| Backtrace | `backtrace` / `bt` |
| Quit | `quit` / `q` |

## Bisection

For regressions, find the culprit commit:

```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good>
# run the repro at each midpoint, mark good/bad until git names the commit
git bisect reset
```

## Structured Logging

Use the project's logging utility (never raw stdout). Emit structured records at:

- **Entry points** — the input parameters that drove execution.
- **Before risky operations** — the URL/query/payload about to be issued.
- **On unexpected state** — `WARNING` with the unexpected value and its source.

In tests, use the runner's log-capture helper (`caplog`, `console.spy`) to assert on log content rather than swallowing it.

## Common Root Cause Patterns

| Symptom | Likely Cause |
| :--- | :--- |
| Type mismatch on null/undefined | Function returned a null sentinel the caller didn't check. |
| Missing-key error | Lookup key from one source doesn't match another (type or case). |
| Index out of range | Empty collection not guarded. |
| Null-pointer / nil deref | Object construction failed silently upstream. |
| Async "no running event loop" / "await outside async" | Sync call inside async context (or vice versa). |
| Tests pass locally, fail in CI | Environment variable, locale, time zone, or path difference. |
| Intermittent failures | Race condition, timing dependency, or non-deterministic seed. |
| `NaN != NaN` paradox | NaN comparison — use the language's `isNaN`/`is_nan` helper. |

## Minimal Repro

A good repro has: no external services (mock or eliminate), no randomness (fix the seed), no project scaffolding (single file), and the exact failure message at the top. Share when asking for help; build first when isolating yourself.

## Source

Agans, Debugging: The 9 Indispensable Rules, 2002; Majors, Fong-Jones & Miranda, Observability Engineering, 2022.
