#!/usr/bin/env bash
# PreToolUse hook: enforce sub_agent_spawn transparency for Agent/Task tool calls.
#
# Contract:
#   - Block any Agent (or Task) tool call that is NOT preceded in the most
#     recent assistant text output by a valid sub_agent_spawn JSON block.
#   - Required schema (all fields mandatory):
#       event:          "sub_agent_spawn"
#       tier:           1 | 2 | 3
#       subagent_type:  string (MUST match Agent's subagent_type input)
#       model_param:    "opus" | "sonnet" | "haiku" | "inherit"
#       resolved_shard: string (concrete model ID)
#       task_ref:       string (Task ID from task.md, or "—")
#   - Spec: .claude/rules/stack.md §Sub-Agent Spawn Transparency
#   - Fail-closed on empty payload, malformed JSON, missing transcript,
#     missing/invalid spawn block. No exemptions.
#
# Exit 0 = allow; Exit 2 = BLOCK.
set -euo pipefail

payload="$(cat || true)"
if [[ -z "$payload" ]]; then
  echo "enforce-spawn-transparency: BLOCKED — empty tool payload (fail-closed)." >&2
  exit 2
fi

export HOOK_PAYLOAD="$payload"
result="$(/usr/bin/python3 - <<'PY'
import json, os, sys

payload_str = os.environ.get("HOOK_PAYLOAD", "")
try:
    payload = json.loads(payload_str)
except Exception:
    print("FAIL:bad-payload")
    sys.exit(0)

tool = payload.get("tool_name") or payload.get("tool") or ""
if tool not in ("Agent", "Task"):
    print("OK:not-agent")
    sys.exit(0)

tool_input = payload.get("tool_input") or payload.get("input") or {}
target_subagent = (tool_input.get("subagent_type") or "").strip()

transcript = payload.get("transcript_path", "")
if not transcript or not os.path.isfile(transcript):
    print("FAIL:no-transcript")
    sys.exit(0)

last_assistant_text = ""
try:
    with open(transcript, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except Exception:
                continue
            if msg.get("type") != "assistant":
                continue
            content = msg.get("message", {}).get("content", [])
            if isinstance(content, str):
                last_assistant_text = content
                continue
            parts = []
            for c in content:
                if isinstance(c, dict) and c.get("type") == "text":
                    parts.append(c.get("text", ""))
            if parts:
                last_assistant_text = "\n".join(parts)
except Exception:
    print("FAIL:transcript-read")
    sys.exit(0)

if not last_assistant_text:
    print("FAIL:no-assistant-text")
    sys.exit(0)

def extract_json_objects(text):
    objs = []
    depth = 0
    buf = ""
    in_string = False
    escape = False
    for ch in text:
        if depth > 0:
            buf += ch
        if escape:
            escape = False
            continue
        if ch == "\\":
            escape = True
            continue
        if ch == '"':
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch == "{":
            if depth == 0:
                buf = "{"
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and buf.strip():
                try:
                    objs.append(json.loads(buf))
                except Exception:
                    pass
                buf = ""
            elif depth < 0:
                depth = 0
                buf = ""
    return objs

required = {"event", "tier", "subagent_type", "model_param", "resolved_shard", "task_ref"}
valid_models = {"opus", "sonnet", "haiku", "inherit"}
valid_tiers = {1, 2, 3}

ok = False
reason = "no-spawn-block"
for obj in extract_json_objects(last_assistant_text):
    if not isinstance(obj, dict):
        continue
    if obj.get("event") != "sub_agent_spawn":
        continue
    missing = required - set(obj.keys())
    if missing:
        reason = "missing-fields:" + ",".join(sorted(missing))
        continue
    if obj.get("tier") not in valid_tiers:
        reason = "bad-tier:" + str(obj.get("tier"))
        continue
    if obj.get("model_param") not in valid_models:
        reason = "bad-model_param:" + str(obj.get("model_param"))
        continue
    if target_subagent and obj.get("subagent_type") != target_subagent:
        reason = "subagent_type-mismatch:expected=" + target_subagent + ",got=" + str(obj.get("subagent_type"))
        continue
    ok = True
    break

print("OK:valid" if ok else "FAIL:" + reason)
PY
)" || result="FAIL:python-error"

case "$result" in
  OK:*) exit 0 ;;
esac

cat >&2 <<EOF
enforce-spawn-transparency: BLOCKED — Agent tool call requires a preceding sub_agent_spawn JSON block.
Reason: ${result#FAIL:}

Required format (place in a fenced \`\`\`json block in your message BEFORE the Agent call):

{
  "event": "sub_agent_spawn",
  "tier": <1|2|3>,
  "subagent_type": "<must match Agent's subagent_type>",
  "model_param": "<opus|sonnet|haiku|inherit>",
  "resolved_shard": "<concrete model ID, e.g. claude-sonnet-4-6>",
  "task_ref": "<Task ID from task.md, or '—'>"
}

Spec: .claude/rules/stack.md §Sub-Agent Spawn Transparency
EOF
exit 2
