#!/usr/bin/env bash
# PostToolUse hook: validate .claude/artifacts/implementation_plan.md against
# the canonical schema at .claude/resources/implementation-plan.md.
#
# Validation rules (all must pass):
#   1. Frontmatter: description, owner=ARCHITECT, target_path, ephemeral=true.
#   2. Required H2 sections: OBJECTIVE, CURRENT STATE ANALYSIS, PROPOSED SOLUTION,
#      VERIFICATION STRATEGY, RISK ASSESSMENT, REFLECTOR APPROVAL, AUDIT TRAIL.
#   3. CRITICAL callouts: TERMINAL STATE, PHASE 3 GATE.
#   4. Required H3 sections under PROPOSED SOLUTION: Architecture Decision,
#      Implementation Steps, Files to Modify, Files to Create.
#   5. REFLECTOR APPROVAL section contains a Confidence Score line.
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
  */.claude/artifacts/implementation_plan.md|.claude/artifacts/implementation_plan.md) : ;;
  *) exit 0 ;;
esac

ARTIFACT=".claude/artifacts/implementation_plan.md"
[[ -f "$ARTIFACT" ]] || { echo "validate-plan-schema: BLOCKED — $ARTIFACT missing after write." >&2; exit 2; }

failures=()
body="$(cat "$ARTIFACT")"

require() {
  local pattern="$1" label="$2"
  printf '%s' "$body" | grep -qE "$pattern" || failures+=("missing: $label")
}

# Frontmatter — extract body between first and second --- via awk (POSIX-clean).
printf '%s' "$body" | head -n 1 | grep -q '^---$' || failures+=("frontmatter: missing opening ---")
fm="$(printf '%s' "$body" | awk '/^---$/{c++; next} c==1' | head -50)"
printf '%s' "$fm" | grep -qE '^description:'       || failures+=("frontmatter: missing description")
printf '%s' "$fm" | grep -qE '^owner: *ARCHITECT'  || failures+=("frontmatter: owner must be ARCHITECT")
printf '%s' "$fm" | grep -qE '^target_path:'       || failures+=("frontmatter: missing target_path")
printf '%s' "$fm" | grep -qE '^ephemeral: *true'   || failures+=("frontmatter: ephemeral must be true")

# H2 sections
require '^## OBJECTIVE$' "## OBJECTIVE"
require '^## CURRENT STATE ANALYSIS$' "## CURRENT STATE ANALYSIS"
require '^## PROPOSED SOLUTION$' "## PROPOSED SOLUTION"
require '^## VERIFICATION STRATEGY$' "## VERIFICATION STRATEGY"
require '^## RISK ASSESSMENT$' "## RISK ASSESSMENT"
require '^## REFLECTOR APPROVAL$' "## REFLECTOR APPROVAL"
require '^## AUDIT TRAIL$' "## AUDIT TRAIL"

# CRITICAL callouts
require 'TERMINAL STATE' "callout: TERMINAL STATE"
require 'PHASE 3 GATE' "callout: PHASE 3 GATE"

# H3 sections under PROPOSED SOLUTION
require '^### Architecture Decision$' "### Architecture Decision"
require '^### Implementation Steps$' "### Implementation Steps"
require '^### Files to Modify$' "### Files to Modify"
require '^### Files to Create$' "### Files to Create"

# REFLECTOR APPROVAL must include Confidence Score
require '\*\*Confidence Score\*\*' "REFLECTOR APPROVAL: **Confidence Score** field"

if (( ${#failures[@]} > 0 )); then
  {
    echo "validate-plan-schema: BLOCKED — $ARTIFACT does not match canonical schema."
    echo "validate-plan-schema: canonical = ${CLAUDE_PROJECT_DIR}/.claude/resources/implementation-plan.md"
    echo "validate-plan-schema: failures (${#failures[@]}):"
    for f in "${failures[@]}"; do echo "  - $f"; done
    echo "validate-plan-schema: hint — instantiate via 'bash \${CLAUDE_PROJECT_DIR}/.claude/hooks/stamp-plan.sh \"<title>\"'"
  } >&2
  exit 2
fi

exit 0
