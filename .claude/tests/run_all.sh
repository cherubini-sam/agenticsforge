#!/usr/bin/env bash
# Governance-layer verification suite.
#
# Persists, as ONE runnable suite, the assertions this hardening cycle used:
#   V-1  Layer is LIVE            — every settings.json command resolves to an existing file.
#   V-2  No global bleed          — a three-arm CONJUNCTION (a) + (a2) + (b):
#          (a)  no CONFIG-family .claude/<config-subdir> literal survives in the hook tree
#          (a2) the only file naming both layer literals is the resolver's own probe
#          (b)  the SANDBOX .claude/artifacts population is unchanged (non-regression)
#   V-2c Resolver fails closed    — no config root => non-zero exit, nothing exported,
#                                    and no ${HOME}/.claude path printed.
#   V-3  No false block           — a truthful current-shard Tier 1 payload is ALLOWED and a
#                                    bogus-shard payload is BLOCKED. BOTH directions.
#   SYN  Syntax floor             — bash -n over every .sh in the tree.
#   SMK  Smoke harness            — every wired hook executes (delegates to smoke_hooks.sh).
#
# Properties this file guarantees:
#   (a) exits 0 only on total success; on any failure exits non-zero and prints a
#       per-check diagnostic naming the failing check with observed-vs-expected values.
#   (b) invocable from the repository root (or from anywhere — it self-locates).
#   (c) RENAME-AGNOSTIC. It finds its own tree via a BASH_SOURCE self-locating walk and
#       contains NO layer-directory literal in any check it performs. The identical file
#       therefore runs correctly both before and after the governance layer is renamed.
#       This is load-bearing: the final shipping layout is verified by running THIS file
#       after the rename, unsupervised.
#   (d) every baseline is derived at run time. There are no hardcoded path-count literals.
#
# Exit 0 = all checks green. Exit 1 = at least one check failed.
set -uo pipefail

