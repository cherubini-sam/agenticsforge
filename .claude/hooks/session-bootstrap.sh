#!/usr/bin/env bash
# SessionStart hook: verify canonical project layout before any agent turn runs.
# Supports both project-local and global (~/.claude/) installation.
# Exit 0 = proceed; Exit 1 = warn (non-blocking); Exit 2 = block session.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Self-heal: ensure all hooks have execute permissions.
# Write tool creates files without the execute bit; this idempotent guard
# prevents any hook from silently failing due to a missing +x.
chmod +x "$(dirname "$0")"/*.sh "$PROJECT_DIR/.claude/hooks"/*.sh 2>/dev/null || true

# Resolve config directory (project-first, global fallback).
# shellcheck source=_resolve-config-dir.sh
source "$(dirname "$0")/_resolve-config-dir.sh"

# CLAUDE.md must exist at project root OR at ~/.claude/CLAUDE.md.
if [[ ! -f "$PROJECT_DIR/CLAUDE.md" && ! -f "$HOME/.claude/CLAUDE.md" ]]; then
  echo "session-bootstrap: MISSING CLAUDE.md (checked $PROJECT_DIR and $HOME/.claude/)" >&2
  exit 2
fi

# Required dirs are validated at CLAUDE_CONFIG_DIR (may be project or global).
REQUIRED_DIRS=(
  "protocols"
  "rules"
  "agents"
  "resources"
  "skills"
  "hooks"
)

missing=0
for d in "${REQUIRED_DIRS[@]}"; do
  target="$CLAUDE_CONFIG_DIR/$d"
  if [[ ! -d "$target" ]]; then
    echo "session-bootstrap: MISSING DIR $target" >&2
    missing=1
  fi
  if [[ -d "$target" && ! -w "$target" ]]; then
    echo "session-bootstrap: NOT WRITABLE $target" >&2
    missing=1
  fi
done

if [[ $missing -ne 0 ]]; then
  echo "session-bootstrap: layout violation — BLOCKING session" >&2
  exit 2
fi

# Ensure artifact sandbox is ready (always project-local, never tracked).
mkdir -p "$CLAUDE_ARTIFACT_DIR"

# Stale-artifact purge — Phase 0 must run fresh every session unless a live,
# recent cycle lock exists. TTL 24h protects against abandoned locks.
LOCK="$CLAUDE_ARTIFACT_DIR/.session-lock"
if [[ -f "$LOCK" ]]; then
  if find "$LOCK" -mmin +1440 -print 2>/dev/null | grep -q .; then
    rm -f "$LOCK"
    echo "session-bootstrap: .session-lock older than 24h — treated as abandoned, removed." >&2
  fi
fi

if [[ ! -f "$LOCK" ]]; then
  rm -f "$CLAUDE_ARTIFACT_DIR/prompt_intake.md" \
        "$CLAUDE_ARTIFACT_DIR/task.md" \
        "$CLAUDE_ARTIFACT_DIR/implementation_plan.md" 2>/dev/null || true
  echo "session-bootstrap: purged stale Phase 0/1/3 artifacts (no active .session-lock)." >&2
fi

# Operational status — stderr only. NEVER stdout. Stdout is injected into
# model context as <system-reminder> and mimics tool-result output.
echo "session-bootstrap: layout verified (config=$CLAUDE_CONFIG_DIR, artifacts=$CLAUDE_ARTIFACT_DIR)." >&2
exit 0
