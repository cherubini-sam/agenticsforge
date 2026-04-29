#!/usr/bin/env bash
# PostToolUse hook: validate .claude/artifacts/task.md against canonical schema.
#
# Triggered on Write|Edit|MultiEdit. No-op unless the affected path is
# .claude/artifacts/task.md. On schema violation, emits an itemized failure
# list to stderr and exits 2 — Claude Code surfaces the error and blocks
# downstream PostToolUse hooks. The agent is forced to overwrite the artifact
# with a conformant body before advancing the workflow.
#
# Validation rules (all must pass):
#   1. Frontmatter present with keys: description, owner=MANAGER,
#      target_path, ephemeral=true.
#   2. Required H2 sections in order: HALT POLICY, PRE-FLIGHT INITIALIZATION,
#      OPERATIONAL RISK ASSESSMENT, MISSION OBJECTIVES,
#      6-PHASE INDUSTRIAL WORKFLOW, SKILL OVERRIDES, AUDIT TRAIL.
#   3. Both CRITICAL callouts present: SYSTEM INTEGRITY ALERT (LAW-30),
#      SINGLETON STATE DIRECTIVE.
#   4. Six phase rows present: Phase 1..6.
#   5. Four PRE-FLIGHT checks: [LAW-1], [LAW-30], [LAW-34], [SEC-01].
#   6. AUDIT TRAIL contains a real Timestamp Created (placeholder rejected).
#
# Exit codes: 0 = pass / not-our-file, 2 = schema violation.
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
  */.claude/artifacts/task.md|.claude/artifacts/task.md) : ;;
  *) exit 0 ;;
esac

ARTIFACT=".claude/artifacts/task.md"
[[ -f "$ARTIFACT" ]] || { echo "validate-task-schema: BLOCKED — $ARTIFACT missing after write." >&2; exit 2; }

failures=()
body="$(cat "$ARTIFACT")"

require() {
  local pattern="$1" label="$2"
  printf '%s' "$body" | grep -qE "$pattern" || failures+=("missing: $label")
}

# Frontmatter — extract body between first and second --- via awk (POSIX-clean).
printf '%s' "$body" | head -n 1 | grep -q '^---$' || failures+=("frontmatter: missing opening ---")
fm="$(printf '%s' "$body" | awk '/^---$/{c++; next} c==1' | head -50)"
printf '%s' "$fm" | grep -qE '^description:'      || failures+=("frontmatter: missing description")
printf '%s' "$fm" | grep -qE '^owner: *MANAGER'    || failures+=("frontmatter: owner must be MANAGER")
printf '%s' "$fm" | grep -qE '^target_path:'       || failures+=("frontmatter: missing target_path")
printf '%s' "$fm" | grep -qE '^ephemeral: *true'   || failures+=("frontmatter: ephemeral must be true")

# Required H2 sections
require '^## HALT POLICY$' "## HALT POLICY"
require '^## PRE-FLIGHT INITIALIZATION$' "## PRE-FLIGHT INITIALIZATION"
require '^## OPERATIONAL RISK ASSESSMENT$' "## OPERATIONAL RISK ASSESSMENT"
require '^## MISSION OBJECTIVES$' "## MISSION OBJECTIVES"
require '^## 6-PHASE INDUSTRIAL WORKFLOW$' "## 6-PHASE INDUSTRIAL WORKFLOW"
require '^## SKILL OVERRIDES$' "## SKILL OVERRIDES"
require '^## AUDIT TRAIL$' "## AUDIT TRAIL"

# CRITICAL callouts
require 'SYSTEM INTEGRITY ALERT \(LAW-30\)' "callout: SYSTEM INTEGRITY ALERT (LAW-30)"
require 'SINGLETON STATE DIRECTIVE' "callout: SINGLETON STATE DIRECTIVE"

# Six phases
for n in 1 2 3 4 5 6; do
  require "Phase $n:" "Phase $n row"
done

# PRE-FLIGHT checks
require '\[LAW-1\] Format Priority' "PRE-FLIGHT [LAW-1] Format Priority"
require '\[LAW-30\] Schema Validation' "PRE-FLIGHT [LAW-30] Schema Validation"
require '\[LAW-34\] Re-Iteration' "PRE-FLIGHT [LAW-34] Re-Iteration"
require '\[SEC-01\] Path Isolation' "PRE-FLIGHT [SEC-01] Path Isolation"

# Audit timestamp must be real (reject the placeholder).
ts_line="$(printf '%s' "$body" | grep -E '^\- \*\*Timestamp Created\*\*:' || true)"
if [[ -z "$ts_line" ]]; then
  failures+=("AUDIT TRAIL: missing **Timestamp Created** field")
elif printf '%s' "$ts_line" | grep -qE '\[ISO-8601\]'; then
  failures+=("AUDIT TRAIL: Timestamp Created still has [ISO-8601] placeholder")
fi

if (( ${#failures[@]} > 0 )); then
  {
    echo "validate-task-schema: BLOCKED — $ARTIFACT does not match canonical schema."
    echo "validate-task-schema: canonical = ${CLAUDE_PROJECT_DIR}/.claude/resources/task.md"
    echo "validate-task-schema: failures (${#failures[@]}):"
    for f in "${failures[@]}"; do echo "  - $f"; done
    echo "validate-task-schema: hint — instantiate via 'bash \${CLAUDE_PROJECT_DIR}/.claude/hooks/stamp-task.sh \"<title>\"'"
  } >&2
  exit 2
fi

exit 0
