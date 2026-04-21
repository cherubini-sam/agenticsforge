---
name: refactoring
description: "Coverage-first safe refactoring: extract method, rename, DRY consolidation, dependency injection. Use when improving code structure, eliminating duplication, or restructuring modules without changing behavior."
---

# Refactoring

Coverage-first approach: always establish a test baseline before touching production code.

## Pre-Refactor Checklist

- [ ] Run existing tests, confirm all pass — `pytest tests/`
- [ ] Check current coverage — `pytest --cov=src tests/`
- [ ] Commit or stash current state — `git stash` (safety net)
- [ ] Identify the refactoring target: function / class / module / pattern

## Core Refactoring Patterns

### Extract Method
When a function is too long or does more than one thing:

```python
# Before: mixed concerns in one function
def process(data):
    # validation
    if not data: raise ValueError(...)
    # transformation
    result = [transform(x) for x in data]
    # output
    write_to_file(result)

# After: each concern in its own function
def validate_input(data): ...
def transform_data(data): ...
def write_output(data): ...

def process(data):
    validate_input(data)
    result = transform_data(data)
    write_output(result)
```

### Rename / Move
- Rename to match the `<package>_<concern>_<action>` naming convention
- Move to the correct layer in the dependency flow (`globals ← systems ← utilities ← clouds/drivers ← domain ← main`)
- Update all import sites after rename — search with Grep before and after

### DRY Consolidation
When the same logic appears in 3+ places:

1. Identify the shared pattern and its variation points
2. Extract to a shared utility with parameters for the variation
3. Replace all call sites
4. Run tests — if any fail, the abstraction captured wrong assumptions

### Dependency Injection
Replace hardcoded dependencies with constructor injection:

```python
# Before: hardcoded dependency
class ServiceClient:
    def __init__(self):
        self.session = requests.Session()  # hardcoded

# After: injected dependency
class ServiceClient:
    def __init__(self, session: requests.Session | None = None):
        self.session = session or requests.Session()  # injectable for testing
```

### Constants Extraction
Move inline magic values to `globals/globals_<concern>.py`:

```python
# Before
if retry_count > 3:
    time.sleep(5)

# After — in globals/globals_service.py
SERVICE_RETRY_MAX: int = 3
SERVICE_RETRY_DELAY: float = 5.0

# In business logic
if retry_count > SERVICE_RETRY_MAX:
    time.sleep(SERVICE_RETRY_DELAY)
```

## Post-Refactor Verification

```bash
# 1. Tests still pass
pytest tests/

# 2. Coverage not regressed
pytest --cov=src --cov-report=term-missing tests/

# 3. No dead code left behind
grep -r "def old_function_name" src/  # should return 0 results

# 4. Review the diff — confirm only structural changes, no logic changes
git diff HEAD
```

## Law 16 — Legacy Code Purge

After a successful refactor:
- Delete the old function/class/file immediately — never leave it commented out
- Delete old imports — no zombie references
- If the old code is in a different module, delete the entire file if now empty

## Safe Rename Protocol

1. Grep for all usages: `grep -r "old_name" src/ tests/`
2. Make the change
3. Grep again to confirm 0 remaining references
4. Run tests

## When NOT to Refactor

- When there are no tests covering the code (add tests first)
- When the change is under time pressure (mark as tech debt, create a task)
- When "refactor" is actually a behavior change (that's a feature, not a refactor)
