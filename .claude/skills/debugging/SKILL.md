---
name: debugging
description: "Systematic debugging workflow: stack trace analysis, hypothesis-driven root cause investigation, bisection debugging, and structured error reproduction. Use when diagnosing bugs, tracing failures, or analyzing exceptions."
---

# Debugging

Systematic 5-step debugging methodology aligned with the ENGINEER agent role.

## The 5-Step Process

1. **Reproduce** — create a minimal, isolated reproduction case
2. **Isolate** — narrow the failure to a single function, line, or condition
3. **Hypothesize** — form a falsifiable hypothesis about the root cause
4. **Test** — write code or run commands that would disprove the hypothesis
5. **Fix** — apply the minimal change that eliminates the root cause

Never skip to step 5. A fix without a confirmed hypothesis creates new bugs.

## Stack Trace Parsing

Read bottom-up — the last frame is where the exception was raised; the top is the entry point.

```
Traceback (most recent call last):         ← entry point (read last)
  File "src/main.py", line 42, in main
    result = service.process(data)
  File "src/service.py", line 18, in process
    return client.fetch(url)               ← root call site
  File "src/client.py", line 67, in fetch  ← exception raised here
    raise ConnectionError(...)
ConnectionError: timeout after 30s         ← exception type + message
```

Key questions:
- What type is the exception? (`TypeError` = wrong type, `KeyError` = missing key, `AttributeError` = wrong object)
- Is this your code or a library? (library = check your inputs; your code = check the logic)
- What is `self` / `cls` at the failure point? (wrong type passed = upstream bug)

## pdb / breakpoint() Usage

```python
# Drop into debugger at a specific line
breakpoint()   # Python 3.7+ preferred over import pdb; pdb.set_trace()

# In pytest: use -s to prevent output capture
pytest tests/unit/test_service.py -s -k "test_failing_case"
```

Common pdb commands:
| Command | Action |
|---------|--------|
| `n` | Next line (step over) |
| `s` | Step into function |
| `r` | Return from function |
| `p expr` | Print expression |
| `pp expr` | Pretty-print |
| `l` | List surrounding code |
| `bt` | Full backtrace |
| `q` | Quit |

## Bisection Debugging

For regressions: use `git bisect` to find the commit that introduced the bug.

```bash
git bisect start
git bisect bad HEAD           # current commit is broken
git bisect good <known-good>  # last known working commit
# git checks out midpoint — run your test, then:
git bisect bad   # or: git bisect good
# repeat until git identifies the culprit commit
git bisect reset
```

## Structured Logging for Debugging

```python
import logging
logger = logging.getLogger(__name__)

# At entry points:
logger.debug("Processing item: id=%s state=%s", item_id, state)

# Before risky operations:
logger.debug("Calling API: url=%s params=%s", url, params)

# On unexpected state:
logger.warning("Unexpected None from %s: input=%r", func.__name__, input_val)
```

Never use `print()` in production — use the logging utility. In tests, `caplog` fixture captures log output.

## Common Root Cause Patterns

| Symptom | Likely Cause |
|---------|-------------|
| `TypeError: NoneType` | Function returned `None` that caller didn't check |
| `KeyError` | Dict key from one source doesn't match another (type or case) |
| `IndexError` | Empty list not guarded |
| `AttributeError: 'NoneType'` | Object construction failed silently |
| Async `RuntimeError: no running event loop` | Sync call inside async context |
| Tests pass locally, fail in CI | Environment variable or path difference |
| Intermittent failures | Race condition, timing dependency, or random seed |
| `float('nan') != float('nan')` | NaN comparison — use `math.isnan()` |

## Minimal Reproduction Template

```python
# minimal_repro.py — share this when asking for help
import <minimal imports>

# The exact inputs that trigger the bug
input_data = ...

# The function under test
result = function_under_test(input_data)

# What you expected vs what you got
print(f"Expected: {expected}")
print(f"Got:      {result}")
```
