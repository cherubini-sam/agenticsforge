#!/usr/bin/env bash
# Smoke harness: prove every hook wired in settings.json EXECUTES rather than
# dying on a syntax error, an unbound variable, or a missing command.
#
# What this asserts, precisely:
#   For each hook command wired in settings.json, a minimal well-formed JSON
#   payload MATCHING THAT HOOK'S OWN EVENT TYPE (SessionStart / PreToolUse /
#   PostToolUse, read from the settings.json event key the hook is wired under)
#   is piped to the hook on stdin. The hook PASSES when:
#     - its exit status is 0 or 2, AND
#     - its stderr carries none of the crash signatures below.
#   It FAILS on any other exit status, or on any crash signature at any exit
#   status (including exit 0 and exit 2).
#
# Crash signatures (a hook that emits any of these did not really run):
#   "syntax error", "unexpected EOF", "unbound variable", "command not found"
#
# What this deliberately does NOT assert: the verdict. Exit 0 (allow) and exit 2
# (block) are BOTH legitimate hook outcomes, and which one a given hook returns
# depends on live artifact state. Asserting a verdict would make the harness a
# state test rather than a liveness test. The 0-vs-2 distribution is reported as
# information only.
#
# Rename-agnostic: this script locates its own tree from BASH_SOURCE and never
# names a layer directory literal, so it runs identically before and after the
# governance layer is renamed.
#
# Exit 0 = every wired hook EXECUTED. Exit 1 = at least one CRASHED.
set -uo pipefail

