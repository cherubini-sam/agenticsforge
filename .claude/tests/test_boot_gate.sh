#!/usr/bin/env bash
# Validator harness for enforce-boot-gate.sh and the enforce-phase-gate.sh
# Read/Glob extension. Runs in an isolated mktemp sandbox — NEVER mutates
# live project state.
#
# Replays the exact prior-session failure prompt as documentation:
#   "Considering @jobs.md as job offers that I must apply, generate tailored
#    resumes and cover letters using as base reference
#    @resume_html/resume_template.md @resume_html/
#    @cover_letter/cover_letter_template.md . Consider at the end to generate
#    also PDFs of all generated resume that must fit in 1 page. Consider to
#    validate the final results to be 100% human written, fluent, natural,
#    and professional."
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK_BOOT="$REPO_ROOT/.claude/hooks/enforce-boot-gate.sh"
HOOK_PHASE="$REPO_ROOT/.claude/hooks/enforce-phase-gate.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/.claude/artifacts" \
         "$TMP/.claude/protocols" \
         "$TMP/.claude/resources" \
         "$TMP/.claude/rules" \
         "$TMP/.claude/skills" \
         "$TMP/.claude/agents"
touch "$TMP/CLAUDE.md" \
      "$TMP/.claude/protocols/core-laws.md" \
      "$TMP/.claude/resources/prompt-intake.md" \
      "$TMP/.claude/resources/task.md"
echo '{}' > "$TMP/.claude/skills/triggers.json"

export CLAUDE_PROJECT_DIR="$TMP"

fail=0
assert_block() {
  local name="$1" payload="$2" hook="$3"
  if printf '%s' "$payload" | "$hook" >/dev/null 2>&1; then
    echo "FAIL: expected BLOCK for $name"
    fail=1
  fi
}
assert_allow() {
  local name="$1" payload="$2" hook="$3"
  if ! printf '%s' "$payload" | "$hook" >/dev/null 2>&1; then
    echo "FAIL: expected ALLOW for $name"
    fail=1
  fi
}

# === enforce-boot-gate: no prompt_intake.md (failure-prompt replay) ===
rm -f "$TMP/.claude/artifacts/prompt_intake.md"

assert_block "Read resume_template"    '{"tool":"Read","input":{"file_path":"resume_html/resume_template.md"}}'      "$HOOK_BOOT"
assert_block "Read jobs.md"            '{"tool":"Read","input":{"file_path":"jobs.md"}}'                             "$HOOK_BOOT"
assert_block "Glob jobs.md"            '{"tool":"Glob","input":{"pattern":"jobs.md"}}'                               "$HOOK_BOOT"
assert_block "Glob resume_html dir"    '{"tool":"Glob","input":{"pattern":"resume_html/*.md"}}'                      "$HOOK_BOOT"
assert_block "Write non-sandbox"       '{"tool":"Write","input":{"file_path":"resume_html/out.html"}}'               "$HOOK_BOOT"
assert_block "Bash ls"                 '{"tool":"Bash","input":{"command":"ls"}}'                                    "$HOOK_BOOT"
assert_block "Agent delegation"        '{"tool":"Agent","input":{"description":"x"}}'                                "$HOOK_BOOT"
assert_block "Task delegation"         '{"tool":"Task","input":{"description":"x"}}'                                 "$HOOK_BOOT"
assert_block "TodoWrite"               '{"tool":"TodoWrite","input":{"todos":[]}}'                                   "$HOOK_BOOT"
assert_block "NotebookEdit"            '{"tool":"NotebookEdit","input":{"notebook_path":"x.ipynb"}}'                 "$HOOK_BOOT"
assert_block "WebFetch"                '{"tool":"WebFetch","input":{"url":"https://example.com"}}'                   "$HOOK_BOOT"
assert_block "Grep"                    '{"tool":"Grep","input":{"pattern":"foo"}}'                                   "$HOOK_BOOT"
assert_block "SlashCommand"            '{"tool":"SlashCommand","input":{"command":"/x"}}'                            "$HOOK_BOOT"

# Fail-closed surfaces
assert_block "malformed JSON"          'not json'                                                                    "$HOOK_BOOT"
assert_block "empty payload"           ''                                                                            "$HOOK_BOOT"
assert_block "unknown tool unknown tgt" '{"tool":"Frobnicate","input":{"file_path":"x"}}'                            "$HOOK_BOOT"

# ALLOW — Phase 0 bootstrap whitelist
assert_allow "Read CLAUDE.md"          '{"tool":"Read","input":{"file_path":"CLAUDE.md"}}'                           "$HOOK_BOOT"
assert_allow "Read core-laws"          '{"tool":"Read","input":{"file_path":".claude/protocols/core-laws.md"}}'      "$HOOK_BOOT"
assert_allow "Read prompt-intake tmpl" '{"tool":"Read","input":{"file_path":".claude/resources/prompt-intake.md"}}'  "$HOOK_BOOT"
assert_allow "Read task template"      '{"tool":"Read","input":{"file_path":".claude/resources/task.md"}}'           "$HOOK_BOOT"
assert_allow "Glob protocols"          '{"tool":"Glob","input":{"pattern":".claude/protocols/*.md"}}'                "$HOOK_BOOT"
assert_allow "Write prompt_intake"     '{"tool":"Write","input":{"file_path":".claude/artifacts/prompt_intake.md"}}' "$HOOK_BOOT"

# === enforce-boot-gate: with prompt_intake.md ===
touch "$TMP/.claude/artifacts/prompt_intake.md"
assert_allow "Read after intake"       '{"tool":"Read","input":{"file_path":"resume_html/resume_template.md"}}'      "$HOOK_BOOT"
assert_allow "Write after intake"      '{"tool":"Write","input":{"file_path":"resume_html/out.html"}}'               "$HOOK_BOOT"

# === enforce-phase-gate: Read/Glob extension ===
rm -f "$TMP/.claude/artifacts/task.md"
assert_allow "phase: sandbox read"        '{"tool":"Read","input":{"file_path":".claude/artifacts/prompt_intake.md"}}'  "$HOOK_PHASE"
assert_allow "phase: protocol read"       '{"tool":"Read","input":{"file_path":".claude/protocols/core-laws.md"}}'      "$HOOK_PHASE"
assert_allow "phase: protocol glob"       '{"tool":"Glob","input":{"pattern":".claude/protocols/*.md"}}'                "$HOOK_PHASE"
assert_block "phase: source read no task" '{"tool":"Read","input":{"file_path":"src/main.py"}}'                         "$HOOK_PHASE"
assert_block "phase: source glob no task" '{"tool":"Glob","input":{"pattern":"src/*.py"}}'                              "$HOOK_PHASE"
touch "$TMP/.claude/artifacts/task.md"
assert_allow "phase: source read w/ task" '{"tool":"Read","input":{"file_path":"src/main.py"}}'                         "$HOOK_PHASE"
assert_allow "phase: source glob w/ task" '{"tool":"Glob","input":{"pattern":"src/*.py"}}'                              "$HOOK_PHASE"

if (( fail )); then
  echo "BOOT-GATE VALIDATOR: FAIL"
  exit 1
fi
echo "BOOT-GATE VALIDATOR: PASS"
