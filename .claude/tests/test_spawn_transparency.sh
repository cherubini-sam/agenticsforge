#!/usr/bin/env bash
# test_spawn_transparency.sh — 16-case test harness for enforce-spawn-transparency.sh
# Cases V1–V6: valid (expect exit 0). Cases I1–I10: invalid (expect exit 2).
# Usage: bash .claude/tests/test_spawn_transparency.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

_LOCAL_HOOK="$REPO_ROOT/.claude/hooks/enforce-spawn-transparency.sh"
_GLOBAL_HOOK="${HOME}/.claude/hooks/enforce-spawn-transparency.sh"

if [[ -f "$_LOCAL_HOOK" ]]; then
    HOOK="$_LOCAL_HOOK"
elif [[ -f "$_GLOBAL_HOOK" ]]; then
    HOOK="$_GLOBAL_HOOK"
else
    echo "ERROR: enforce-spawn-transparency.sh not found in project-local or global hooks." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local payload="$2"
    local expected_exit="$3"

    actual_exit=0
    printf '%s' "$payload" | bash "$HOOK" > /dev/null 2>&1 || actual_exit=$?

    if [[ "$actual_exit" -eq "$expected_exit" ]]; then
        echo "  PASS: $name (exit $actual_exit)"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name (expected exit $expected_exit, got $actual_exit)"
        FAIL=$((FAIL + 1))
    fi
}

# Write a single-line JSONL transcript with the given assistant text content.
write_transcript() {
    local path="$1"
    local text="$2"
    printf '{"type":"assistant","message":{"content":[{"type":"text","text":%s}]}}\n' \
        "$(printf '%s' "$text" | /usr/bin/python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
        > "$path"
}

echo ""
echo "=== Spawn Transparency Hook Test Harness ==="
echo ""

# ---- VALID CASES (expect exit 0) ----
echo "-- Valid Cases --"

# V1: Non-Agent tool — passthrough
V1='{"tool_name":"Read","tool_input":{"file_path":"foo.md"}}'
run_test "V1_non_agent_tool" "$V1" 0

# V2: Valid Agent call — opus, tier 1, architect (spawn JSON embedded in longer text)
write_transcript "$TMP/v2.jsonl" 'Planning: {"event":"sub_agent_spawn","tier":1,"subagent_type":"architect","model_param":"opus","resolved_shard":"claude-opus-4-7","task_ref":"T-002"}'
V2='{"tool_name":"Agent","tool_input":{"subagent_type":"architect"},"transcript_path":"'"$TMP/v2.jsonl"'"}'
run_test "V2_valid_opus" "$V2" 0

# V3: Valid Task call — sonnet, tier 2, engineer
write_transcript "$TMP/v3.jsonl" '{"event":"sub_agent_spawn","tier":2,"subagent_type":"engineer","model_param":"sonnet","resolved_shard":"claude-sonnet-4-6","task_ref":"T-005"}'
V3='{"tool_name":"Task","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/v3.jsonl"'"}'
run_test "V3_valid_sonnet" "$V3" 0

# V4: Valid Agent call — haiku, tier 3, explore
write_transcript "$TMP/v4.jsonl" '{"event":"sub_agent_spawn","tier":3,"subagent_type":"explore","model_param":"haiku","resolved_shard":"claude-haiku-4-5-20251001","task_ref":"T-001"}'
V4='{"tool_name":"Agent","tool_input":{"subagent_type":"explore"},"transcript_path":"'"$TMP/v4.jsonl"'"}'
run_test "V4_valid_haiku" "$V4" 0

# V5: Valid Agent call — inherit, tier 2, validator
write_transcript "$TMP/v5.jsonl" '{"event":"sub_agent_spawn","tier":2,"subagent_type":"validator","model_param":"inherit","resolved_shard":"claude-sonnet-4-6","task_ref":"T-006"}'
V5='{"tool_name":"Agent","tool_input":{"subagent_type":"validator"},"transcript_path":"'"$TMP/v5.jsonl"'"}'
run_test "V5_valid_inherit" "$V5" 0

