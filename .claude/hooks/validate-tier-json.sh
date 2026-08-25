#!/usr/bin/env bash
# PreToolUse hook: validate that the assistant turn preceding every tool call
# contains conformant Tier 1 AND Tier 2 JSON blocks.
#
# Fail-open policy: if payload absent, malformed, or lacks assistant_message → exit 0.
#
# Validation rules — Tier 1 (first ```json...``` block):
#   1. Block present and valid JSON.
#   2. target_agent present and one of the canonical agent set.
#   3. reasoning present and non-empty string.
#   4. model_shard present and one of the canonical shard set.
#   5. intent present and non-empty string.
#   6. confidence present and float in [0.0, 1.0].
#   7. thinking_level present and one of: low|medium|high|xhigh|max.
#   8. language_check present and matches ^[A-Z]{2}$ (ISO-639-1 code).
#   9. persona present and matches ^[A-Z]{2}-SeniorPeer$.
#  10. mode present and one of: Ask|Edit|Agent|Plan.
#  11. loaded_skills present and a JSON array.
#  12. No forbidden top-level keys: session_shard, language, tier, phase, status.
#
# Validation rules — Tier 2 (second ```json...``` block):
#   Required UNLESS target_agent == "MANAGER" (Law 1.3 self-route elision).
#   When required:
#   1. Block present and valid JSON.
#   2. active_agent present and non-empty string.
#   3. task_type present and non-empty string.
#   4. execution_mode present and one of: readonly|write|full.
#
# Project-local persona/language adaptation: this project supports any ISO-639-1
# language with the canonical SeniorPeer voice (EN-SeniorPeer, IT-SeniorPeer,
# FR-SeniorPeer, ...). The persona enum in the upstream GUIDELINES.md spec
# {IT-SeniorMentor, EN-SeniorPeer} is replaced with the regex
# ^[A-Z]{2}-SeniorPeer$, and language_check uses the matching regex
# ^[A-Z]{2}$ instead of the upstream {EN, IT} literal set.
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

blocks_raw = re.findall(r"```json\s*\n(.*?)\n```", text, re.DOTALL)
if not blocks_raw:
    print(f"{HOOK_NAME}: BLOCKED — no ```json...``` block found in assistant message.", file=sys.stderr)
    print(f"{HOOK_NAME}: Tier 1 JSON must be the absolute first output (Law 1).", file=sys.stderr)
    sys.exit(2)

try:
    tier1 = json.loads(blocks_raw[0].strip())
except Exception as e:
    print(f"{HOOK_NAME}: BLOCKED — first JSON block (Tier 1) is not valid JSON: {e}", file=sys.stderr)
    sys.exit(2)

VALID_AGENTS = {"ARCHITECT", "ENGINEER", "VALIDATOR", "LIBRARIAN", "REFLECTOR", "PROTOCOL", "MANAGER"}
PERSONA_RE = re.compile(r"^[A-Z]{2}-SeniorPeer$")
LANGUAGE_RE = re.compile(r"^[A-Z]{2}$")
VALID_THINKING = {"low", "medium", "high", "xhigh", "max"}
VALID_MODES = {"Ask", "Edit", "Agent", "Plan"}
VALID_EXECUTION_MODES = {"readonly", "write", "full"}
VALID_SHARDS = {
    "claude-opus-5",
    "claude-sonnet-5",
    "claude-fable-5",
    "claude-sonnet-4-6",
    "claude-opus-4-7",
    "claude-haiku-4-5",
    "claude-opus-4-6",
    "claude-opus-4-5",
    "claude-sonnet-4-5",
}
FORBIDDEN = {
    "session_shard": "use model_shard instead",
    "language":      "use language_check instead",
    "tier":          "not a Tier 1 field — remove it",
    "phase":         "not a Tier 1 field — remove it",
    "status":        "not a Tier 1 field — remove it",
}

failures = []

ta = tier1.get("target_agent", "__MISSING__")
if ta == "__MISSING__" or not ta:
    failures.append("Tier 1: missing required field: target_agent")
elif ta not in VALID_AGENTS:
    failures.append(f"Tier 1: invalid target_agent \"{ta}\" — must be one of {sorted(VALID_AGENTS)}")

if not tier1.get("reasoning", ""):
    failures.append("Tier 1: missing required field: reasoning")

