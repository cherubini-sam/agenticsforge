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
#   - The config root is resolved project-locally by _resolve-config-dir.sh,
#     which probes the canonical and interim layer names in order and fails
#     closed. There is no global fallback. The artifact sandbox is always
#     project-local and is resolved separately from the config root.
#   - Fail closed on empty payload, malformed JSON, missing project layout,
#     or any case-match miss.
#
# Exit 0 = allow; Exit 2 = BLOCK.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Project sanity — resolve the config root project-locally, under either the
# canonical or the interim layer name. No global fallback: a gate that resolves
# to a global mirror would enforce against a tree it does not govern.
# shellcheck source=_resolve-config-dir.sh
if ! source "$(dirname "$0")/_resolve-config-dir.sh"; then
  echo "enforce-boot-gate: BLOCKED — no project-local governance config root resolvable." >&2
  exit 2
fi
CONFIG_REL="$(basename "$CLAUDE_CONFIG_DIR")"

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
      CLAUDE_agentics_forge_boot.md|*/CLAUDE_agentics_forge_boot.md) exit 0 ;;
      "$CONFIG_REL"/protocols/*|*/"$CONFIG_REL"/protocols/*) exit 0 ;;
      "$CONFIG_REL"/resources/*|*/"$CONFIG_REL"/resources/*) exit 0 ;;
      "$CONFIG_REL"/rules/*|*/"$CONFIG_REL"/rules/*) exit 0 ;;
      "$CONFIG_REL"/skills/*|*/"$CONFIG_REL"/skills/*) exit 0 ;;
      "$CONFIG_REL"/agents/*|*/"$CONFIG_REL"/agents/*) exit 0 ;;
      "$CONFIG_REL"/tests/*|*/"$CONFIG_REL"/tests/*) exit 0 ;;
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