# --- Self-location (rename-agnostic; no layer-name literal) ------------------
_SELF="${BASH_SOURCE[0]}"
while [ -L "$_SELF" ]; do
  _LINK="$(readlink "$_SELF")"
  case "$_LINK" in
    /*) _SELF="$_LINK" ;;
    *)  _SELF="$(cd -P "$(dirname "$_SELF")" && pwd)/$_LINK" ;;
  esac
done
TESTS_DIR="$(cd -P "$(dirname "$_SELF")" && pwd)"
CONFIG_DIR="$(cd -P "$TESTS_DIR/.." && pwd)"
PROJECT_DIR="$(cd -P "$CONFIG_DIR/.." && pwd)"

# The layer's own directory NAME, derived — never written as a literal.
CONFIG_REL="$(basename "$CONFIG_DIR")"

HOOKS_DIR="$CONFIG_DIR/hooks"
SETTINGS="$CONFIG_DIR/settings.json"
RESOLVER="$HOOKS_DIR/_resolve-config-dir.sh"
TIER_HOOK="$HOOKS_DIR/validate-tier-json.sh"
SMOKE="$TESTS_DIR/smoke_hooks.sh"

export CLAUDE_PROJECT_DIR="$PROJECT_DIR"

PASSED=0
FAILED=0
FAILED_NAMES=""

pass() {
  PASSED=$((PASSED + 1))
  printf '  [ PASS ] %s\n' "$1"
}

fail() {
  # fail <check-name> <expected> <observed>
  FAILED=$((FAILED + 1))
  FAILED_NAMES="$FAILED_NAMES
    - $1"
  printf '  [ FAIL ] %s\n' "$1"
  printf '           expected: %s\n' "$2"
  printf '           observed: %s\n' "$3"
}

echo "======================================================================"
echo " Governance layer verification suite"
echo "   project root : $PROJECT_DIR"
echo "   config root  : $CONFIG_DIR"
echo "   layer name   : $CONFIG_REL  (derived at run time)"
echo "======================================================================"

# --- Preconditions -----------------------------------------------------------
echo
echo "[PRE] Tree preconditions"
for required in "$SETTINGS" "$RESOLVER" "$TIER_HOOK" "$SMOKE"; do
  if [ -f "$required" ]; then
    pass "present: ${required#$PROJECT_DIR/}"
  else
    fail "present: ${required#$PROJECT_DIR/}" "file exists" "missing"
  fi
done

# --- V-1: layer is LIVE ------------------------------------------------------
# Every command in settings.json must resolve, after ${CLAUDE_PROJECT_DIR}
# substitution, to a file that exists on disk. Counts are derived, not asserted
# against a literal.
echo
echo "[V-1] Layer is LIVE — every settings.json command resolves to an existing file"
V1_OUT="$(/usr/bin/python3 - "$SETTINGS" "$PROJECT_DIR" <<'PY'
import json, os, sys
settings_path, project_dir = sys.argv[1], sys.argv[2]
try:
    with open(settings_path) as fh:
        data = json.load(fh)
except Exception as exc:
    print("PARSE_ERROR\t0\t0\t%s" % exc)
    raise SystemExit(0)
commands = [
    hook.get("command", "")
    for groups in (data.get("hooks") or {}).values()
    for group in (groups or [])
    for hook in (group.get("hooks") or [])
    if hook.get("command")
]
missing = [
    c for c in commands
    if not os.path.isfile(c.replace("${CLAUDE_PROJECT_DIR}", project_dir))
]
print("OK\t%d\t%d\t%s" % (len(commands), len(missing), ",".join(missing)))
PY
)"
V1_STATUS="$(printf '%s' "$V1_OUT" | cut -f1)"
V1_TOTAL="$(printf '%s' "$V1_OUT" | cut -f2)"
V1_MISSING="$(printf '%s' "$V1_OUT" | cut -f3)"
V1_LIST="$(printf '%s' "$V1_OUT" | cut -f4)"

if [ "$V1_STATUS" != "OK" ]; then
  fail "V-1 settings.json parses" "valid JSON" "parse error: $V1_LIST"
elif [ "$V1_TOTAL" -eq 0 ]; then
  fail "V-1 settings.json wires hooks" "at least 1 wired command" "0 commands found"
elif [ "$V1_MISSING" -ne 0 ]; then
  fail "V-1 all wired commands resolve" "0 unresolvable of $V1_TOTAL" "$V1_MISSING unresolvable: $V1_LIST"
else
  pass "V-1 all $V1_TOTAL wired commands resolve to existing files"
fi

# --- V-2 arm (a): CONFIG family fully routed --------------------------------
# No hook may reference .claude/<config-subdir>. The sandbox subdir (artifacts)
# is deliberately excluded from this pattern — it is the SANDBOX family.
echo
echo "[V-2a] CONFIG family fully routed — no .claude/<config-subdir> literal in hooks"
# The resolver is EXEMPT by definition: its whole job is to probe both candidate
# directory names, so it is the one file that must name them literally. Every
# other hook must reach CONFIG paths through the resolver's exported variable.
V2A_HITS="$(
  grep -rn '\.claude/\(hooks\|resources\|protocols\|rules\|agents\|skills\|tests\)' "$HOOKS_DIR" 2>/dev/null \
    | grep -v '/_resolve-config-dir\.sh:' || true
)"
V2A_COUNT="$(printf '%s' "$V2A_HITS" | grep -c . || true)"
if [ "${V2A_COUNT:-0}" -eq 0 ]; then
  pass "V-2a zero CONFIG-family literals in the hook tree"
else
  fail "V-2a zero CONFIG-family literals in the hook tree" "0 matches" "$V2A_COUNT matches: $(printf '%s' "$V2A_HITS" | head -3 | tr '\n' ' ')"
fi

# --- V-2 arm (a2): only the resolver names the INTERIM layer literal ---------
# Invariant asserted, identically under BOTH layouts: the INTERIM layer
# directory name appears in at most ONE file under the hooks tree —
# _resolve-config-dir.sh, which must name both candidates by definition.
#
# Why $CONFIG_REL CANNOT be used as the search term here:
#   $CONFIG_REL is the directory the layer CURRENTLY occupies. After the rename
#   it becomes the canonical sandbox-sharing name, so grepping for
#   "$CONFIG_REL/" would match every legitimate .claude/artifacts SANDBOX line
#   in the hook tree and report a tree-wide failure that does not exist. The
#   SANDBOX family is REQUIRED to appear literally (AD-1 exception 2). This arm
#   is about the INTERIM name only, which is why it is derived independently of
#   whichever name the tree happens to carry right now.
#
# The interim name is derived from the resolver's own two-probe candidate list —
# the resolver is the one file that legitimately contains it — so this check
# carries no directory literal of its own and is correct pre- and post-rename.
echo
echo "[V-2a2] Only the resolver names the interim layer literal"
V2A2_INTERIM="$(
  grep -o '\${_PROJECT_DIR}/\.[A-Za-z0-9_.-]*' "$RESOLVER" 2>/dev/null \
    | sed 's|\${_PROJECT_DIR}/||' \
    | sort -u \
    | grep -v '^\.claude$' \
    | head -1 || true
)"

if [ -z "$V2A2_INTERIM" ]; then
  # No interim candidate in the resolver means the rename is fully complete and
  # the resolver probes a single canonical name. Nothing to leak: vacuously true.
  pass "V-2a2 resolver declares no interim layer literal (rename complete)"
else
  V2A2_HITS="$(
    grep -rl -- "$V2A2_INTERIM" "$HOOKS_DIR" 2>/dev/null \
      | grep -v '_resolve-config-dir\.sh$' || true
  )"
  V2A2_COUNT="$(printf '%s' "$V2A2_HITS" | grep -c . || true)"
  if [ "${V2A2_COUNT:-0}" -eq 0 ]; then
    pass "V-2a2 interim literal ($V2A2_INTERIM) confined to _resolve-config-dir.sh"
  else
    fail "V-2a2 interim literal ($V2A2_INTERIM) confined to _resolve-config-dir.sh" \
         "0 other files naming it" \
         "$V2A2_COUNT: $(printf '%s' "$V2A2_HITS" | sed "s|^$PROJECT_DIR/||" | tr '\n' ' ')"
  fi
fi

# --- V-2 arm (b): SANDBOX family untouched (non-regression) -----------------
# Baseline is DERIVED at run time from the committed tree via git, never a
# hardcoded literal. When git cannot supply a baseline (no repo, or the tree is
# untracked), the arm degrades to a presence assertion and says so — it never
# silently invents a number.
echo
echo "[V-2b] SANDBOX family non-regression — .claude/artifacts population unchanged"
V2B_NOW="$(grep -rn '\.claude/artifacts' "$HOOKS_DIR" 2>/dev/null | grep -c . || true)"
V2B_NOW="${V2B_NOW:-0}"
V2B_BASE=""
if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  # The layer may be tracked at HEAD under a DIFFERENT directory name than it
  # currently carries (that is exactly what a rename means). Probe the current
  # name first, then fall back to any other top-level governance tree at HEAD,
  # so the baseline survives the rename in both directions. Still zero literals:
  # the candidate names are read from the tree itself.
  for _cand in "$CONFIG_REL" $(
        git -C "$PROJECT_DIR" ls-tree HEAD --name-only 2>/dev/null \
          | grep '^\.claude' || true
      ); do
    _n="$(
      git -C "$PROJECT_DIR" grep -h --no-color -n '\.claude/artifacts' \
          HEAD -- "$_cand/hooks" 2>/dev/null | grep -c . || true
    )"
    if [ "${_n:-0}" -gt 0 ] 2>/dev/null; then
      V2B_BASE="$_n"
      break
    fi
  done
fi

if [ -n "$V2B_BASE" ] && [ "$V2B_BASE" -gt 0 ] 2>/dev/null; then
  if [ "$V2B_NOW" -eq "$V2B_BASE" ]; then
    pass "V-2b SANDBOX population unchanged vs HEAD ($V2B_NOW refs)"
  else
    fail "V-2b SANDBOX population unchanged vs HEAD" "$V2B_BASE refs (HEAD baseline)" "$V2B_NOW refs (working tree)"
  fi
elif [ "$V2B_NOW" -gt 0 ]; then
  pass "V-2b SANDBOX family present ($V2B_NOW refs; no HEAD baseline available, presence-only)"
else
  fail "V-2b SANDBOX family present" "at least 1 .claude/artifacts reference" "0 references"
fi

# --- V-2 arm (c): resolver fails closed -------------------------------------
echo
echo "[V-2c] Resolver fails closed — no config root => non-zero exit, no HOME fallback"
V2C_ERR="$(CLAUDE_PROJECT_DIR=/tmp/nonexistent-governance-probe bash "$RESOLVER" 2>&1 >/dev/null || true)"
CLAUDE_PROJECT_DIR=/tmp/nonexistent-governance-probe bash "$RESOLVER" >/dev/null 2>&1
V2C_STATUS=$?
if [ "$V2C_STATUS" -eq 0 ]; then
  fail "V-2c resolver exits non-zero on total miss" "non-zero exit" "exit 0 (fail-open)"
else
  pass "V-2c resolver exits non-zero on total miss (exit $V2C_STATUS)"
fi

if printf '%s' "$V2C_ERR" | grep -q "$HOME/.claude"; then
  fail "V-2c resolver prints no HOME fallback path" "no \$HOME/.claude in stderr" "HOME path present in stderr"
else
  pass "V-2c resolver prints no \$HOME/.claude fallback path"
fi

V2C_HOMEREFS="$(grep -c 'HOME.*\.claude' "$RESOLVER" || true)"
if [ "${V2C_HOMEREFS:-0}" -eq 0 ]; then
  pass "V-2c resolver source carries zero HOME/.claude references"
else
  fail "V-2c resolver source carries zero HOME/.claude references" "0 occurrences" "$V2C_HOMEREFS occurrences"
fi

# --- V-3: no false block, BOTH directions -----------------------------------
echo
echo "[V-3] No false block — truthful current-shard ALLOWED, bogus shard BLOCKED"
tier_payload() {
  # tier_payload <model_shard> <thinking_level>
  /usr/bin/python3 - "$1" "$2" <<'PY'
import json, sys
shard, thinking = sys.argv[1], sys.argv[2]
tier1 = {
    "target_agent": "MANAGER",
    "intent": "verification_probe",
    "reasoning": "suite probe for shard enum acceptance",
    "confidence": 1.0,
    "model_shard": shard,
    "thinking_level": thinking,
    "language_check": "EN",
    "persona": "EN-SeniorPeer",
    "mode": "Plan",
    "loaded_skills": [],
}
text = "```json\n" + json.dumps(tier1) + "\n```"
print(json.dumps({
    "tool_name": "Read",
    "tool_input": {"file_path": "README.md"},
    "assistant_message": {"content": [{"type": "text", "text": text}]},
}))
PY
}

tier_payload "claude-opus-5" "xhigh" | bash "$TIER_HOOK" >/dev/null 2>&1
V3_TRUE=$?
if [ "$V3_TRUE" -eq 0 ]; then
  pass "V-3 truthful payload (claude-opus-5 / xhigh) ALLOWED (exit 0)"
else
  fail "V-3 truthful payload ALLOWED" "exit 0" "exit $V3_TRUE — current shard is falsely blocked"
fi

tier_payload "claude-bogus-99" "xhigh" | bash "$TIER_HOOK" >/dev/null 2>&1
V3_BOGUS=$?
if [ "$V3_BOGUS" -eq 2 ]; then
  pass "V-3 bogus payload (claude-bogus-99) BLOCKED (exit 2)"
else
  fail "V-3 bogus payload BLOCKED" "exit 2" "exit $V3_BOGUS — enum was widened into a no-op"
fi

# --- SYN: syntax floor -------------------------------------------------------
echo
echo "[SYN] Syntax floor — bash -n over every .sh in the tree"
SYN_TOTAL=0
SYN_BAD=""
while IFS= read -r script; do
  SYN_TOTAL=$((SYN_TOTAL + 1))
  if ! bash -n "$script" 2>/dev/null; then
    SYN_BAD="$SYN_BAD ${script#$PROJECT_DIR/}"
  fi
done < <(find "$CONFIG_DIR" -type f -name '*.sh' 2>/dev/null)

if [ "$SYN_TOTAL" -eq 0 ]; then
  fail "SYN shell scripts discovered" "at least 1 .sh file" "0 found under $CONFIG_DIR"
elif [ -z "$SYN_BAD" ]; then
  pass "SYN all $SYN_TOTAL shell scripts pass bash -n"
else
  fail "SYN all shell scripts pass bash -n" "0 syntax errors of $SYN_TOTAL" "failing:$SYN_BAD"
fi

# --- SMK: smoke harness ------------------------------------------------------
echo
echo "[SMK] Smoke harness — every wired hook executes"
if [ -f "$SMOKE" ]; then
  SMK_OUT="$(bash "$SMOKE" 2>&1)"
  SMK_STATUS=$?
  printf '%s\n' "$SMK_OUT" | sed 's/^/    | /'
  if [ "$SMK_STATUS" -eq 0 ]; then
    pass "SMK every wired hook executed"
  else
    fail "SMK every wired hook executed" "exit 0, 0 CRASHED" "exit $SMK_STATUS — see smoke output above"
  fi
else
  fail "SMK smoke harness present" "smoke_hooks.sh exists" "missing at $SMOKE"
fi

# --- Summary -----------------------------------------------------------------
echo
echo "======================================================================"
echo " SUITE SUMMARY: $PASSED passed, $FAILED failed"
if [ "$FAILED" -ne 0 ]; then
  echo " FAILING CHECKS:$FAILED_NAMES"
  echo "======================================================================"
  exit 1
fi
echo " ALL CHECKS GREEN"
echo "======================================================================"
exit 0