# --- Self-location (rename-agnostic; no layer-name literal anywhere) ---------
_SMOKE_SELF="${BASH_SOURCE[0]}"
while [ -L "$_SMOKE_SELF" ]; do
  _SMOKE_LINK="$(readlink "$_SMOKE_SELF")"
  case "$_SMOKE_LINK" in
    /*) _SMOKE_SELF="$_SMOKE_LINK" ;;
    *)  _SMOKE_SELF="$(cd -P "$(dirname "$_SMOKE_SELF")" && pwd)/$_SMOKE_LINK" ;;
  esac
done
TESTS_DIR="$(cd -P "$(dirname "$_SMOKE_SELF")" && pwd)"
CONFIG_DIR="$(cd -P "$TESTS_DIR/.." && pwd)"
PROJECT_DIR="$(cd -P "$CONFIG_DIR/.." && pwd)"
SETTINGS="$CONFIG_DIR/settings.json"

export CLAUDE_PROJECT_DIR="$PROJECT_DIR"

if [ ! -f "$SETTINGS" ]; then
  echo "smoke_hooks: FATAL — settings.json not found at $SETTINGS" >&2
  exit 1
fi

# --- Enumerate wired hooks as "<event>\t<command>" --------------------------
# Derived from settings.json at run time; no hook list is hardcoded.
HOOK_ROWS="$(/usr/bin/python3 - "$SETTINGS" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
for event, groups in (data.get("hooks") or {}).items():
    for group in groups or []:
        for hook in group.get("hooks") or []:
            command = hook.get("command") or ""
            if command:
                print("%s\t%s" % (event, command))
PY
)"

if [ -z "$HOOK_ROWS" ]; then
  echo "smoke_hooks: FATAL — no hook commands found in $SETTINGS" >&2
  exit 1
fi

# --- Per-event payload builders ---------------------------------------------
# Each payload is minimal but well-formed FOR ITS OWN EVENT TYPE. A hook only
# ever receives the shape its event actually delivers at runtime.
#
# PreToolUse: tool_name + tool_input, plus an assistant_message carrying a
#   conformant Tier 1 / Tier 2 JSON pair so a transparency validator has real
#   material to parse rather than an empty-payload fail-open shortcut.
# PostToolUse: the same tool envelope plus tool_response.
# SessionStart: source + transcript_path only; these hooks read no tool input.
payload_for_event() {
  case "$1" in
    PreToolUse)
      cat <<'JSON'
{
  "session_id": "smoke-harness",
  "transcript_path": "/dev/null",
  "cwd": ".",
  "hook_event_name": "PreToolUse",
  "tool_name": "Read",
  "tool_input": { "file_path": "README.md" },
  "assistant_message": {
    "content": [
      {
        "type": "text",
        "text": "```json\n{\"target_agent\":\"MANAGER\",\"intent\":\"smoke_test\",\"reasoning\":\"smoke harness liveness probe\",\"confidence\":1.0,\"model_shard\":\"claude-opus-5\",\"thinking_level\":\"high\",\"language_check\":\"EN\",\"persona\":\"EN-SeniorPeer\",\"mode\":\"Plan\",\"loaded_skills\":[]}\n```"
      }
    ]
  }
}
JSON
      ;;
    PostToolUse)
      cat <<'JSON'
{
  "session_id": "smoke-harness",
  "transcript_path": "/dev/null",
  "cwd": ".",
  "hook_event_name": "PostToolUse",
  "tool_name": "Read",
  "tool_input": { "file_path": "README.md" },
  "input": { "file_path": "README.md" },
  "tool_response": { "success": true }
}
JSON
      ;;
    SessionStart)
      cat <<'JSON'
{
  "session_id": "smoke-harness",
  "transcript_path": "/dev/null",
  "cwd": ".",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
JSON
      ;;
    *)
      cat <<'JSON'
{ "session_id": "smoke-harness", "transcript_path": "/dev/null" }
JSON
      ;;
  esac
}

# --- Run every hook ----------------------------------------------------------
CRASH_RE='syntax error|unexpected EOF|unbound variable|command not found'
STDERR_TMP="$(mktemp -t smoke_hooks_stderr.XXXXXX)"
trap 'rm -f "$STDERR_TMP"' EXIT

total=0
executed=0
crashed=0
allow_count=0
block_count=0

echo "smoke_hooks: probing hooks wired in $SETTINGS"
echo "smoke_hooks: project root = $PROJECT_DIR"
echo "----------------------------------------------------------------------"

while IFS="$(printf '\t')" read -r event command; do
  [ -z "${command:-}" ] && continue
  total=$((total + 1))

  # Resolve the runtime ${CLAUDE_PROJECT_DIR} substitution settings.json uses.
  resolved="${command//\$\{CLAUDE_PROJECT_DIR\}/$PROJECT_DIR}"
  name="$(basename "$resolved")"

  if [ ! -f "$resolved" ]; then
    printf '%-34s exit=--  verdict=CRASHED   (missing file: %s)\n' "$name" "$resolved"
    crashed=$((crashed + 1))
    continue
  fi

  : > "$STDERR_TMP"
  payload_for_event "$event" | bash "$resolved" >/dev/null 2>"$STDERR_TMP"
  status=$?
  err="$(cat "$STDERR_TMP")"

  verdict="CRASHED"
  detail=""
  if printf '%s' "$err" | grep -Eqi "$CRASH_RE"; then
    detail="crash signature on stderr"
  elif [ "$status" -eq 0 ] || [ "$status" -eq 2 ]; then
    verdict="EXECUTED"
  else
    detail="unexpected exit status"
  fi

  if [ "$verdict" = "EXECUTED" ]; then
    executed=$((executed + 1))
    if [ "$status" -eq 0 ]; then
      allow_count=$((allow_count + 1))
    else
      block_count=$((block_count + 1))
    fi
    printf '%-34s exit=%-3s verdict=%s  [%s]\n' "$name" "$status" "$verdict" "$event"
  else
    crashed=$((crashed + 1))
    printf '%-34s exit=%-3s verdict=%s   [%s] %s\n' "$name" "$status" "$verdict" "$event" "$detail"
    printf '    stderr: %s\n' "$(printf '%s' "$err" | head -3 | tr '\n' ' ')"
  fi
done <<EOF
$HOOK_ROWS
EOF

echo "----------------------------------------------------------------------"
echo "smoke_hooks: $executed/$total EXECUTED, $crashed CRASHED"
echo "smoke_hooks: verdict distribution (informational only) — allow(0)=$allow_count block(2)=$block_count"

if [ "$crashed" -ne 0 ]; then
  echo "smoke_hooks: FAIL — $crashed hook(s) did not execute cleanly." >&2
  exit 1
fi

echo "smoke_hooks: PASS — every wired hook executed."
exit 0
