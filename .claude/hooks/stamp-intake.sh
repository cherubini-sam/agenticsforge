#!/usr/bin/env bash
# Canonical instantiator for the project-local prompt_intake.md artifact.
#
# Reads the canonical template from the GLOBAL config:
#   ${CLAUDE_PROJECT_DIR}/.claude/resources/prompt-intake.md
# and writes the stamped artifact to the PROJECT-LOCAL sandbox:
#   ${CLAUDE_PROJECT_DIR}/.claude/artifacts/prompt_intake.md
#
# Substitutions applied at stamp time:
#   - "{{Session Slug}}" -> the provided slug
#   - "{{ISO-8601}}"     -> a real ISO-8601 UTC timestamp
#
# Other {{...}} placeholders (Original/Reformulated/Token Delta/etc.) are left
# in place — they are filled by PROTOCOL during the Phase 0 (b) inference step.
#
# Usage:
#   CLAUDE_PROJECT_DIR=/abs/path/to/project bash ${CLAUDE_PROJECT_DIR}/.claude/hooks/stamp-intake.sh "<session-slug>"
#
# Exit codes: 0 = ok, 1 = misuse / template missing / CLAUDE_PROJECT_DIR unset.
set -euo pipefail

if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "stamp-intake: ERROR — CLAUDE_PROJECT_DIR is not set." >&2
  echo "stamp-intake: refusing to guess project root; export CLAUDE_PROJECT_DIR before invoking." >&2
  exit 1
fi

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "stamp-intake: USAGE — bash \${CLAUDE_PROJECT_DIR}/.claude/hooks/stamp-intake.sh \"<session-slug>\"" >&2
  exit 1
fi

SLUG="$1"
SRC="${CLAUDE_PROJECT_DIR}/.claude/resources/prompt-intake.md"
DST="${CLAUDE_PROJECT_DIR}/.claude/artifacts/prompt_intake.md"

[[ -f "$SRC" ]] || { echo "stamp-intake: ERROR — canonical template missing: $SRC" >&2; exit 1; }
mkdir -p "$(dirname "$DST")"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SAFE_SLUG="${SLUG//\\/\\\\}"
SAFE_SLUG="${SAFE_SLUG//&/\\&}"
SAFE_SLUG="${SAFE_SLUG//|/\\|}"

cp "$SRC" "$DST"
sed -i.bak "s|{{Session Slug}}|${SAFE_SLUG}|g" "$DST"
sed -i.bak "s|{{ISO-8601}}|${TS}|g" "$DST"
rm -f "${DST}.bak"

echo "stamp-intake: stamped $DST (slug=\"$SLUG\", timestamp=$TS)"
