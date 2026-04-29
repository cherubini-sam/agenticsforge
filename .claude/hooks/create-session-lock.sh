#!/usr/bin/env bash
# PostToolUse hook: create .session-lock atomically with prompt_intake.md write.
#
# Closes the gap where session-bootstrap.sh purges in-progress artifacts when a
# context compaction or session restart fires between P0(b) (prompt_intake.md
# written) and the P1 agent step that previously ran `touch .session-lock`.
#
# Triggers on Write|Edit|MultiEdit. No-op unless the affected path is
# .claude/artifacts/prompt_intake.md. Idempotent — touch is safe to re-run.
#
# Exit 0 always: lock creation must never block the agent. Errors are logged
# to stderr but do not abort the session.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

payload="$(cat || true)"
[[ -z "$payload" ]] && exit 0

target="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    i=d.get("tool_input") or d.get("input") or {}
    print(i.get("file_path") or "")
except Exception:
    print("")' 2>/dev/null || true)"

case "$target" in
  */.claude/artifacts/prompt_intake.md|.claude/artifacts/prompt_intake.md) ;;
  *) exit 0 ;;
esac

LOCK="${PROJECT_DIR}/.claude/artifacts/.session-lock"
mkdir -p "$(dirname "$LOCK")"
touch "$LOCK" && echo "create-session-lock: .session-lock created (P0b prompt_intake.md write confirmed)." >&2 || \
  echo "create-session-lock: WARNING — failed to create .session-lock at $LOCK" >&2

exit 0
