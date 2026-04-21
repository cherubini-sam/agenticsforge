#!/usr/bin/env bash
# PreToolUse hook: enforce Phase 1 + Phase 3 gates.
#
# Gate logic:
#   Read|Glob:
#     - Allow empty target (metadata probes, broad glob refreshes).
#     - Allow reads on protocol templates (CLAUDE.md, .claude/protocols|
#       resources|rules|skills|agents, .claude/artifacts).
#     - Otherwise require .claude/artifacts/task.md (Phase 1 gate).
#   Grep|Bash|Agent|Task|WebSearch|WebFetch:
#     - Require .claude/artifacts/task.md (Phase 1 gate).
#   Write|Edit|MultiEdit:
#     - Allow writes under .claude/artifacts/.
#     - Otherwise require .claude/artifacts/implementation_plan.md (Phase 3).
#
# Exit codes: 0 = allow, 2 = block (Claude Code aborts the tool call).
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

payload="$(cat || true)"
if [[ -z "$payload" ]]; then
  exit 0
fi

tool="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_name") or d.get("tool") or "")
except Exception:
    print("")' 2>/dev/null || true)"

# Hoisted target extraction — used by Read/Glob and by Write/Edit/MultiEdit
# fall-through below. Fallback to "pattern" covers Glob payloads.
target="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    i=d.get("tool_input") or d.get("input") or {}
    print(i.get("file_path") or i.get("pattern") or "")
except Exception:
    print("")' 2>/dev/null || true)"

case "$tool" in
  Read|Glob)
    case "$target" in
      "") exit 0 ;;
      .claude/artifacts/*|*/.claude/artifacts/*) exit 0 ;;
      CLAUDE.md|*/CLAUDE.md) exit 0 ;;
      .claude/protocols/*|*/.claude/protocols/*) exit 0 ;;
      .claude/resources/*|*/.claude/resources/*) exit 0 ;;
      .claude/rules/*|*/.claude/rules/*) exit 0 ;;
      .claude/skills/*|*/.claude/skills/*) exit 0 ;;
      .claude/agents/*|*/.claude/agents/*) exit 0 ;;
    esac
    if [[ ! -f ".claude/artifacts/task.md" ]]; then
      echo "enforce-phase-gate: BLOCKED — Read/Glob on non-sandbox path requires .claude/artifacts/task.md (Phase 1 gate)." >&2
      exit 2
    fi
    exit 0
    ;;
  Grep|Bash|Agent|Task|WebSearch|WebFetch)
    if [[ ! -f ".claude/artifacts/task.md" ]]; then
      echo "enforce-phase-gate: BLOCKED — $tool requires .claude/artifacts/task.md (Phase 1 gate)." >&2
      echo "enforce-phase-gate: Create task.md at Phase 1 before using research or execution tools." >&2
      exit 2
    fi
    exit 0
    ;;
  Write|Edit|MultiEdit) : ;;
  *) exit 0 ;;
esac

# Legacy L44-L49 target extraction removed — extraction is now hoisted above.

if [[ -z "$target" ]]; then
  exit 0
fi

# Allow writes to artifact sandbox unconditionally (Phase 0-2 create artifacts).
case "$target" in
  */.claude/artifacts/*|.claude/artifacts/*) exit 0 ;;
esac

# Gate: implementation_plan.md must exist before any source-file write.
if [[ ! -f ".claude/artifacts/implementation_plan.md" ]]; then
  echo "enforce-phase-gate: BLOCKED — Phase 3 gate requires .claude/artifacts/implementation_plan.md before source writes." >&2
  echo "enforce-phase-gate: Create a plan at Phase 3 and get REFLECTOR approval at Phase 4 before executing." >&2
  exit 2
fi

exit 0
