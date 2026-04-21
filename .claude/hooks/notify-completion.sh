#!/usr/bin/env bash
# Stop hook: fire desktop notification on agent turn completion.
# OS-guarded — Darwin uses osascript, Linux uses notify-send, other = no-op.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TITLE="Claude Code"
MSG="Agent turn complete — $(basename "$PROJECT_DIR")"

os="$(uname -s 2>/dev/null || echo unknown)"
case "$os" in
  Darwin)
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "display notification \"$MSG\" with title \"$TITLE\"" >/dev/null 2>&1 || true
    fi
    ;;
  Linux)
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "$TITLE" "$MSG" >/dev/null 2>&1 || true
    fi
    ;;
  *) : ;;
esac

exit 0
