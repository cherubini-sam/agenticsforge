#!/usr/bin/env bash
# PreToolUse hook: deny destructive shell commands and artifact-containment breaches.
# Receives the pending tool invocation on stdin as JSON:
#   { "tool_name": "Bash|Write|Edit|...", "tool_input": { ... } }
# Legacy "tool"/"input" keys are accepted as a fallback for payload-format drift.
# Exit 0 = allow; Exit 2 = BLOCK (Claude Code aborts the tool call).
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

case "$tool" in
  Bash)
    cmd="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    i=d.get("tool_input") or d.get("input") or {}
    print(i.get("command",""))
except Exception:
    print("")' 2>/dev/null || true)"

    # Hard-deny destructive shell patterns.
    declare -a DENY=(
      'rm[[:space:]]+-rf[[:space:]]+/'
      'rm[[:space:]]+-rf[[:space:]]+~'
      'rm[[:space:]]+-rf[[:space:]]+\$HOME'
      'rm[[:space:]]+-rf[[:space:]]+\.git([[:space:]]|$)'
      'git[[:space:]]+push[[:space:]]+.*--force'
      'git[[:space:]]+push[[:space:]]+.*-f([[:space:]]|$)'
      'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin'
      'git[[:space:]]+commit[[:space:]]+.*--no-verify'
      'git[[:space:]]+commit[[:space:]]+.*--no-gpg-sign'
      '--no-verify'
      'DROP[[:space:]]+TABLE'
      'DROP[[:space:]]+DATABASE'
      'TRUNCATE[[:space:]]+TABLE'
      'chmod[[:space:]]+-R[[:space:]]+777'
      'mkfs\.'
      'dd[[:space:]]+if=.*of=/dev/'
    )
    for pat in "${DENY[@]}"; do
      if printf '%s' "$cmd" | grep -Eqi "$pat"; then
        echo "block-destructive: DENY pattern matched -> $pat" >&2
        exit 2
      fi
    done

    # Branch-isolation guard (Law 40): refuse writes on master/main.
    if printf '%s' "$cmd" | grep -Eq '^\s*git[[:space:]]+(commit|merge|push)'; then
      branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
      if [[ "$branch" == "master" || "$branch" == "main" ]]; then
        if printf '%s' "$cmd" | grep -Eq 'push'; then
          echo "block-destructive: push on $branch requires explicit user override" >&2
          exit 2
        fi
      fi
    fi
    ;;

  Write|Edit|MultiEdit)
    target="$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    i=d.get("tool_input") or d.get("input") or {}
    print(i.get("file_path",""))
except Exception:
    print("")' 2>/dev/null || true)"

    if [[ -z "$target" ]]; then
      exit 0
    fi

    # On master/main branch: writes restricted to .claude/artifacts/ (Law 5 + Law 40).
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ "$branch" == "master" || "$branch" == "main" ]]; then
      case "$target" in
        */.claude/artifacts/*|.claude/artifacts/*) : ;;
        *)
          echo "block-destructive: write on $branch restricted to .claude/artifacts/ — target=$target" >&2
          exit 2
          ;;
      esac
    fi
    ;;

  Agent)
    # Agent sub-agents can write anywhere. On protected branches, require task.md.
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ "$branch" == "master" || "$branch" == "main" ]]; then
      if [[ ! -f ".claude/artifacts/task.md" ]]; then
        echo "block-destructive: Agent tool BLOCKED on $branch — no task.md" >&2
        exit 2
      fi
    fi
    ;;
esac

exit 0
