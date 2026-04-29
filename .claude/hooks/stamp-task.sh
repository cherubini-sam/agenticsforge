#!/usr/bin/env bash
# Canonical instantiator for the project-local task.md artifact.
#
# Reads the canonical template from the GLOBAL config:
#   ${CLAUDE_PROJECT_DIR}/.claude/resources/task.md
# and writes the stamped artifact to the PROJECT-LOCAL sandbox:
#   ${CLAUDE_PROJECT_DIR}/.claude/artifacts/task.md
#
# Substitutions applied:
#   - "{{Task Name}}"  -> the provided title
#   - "[ISO-8601]"     -> a real ISO-8601 UTC timestamp
#
# Usage:
#   CLAUDE_PROJECT_DIR=/abs/path/to/project bash ${CLAUDE_PROJECT_DIR}/.claude/hooks/stamp-task.sh "<task title>"
#
# Exit codes: 0 = ok, 1 = misuse / template missing / CLAUDE_PROJECT_DIR unset.
set -euo pipefail

if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "stamp-task: ERROR — CLAUDE_PROJECT_DIR is not set." >&2
  echo "stamp-task: refusing to guess project root; export CLAUDE_PROJECT_DIR before invoking." >&2
  exit 1
fi

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "stamp-task: USAGE — bash \${CLAUDE_PROJECT_DIR}/.claude/hooks/stamp-task.sh \"<task title>\"" >&2
  exit 1
fi

TITLE="$1"
SRC="${CLAUDE_PROJECT_DIR}/.claude/resources/task.md"
DST="${CLAUDE_PROJECT_DIR}/.claude/artifacts/task.md"

[[ -f "$SRC" ]] || { echo "stamp-task: ERROR — canonical template missing: $SRC" >&2; exit 1; }
mkdir -p "$(dirname "$DST")"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SAFE_TITLE="${TITLE//\\/\\\\}"
SAFE_TITLE="${SAFE_TITLE//&/\\&}"
SAFE_TITLE="${SAFE_TITLE//|/\\|}"

cp "$SRC" "$DST"
# Substitute placeholders in-place. Use | as sed delimiter to tolerate paths in titles.
sed -i.bak "s|{{Task Name}}|${SAFE_TITLE}|g" "$DST"
sed -i.bak "s|\[ISO-8601\]|${TS}|g" "$DST"
rm -f "${DST}.bak"

echo "stamp-task: stamped $DST (title=\"$TITLE\", timestamp=$TS)"
