#!/usr/bin/env bash
# PostToolUse hook: run pytest on touched test files only.
# Non-blocking — emits warning on failure, never aborts tool chain.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

payload="$(cat || true)"
if [[ -z "$payload" ]]; then
  exit 0
fi

# Boot-gate validator — run on every PostToolUse invocation so hook/settings
# regressions surface immediately, regardless of the touched file type.
BOOT_VALIDATOR="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/tests/test_boot_gate.sh"
if [[ -x "$BOOT_VALIDATOR" ]]; then
  if ! "$BOOT_VALIDATOR" >&2; then
    echo "verify-tests: boot-gate validator FAILED" >&2
    exit 1
  fi
fi

target="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("input",{}).get("file_path",""))
except Exception:
    print("")' 2>/dev/null || true)"

if [[ -z "$target" || ! -f "$target" ]]; then
  exit 0
fi

# Only react to touched test files.
case "$target" in
  tests/*|*/tests/*) : ;;
  *) exit 0 ;;
esac

case "$target" in
  *.py) : ;;
  *) exit 0 ;;
esac

if command -v poetry >/dev/null 2>&1 && [[ -f pyproject.toml ]]; then
  if ! poetry run pytest -q "$target" >/dev/null 2>&1; then
    echo "verify-tests: pytest FAILED on $target" >&2
    exit 1
  fi
elif command -v pytest >/dev/null 2>&1; then
  if ! pytest -q "$target" >/dev/null 2>&1; then
    echo "verify-tests: pytest FAILED on $target" >&2
    exit 1
  fi
fi

exit 0
