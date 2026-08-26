#!/usr/bin/env bash
# Project-local hook resolver — NO global fallback (layer detachment is a correctness property).
# Called by the bash -c wrapper in .claude/settings.json "command" strings.
#
# $1 = hook filename (basename only, e.g. "session-bootstrap.sh")
# Resolution: searches ONLY "${CLAUDE_PROJECT_DIR:-$PWD}/.claude/hooks/<hook>".
# If found: exec it. If absent: exit 0 (silent skip).
set -euo pipefail

HOOK_NAME="${1:-}"
if [[ -z "$HOOK_NAME" ]]; then
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
HOOK_PATH="$ROOT/.claude/hooks/$HOOK_NAME"

if [[ -f "$HOOK_PATH" ]]; then
  exec bash "$HOOK_PATH" "${@:2}"
fi

exit 0
