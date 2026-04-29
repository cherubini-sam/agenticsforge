#!/usr/bin/env bash
# PostToolUse hook: validate .claude/artifacts/prompt_intake.md against the
# canonical schema at .claude/resources/prompt-intake.md.
#
# Validation rules (all must pass):
#   1. Frontmatter: description, owner=PROTOCOL, target_path, ephemeral=true.
#   2. CRITICAL callouts: TERMINAL STATE, OWNERSHIP, SCOPE GATE.
#   3. Required H2 sections: Language, Original, Reformulated, Transformations,
#      Token Delta, Fidelity Score, Decision, Loaded Skills, Warnings, Audit Trail.
#   4. Reformulated block contains <goal>, <scope>, <constraints>, <acceptance>, <refs>.
#   5. Decision section has exactly one [x] row.
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
  */.claude/artifacts/prompt_intake.md|.claude/artifacts/prompt_intake.md) : ;;
  *) exit 0 ;;
esac

ARTIFACT=".claude/artifacts/prompt_intake.md"
[[ -f "$ARTIFACT" ]] || { echo "validate-intake-schema: BLOCKED — $ARTIFACT missing after write." >&2; exit 2; }

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
printf '%s' "$fm" | grep -qE '^owner: *PROTOCOL'   || failures+=("frontmatter: owner must be PROTOCOL")
printf '%s' "$fm" | grep -qE '^target_path:'       || failures+=("frontmatter: missing target_path")
printf '%s' "$fm" | grep -qE '^ephemeral: *true'   || failures+=("frontmatter: ephemeral must be true")

# CRITICAL callouts
require 'TERMINAL STATE' "callout: TERMINAL STATE"
require 'OWNERSHIP' "callout: OWNERSHIP"
require 'SCOPE GATE' "callout: SCOPE GATE"

# H2 sections
require '^## Language$' "## Language"
require '^## Original$' "## Original"
require '^## Reformulated$' "## Reformulated"
require '^## Transformations$' "## Transformations"
require '^## Token Delta$' "## Token Delta"
require '^## Fidelity Score$' "## Fidelity Score"
require '^## Decision$' "## Decision"
require '^## Loaded Skills$' "## Loaded Skills"
require '^## Warnings$' "## Warnings"
require '^## Audit Trail$' "## Audit Trail"

# Reformulated XML tags
require '<goal>' "Reformulated: <goal> tag"
require '<scope>' "Reformulated: <scope> tag"
require '<constraints>' "Reformulated: <constraints> tag"
require '<acceptance>' "Reformulated: <acceptance> tag"
require '<refs>' "Reformulated: <refs> tag"

# Decision: exactly one [x] row among the three options
decision_block="$(printf '%s' "$body" | sed -n '/^## Decision$/,/^## /p')"
checked_count="$(printf '%s' "$decision_block" | grep -cE '^- \[x\] ' || true)"
if [[ "$checked_count" -ne 1 ]]; then
  failures+=("Decision: must have exactly one [x] row (found $checked_count)")
fi

if (( ${#failures[@]} > 0 )); then
  {
    echo "validate-intake-schema: BLOCKED — $ARTIFACT does not match canonical schema."
    echo "validate-intake-schema: canonical = ${CLAUDE_PROJECT_DIR}/.claude/resources/prompt-intake.md"
    echo "validate-intake-schema: failures (${#failures[@]}):"
    for f in "${failures[@]}"; do echo "  - $f"; done
    echo "validate-intake-schema: hint — instantiate via 'bash \${CLAUDE_PROJECT_DIR}/.claude/hooks/stamp-intake.sh \"<slug>\"'"
  } >&2
  exit 2
fi

exit 0
