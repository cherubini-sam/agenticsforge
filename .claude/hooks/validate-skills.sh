#!/usr/bin/env bash
# SessionStart / ad-hoc hook: enforce SKILL.md token budget (V7.8) and index/triggers integrity.
# Budget: no SKILL.md may exceed 500 tokens (~2KB). Aligned with Anthropic official "under 500 lines" guidance.
# Integrity: index.json + triggers.json must be valid JSON with no empty placeholder fields (V7.9).
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Resolve config directory (project-first, global fallback).
# shellcheck source=_resolve-config-dir.sh
source "$(dirname "$0")/_resolve-config-dir.sh"

SKILL_ROOT="$CLAUDE_CONFIG_DIR/skills"
INDEX="$SKILL_ROOT/index.json"
TRIGGERS="$SKILL_ROOT/triggers.json"
TOKEN_BUDGET=500

if [[ ! -d "$SKILL_ROOT" ]]; then
  echo "validate-skills: skills root missing -> $SKILL_ROOT" >&2
  exit 2
fi

fail=0
warn=0

# V7.8 token budget sweep (500 tokens ~ 2000 bytes).
while IFS= read -r -d '' f; do
  bytes="$(wc -c < "$f" | tr -d ' ')"
  tokens=$(( bytes / 4 ))
  if (( tokens > TOKEN_BUDGET )); then
    echo "validate-skills: BUDGET breach (~$tokens tokens > $TOKEN_BUDGET) -> $f" >&2
    fail=1
  fi
done < <(find "$SKILL_ROOT" -type f -name "SKILL.md" -print0 2>/dev/null)

# index.json integrity.
if [[ -f "$INDEX" ]]; then
  if ! /usr/bin/python3 - "$INDEX" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as fh:
        data = json.load(fh)
except Exception as exc:
    print(f"validate-skills: index.json parse error -> {exc}", file=sys.stderr)
    sys.exit(2)

skills = data.get("skills") if isinstance(data, dict) else None
if not isinstance(skills, list):
    print("validate-skills: index.json missing 'skills' array", file=sys.stderr)
    sys.exit(2)

bad = 0
for entry in skills:
    if not isinstance(entry, dict):
        bad += 1
        continue
    for field in ("id", "description"):
        if not entry.get(field):
            print(f"validate-skills: empty '{field}' in entry {entry.get('id','<no-id>')}", file=sys.stderr)
            bad += 1
sys.exit(2 if bad else 0)
PY
  then
    fail=1
  fi
else
  echo "validate-skills: index.json missing -> $INDEX" >&2
  fail=1
fi

# V7.9 triggers.json integrity.
if [[ -f "$TRIGGERS" ]]; then
  if ! /usr/bin/python3 - "$TRIGGERS" <<'PY2'
import json, sys
path = sys.argv[1]
try:
    with open(path) as fh:
        data = json.load(fh)
except Exception as exc:
    print(f"validate-skills: triggers.json parse error -> {exc}", file=sys.stderr)
    sys.exit(2)

triggers = data.get("triggers") if isinstance(data, dict) else None
if not isinstance(triggers, dict):
    print("validate-skills: triggers.json missing 'triggers' object", file=sys.stderr)
    sys.exit(2)

bad = 0
for sid, entry in triggers.items():
    if not isinstance(entry, dict):
        bad += 1
        continue
    # V7.9: reject empty arrays (should be omitted, not [])
    for field in ("keywords", "regex", "intents", "file_globs"):
        val = entry.get(field)
        if isinstance(val, list) and len(val) == 0 and field != "file_globs":
            print(f"validate-skills: empty '{field}' in trigger {sid} — omit instead of []", file=sys.stderr)
            bad += 1
sys.exit(2 if bad else 0)
PY2
  then
    fail=1
  fi
fi

if (( fail )); then exit 2; fi
exit 0