# V6: Write tool — passthrough (no spawn JSON required)
V6='{"tool_name":"Write","tool_input":{"file_path":"foo.md"}}'
run_test "V6_write_tool_passthrough" "$V6" 0

# ---- INVALID CASES (expect exit 2) ----
echo ""
echo "-- Invalid Cases --"

# I1: Agent call with no spawn JSON in transcript
write_transcript "$TMP/i1.jsonl" 'delegating to engineer without spawn block'
I1='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i1.jsonl"'"}'
run_test "I1_missing_spawn_json" "$I1" 2

# I2: Missing event field
write_transcript "$TMP/i2.jsonl" '{"tier":2,"subagent_type":"engineer","model_param":"sonnet","resolved_shard":"claude-sonnet-4-6","task_ref":"T-005"}'
I2='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i2.jsonl"'"}'
run_test "I2_missing_event_field" "$I2" 2

# I3: Missing tier field
write_transcript "$TMP/i3.jsonl" '{"event":"sub_agent_spawn","subagent_type":"engineer","model_param":"sonnet","resolved_shard":"claude-sonnet-4-6","task_ref":"T-005"}'
I3='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i3.jsonl"'"}'
run_test "I3_missing_tier_field" "$I3" 2

# I4: Missing subagent_type field
write_transcript "$TMP/i4.jsonl" '{"event":"sub_agent_spawn","tier":2,"model_param":"sonnet","resolved_shard":"claude-sonnet-4-6","task_ref":"T-005"}'
I4='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i4.jsonl"'"}'
run_test "I4_missing_subagent_type" "$I4" 2

# I5: Missing model_param field
write_transcript "$TMP/i5.jsonl" '{"event":"sub_agent_spawn","tier":2,"subagent_type":"engineer","resolved_shard":"claude-sonnet-4-6","task_ref":"T-005"}'
I5='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i5.jsonl"'"}'
run_test "I5_missing_model_param" "$I5" 2

# I6: Missing resolved_shard field
write_transcript "$TMP/i6.jsonl" '{"event":"sub_agent_spawn","tier":2,"subagent_type":"engineer","model_param":"sonnet","task_ref":"T-005"}'
I6='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i6.jsonl"'"}'
run_test "I6_missing_resolved_shard" "$I6" 2

# I7: Missing task_ref field
write_transcript "$TMP/i7.jsonl" '{"event":"sub_agent_spawn","tier":2,"subagent_type":"engineer","model_param":"sonnet","resolved_shard":"claude-sonnet-4-6"}'
I7='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i7.jsonl"'"}'
run_test "I7_missing_task_ref" "$I7" 2

# I8: Invalid model_param value
write_transcript "$TMP/i8.jsonl" '{"event":"sub_agent_spawn","tier":2,"subagent_type":"engineer","model_param":"gpt4","resolved_shard":"claude-sonnet-4-6","task_ref":"T-005"}'
I8='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i8.jsonl"'"}'
run_test "I8_invalid_model_param" "$I8" 2

# I9: Wrong event value
write_transcript "$TMP/i9.jsonl" '{"event":"something_else","tier":2,"subagent_type":"engineer","model_param":"sonnet","resolved_shard":"claude-sonnet-4-6","task_ref":"T-005"}'
I9='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i9.jsonl"'"}'
run_test "I9_wrong_event_value" "$I9" 2

# I10: Agent call — transcript assistant message has empty content array
printf '{"type":"assistant","message":{"content":[]}}\n' > "$TMP/i10.jsonl"
I10='{"tool_name":"Agent","tool_input":{"subagent_type":"engineer"},"transcript_path":"'"$TMP/i10.jsonl"'"}'
run_test "I10_empty_content_array" "$I10" 2

# ---- Summary ----
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [[ "$FAIL" -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
else
    echo "SOME TESTS FAILED"
    exit 1
fi
