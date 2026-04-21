---
name: test-generation
description: "Unit and integration test generation for Python projects using pytest. Use when writing new tests, expanding coverage, generating fixtures, or setting up the test infrastructure."
---

# Test Generation

Generates pytest-based tests following protocol naming and structure conventions.

## Directory Layout

```
tests/
  conftest.py              # Session-scoped fixtures, markers
  unit/
    test_<module_name>.py  # Unit tests — mirror src/ structure
  integration/
    test_<module_name>.py  # Integration tests — require live services
```

## Naming Conventions

### File Naming
`test_<package>_<concern>.py` mirrors `src/<package>/<package>_<concern>.py`.

### Class Naming
`Test<ModuleName><Concern>` — one class per logical concern:
```python
class TestServiceClientSuccess:      # happy path
class TestServiceClientRetry:        # retry behavior
class TestServiceClientError:        # error/edge cases
```

### Method Naming
`test_<expected_behavior>` — name the outcome, not the implementation:
```python
def test_returns_value_on_first_try(self):
def test_retries_on_retryable_http_error(self, status):
def test_no_retry_on_logic_errors(self, exc_class):
def test_exhausted_retries_returns_none(self):
```

## Fixture Patterns

```python
# conftest.py — session-scoped for expensive shared resources
@pytest.fixture(scope="session")
def db_connection():
    conn = create_connection()
    yield conn
    conn.close()

# Integration marker registration
def pytest_configure(config):
    config.addinivalue_line("markers", "integration: requires live external services")
```

## Parametrize Pattern

```python
@pytest.mark.parametrize("status", [408, 429, 500, 502, 503, 504])
def test_retries_on_retryable_http_error(self, status):
    ...

@pytest.mark.parametrize("exc_class", [TypeError, ValueError, NameError])
def test_no_retry_on_logic_errors(self, exc_class):
    ...
```

## Async Test Mode

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
```

Async test functions are auto-detected — no `@pytest.mark.asyncio` decorator needed.

## Mocking Patterns

```python
# Patch time.sleep in retry tests — never let real delays run
@patch("time.sleep")
def test_exponential_backoff(self, mock_sleep):
    ...
    assert mock_sleep.call_count == expected_retries

# Monkeypatch for environment variables — never modify os.environ directly
def test_reads_env_var(self, monkeypatch):
    monkeypatch.setenv("MY_VAR", "test_value")
    ...
```

## Assertions

Always assert both **return value** AND **call count** for retry tests:
```python
result = service.call_with_retry()
assert result is None                          # exhausted retries → None
assert mock_api.call_count == RETRY_COUNT      # correct retry count
```

## Integration Test Pattern

```python
@pytest.mark.integration
class TestServiceClientIntegration:
    def test_real_api_call_returns_data(self):
        ...
```

Pre-commit hooks run unit tests only (`-m "not integration"`). CI runs both.

## Quality Gates

- Every source module MUST have a corresponding test file
- Priority: utilities/shared libs → business logic → integration points
- Tests MUST pass in pre-commit hook chain and CI pipeline
