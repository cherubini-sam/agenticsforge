#!/usr/bin/env bash
# PostToolUse hook: format modified Python files with black + isort.
# Non-blocking — warns on failure but never aborts agent flow.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

payload="$(cat || true)"
if [[ -z "$payload" ]]; then
  exit 0
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

case "$target" in
  *.py) : ;;
  *) exit 0 ;;
esac

# Prefer poetry-managed tools; fall back to system binaries.
if command -v poetry >/dev/null 2>&1 && [[ -f pyproject.toml ]]; then
  poetry run black --quiet "$target" >/dev/null 2>&1 || echo "format-code: black failed on $target" >&2
  poetry run isort --quiet "$target" >/dev/null 2>&1 || echo "format-code: isort failed on $target" >&2
else
  command -v black >/dev/null 2>&1 && black --quiet "$target" >/dev/null 2>&1 || true
  command -v isort >/dev/null 2>&1 && isort --quiet "$target" >/dev/null 2>&1 || true
fi

exit 0
