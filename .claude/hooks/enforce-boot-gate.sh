#!/usr/bin/env bash
# PreToolUse hook: enforce Phase 0 boot gate.
#
# Contract:
#   - Deny every tool call unless prompt_intake.md exists in the artifact
#     sandbox, EXCEPT for a narrow allowlist of protocol-template reads
#     needed to produce prompt_intake.md itself.
#   - Fast path: once prompt_intake.md exists, exit 0 unconditionally.
#     Downstream Phase 1/3 enforcement is delegated to enforce-phase-gate.sh
#     and block-destructive.sh. Do NOT duplicate that logic here.
#   - Resolution order for .claude/protocols/ follows CLAUDE.md §GLOBAL
#     INSTALLATION: project-local first, ${HOME}/.claude/ fallback. The
#     artifact sandbox remains project-local-only.
#   - Fail closed on empty payload, malformed JSON, missing project layout,
#     or any case-match miss.
#
# Exit 0 = allow; Exit 2 = BLOCK.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Project sanity — resolve protocols/ in the documented order.
if [[ ! -d ".claude/protocols" && ! -d "${HOME}/.claude/protocols" ]]; then
  echo "enforce-boot-gate: BLOCKED — no .claude/protocols/ resolvable (project-local or \${HOME}/.claude/)." >&2
  exit 2
fi

payload="$(cat || true)"
if [[ -z "$payload" ]]; then
  echo "enforce-boot-gate: BLOCKED — empty tool payload (fail-closed)." >&2
  exit 2
fi

tool="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_name") or d.get("tool") or "")
except Exception:
    print("")' 2>/dev/null || true)"

target="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    i=d.get("tool_input") or d.get("input") or {}
    print(i.get("file_path") or i.get("pattern") or "")
except Exception:
    print("")' 2>/dev/null || true)"

# Fast path — Phase 0 complete. Defer to enforce-phase-gate.sh for Phase 1/3.
if [[ -f ".claude/artifacts/prompt_intake.md" ]]; then
  exit 0
fi

# Phase 0 bootstrap whitelist.
case "$tool" in
  Read|Glob)
    case "$target" in
      CLAUDE.md|*/CLAUDE.md) exit 0 ;;
      .claude/protocols/*|*/.claude/protocols/*) exit 0 ;;
      .claude/resources/*|*/.claude/resources/*) exit 0 ;;
      .claude/rules/*|*/.claude/rules/*) exit 0 ;;
      .claude/skills/*|*/.claude/skills/*) exit 0 ;;
      .claude/agents/*|*/.claude/agents/*) exit 0 ;;
    esac
    ;;
  Write)
    case "$target" in
      .claude/artifacts/prompt_intake.md|*/.claude/artifacts/prompt_intake.md) exit 0 ;;
    esac
    ;;
esac

echo "enforce-boot-gate: BLOCKED — Phase 0 incomplete. Author .claude/artifacts/prompt_intake.md via Phase 0(b) before using $tool on $target." >&2
echo "enforce-boot-gate: No task-type exemption. Applies to content generation, analysis, refactors — every tool call on every session." >&2
exit 2