ms = tier1.get("model_shard", "__MISSING__")
if ms == "__MISSING__" or not ms:
    failures.append("Tier 1: missing required field: model_shard")
elif ms not in VALID_SHARDS:
    failures.append(f"Tier 1: invalid model_shard \"{ms}\" — must be one of {sorted(VALID_SHARDS)}")

if not tier1.get("intent", ""):
    failures.append("Tier 1: missing required field: intent")

if "confidence" not in tier1:
    failures.append("Tier 1: missing required field: confidence")
else:
    c = tier1["confidence"]
    if isinstance(c, bool) or not isinstance(c, (int, float)) or not (0.0 <= float(c) <= 1.0):
        failures.append(f"Tier 1: confidence must be a float in [0.0, 1.0], got: {c!r}")

tl = tier1.get("thinking_level", "__MISSING__")
if tl == "__MISSING__":
    failures.append("Tier 1: missing required field: thinking_level")
elif tl not in VALID_THINKING:
    failures.append(f"Tier 1: invalid thinking_level \"{tl}\" — must be one of {sorted(VALID_THINKING)}")

lc = tier1.get("language_check", "__MISSING__")
if lc == "__MISSING__":
    failures.append("Tier 1: missing required field: language_check")
elif not LANGUAGE_RE.match(str(lc)):
    failures.append(f"Tier 1: invalid language_check \"{lc}\" — must match ^[A-Z]{{2}}$ (ISO-639-1 code, e.g. EN, IT, FR)")

persona = tier1.get("persona", "__MISSING__")
if persona == "__MISSING__":
    failures.append("Tier 1: missing required field: persona")
elif not PERSONA_RE.match(str(persona)):
    failures.append(f"Tier 1: invalid persona \"{persona}\" — must match ^[A-Z]{{2}}-SeniorPeer$ (e.g. EN-SeniorPeer, IT-SeniorPeer, FR-SeniorPeer)")

mode = tier1.get("mode", "__MISSING__")
if mode == "__MISSING__":
    failures.append("Tier 1: missing required field: mode")
elif mode not in VALID_MODES:
    failures.append(f"Tier 1: invalid mode \"{mode}\" — must be one of {sorted(VALID_MODES)}")

if "loaded_skills" not in tier1:
    failures.append("Tier 1: missing required field: loaded_skills (use [] when empty)")
elif not isinstance(tier1["loaded_skills"], list):
    failures.append("Tier 1: loaded_skills must be a JSON array")

for key, hint in FORBIDDEN.items():
    if key in tier1:
        failures.append(f"Tier 1: forbidden field \"{key}\" — {hint}")

self_route = (ta == "MANAGER")

if not self_route:
    if len(blocks_raw) < 2:
        failures.append(
            "Tier 2: missing — a second ```json...``` block is required for every non-MANAGER target_agent (Law 1). "
            "Only target_agent == \"MANAGER\" (self-route) may omit Tier 2 (Law 1.3)."
        )
    else:
        try:
            tier2 = json.loads(blocks_raw[1].strip())
        except Exception as e:
            failures.append(f"Tier 2: second JSON block is not valid JSON: {e}")
            tier2 = None

        if tier2 is not None:
            if not tier2.get("active_agent", ""):
                failures.append("Tier 2: missing required field: active_agent")
            if not tier2.get("task_type", ""):
                failures.append("Tier 2: missing required field: task_type")
            em = tier2.get("execution_mode", "__MISSING__")
            if em == "__MISSING__":
                failures.append("Tier 2: missing required field: execution_mode")
            elif em not in VALID_EXECUTION_MODES:
                failures.append(f"Tier 2: invalid execution_mode \"{em}\" — must be one of {sorted(VALID_EXECUTION_MODES)}")

if failures:
    print(f"{HOOK_NAME}: BLOCKED — Tier 1/2 JSON violates canonical schema (core-laws.md §8).", file=sys.stderr)
    print(f"{HOOK_NAME}: failures ({len(failures)}):", file=sys.stderr)
    for f in failures:
        print(f"  - {f}", file=sys.stderr)
    print(f"{HOOK_NAME}: canonical schema in CLAUDE.md §BOOT SEQUENCE and core-laws.md §8.", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
PYEOF
