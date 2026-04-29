#!/usr/bin/env bash
# PreToolUse hook: validate that the assistant turn preceding every tool call
# contains a conformant Tier 1 JSON block.
#
# Fail-open policy: if payload absent, malformed, or lacks assistant_message → exit 0.
#
# Validation rules (all must pass):
#   1. First ```json...``` fenced block present in assistant text.
#   2. Block is valid JSON.
#   3. target_agent present and one of the canonical agent set.
#   4. reasoning present and non-empty.
#   5. persona, if present, must match ^[A-Z]{2}-SeniorPeer$ (e.g. EN-SeniorPeer, IT-SeniorPeer, FR-SeniorPeer).
#   6. No forbidden top-level keys: session_shard, language, tier, phase, status.
#
# Exit codes: 0 = allow, 2 = block (Claude Code aborts the tool call).
set -euo pipefail

PAYLOAD=$(cat || true)
[[ -z "$PAYLOAD" ]] && exit 0

export HOOK_PAYLOAD="$PAYLOAD"

python3 - <<'PYEOF'
import json, sys, re, os

HOOK_NAME = "validate-tier-json"

payload = os.environ.get('HOOK_PAYLOAD', '')
if not payload.strip():
    sys.exit(0)

try:
    d = json.loads(payload)
except Exception:
    sys.exit(0)

msg = d.get("assistant_message") or {}
content = msg.get("content") or []
if not content:
    sys.exit(0)

text = "\n".join(
    b.get("text", "") for b in content
    if isinstance(b, dict) and b.get("type") == "text"
)
if not text.strip():
    sys.exit(0)

m = re.search(r"```json\s*\n(.*?)\n```", text, re.DOTALL)
if not m:
    print(f"{HOOK_NAME}: BLOCKED — no ```json...``` block found in assistant message.", file=sys.stderr)
    print(f"{HOOK_NAME}: Tier 1 JSON must be the absolute first output (Law 1).", file=sys.stderr)
    sys.exit(2)

try:
    obj = json.loads(m.group(1).strip())
except Exception as e:
    print(f"{HOOK_NAME}: BLOCKED — first JSON block is not valid JSON: {e}", file=sys.stderr)
    sys.exit(2)

VALID_AGENTS = {"ARCHITECT", "ENGINEER", "VALIDATOR", "LIBRARIAN", "REFLECTOR", "PROTOCOL", "MANAGER"}
PERSONA_RE = re.compile(r"^[A-Z]{2}-SeniorPeer$")
FORBIDDEN = {
    "session_shard": "use model_shard instead",
    "language":      "use language_check instead",
    "tier":          "not a Tier 1 field — remove it",
    "phase":         "not a Tier 1 field — remove it",
    "status":        "not a Tier 1 field — remove it",
}

failures = []

ta = obj.get("target_agent", "")
if not ta:
    failures.append("missing required field: target_agent")
elif ta not in VALID_AGENTS:
    failures.append(f"invalid target_agent \"{ta}\" — must be one of {sorted(VALID_AGENTS)}")

if not obj.get("reasoning", ""):
    failures.append("missing required field: reasoning")

persona = obj.get("persona")
if persona is not None and not PERSONA_RE.match(str(persona)):
    failures.append(f"invalid persona \"{persona}\" — must match ^[A-Z]{{2}}-SeniorPeer$ (e.g. EN-SeniorPeer, IT-SeniorPeer)")

for key, hint in FORBIDDEN.items():
    if key in obj:
        failures.append(f"forbidden field \"{key}\" — {hint}")

if failures:
    print(f"{HOOK_NAME}: BLOCKED — Tier 1 JSON violates canonical schema (core-laws.md §8).", file=sys.stderr)
    print(f"{HOOK_NAME}: failures ({len(failures)}):", file=sys.stderr)
    for f in failures:
        print(f"  - {f}", file=sys.stderr)
    print(f"{HOOK_NAME}: canonical schema embedded in CLAUDE.md §BOOT SEQUENCE.", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
PYEOF
