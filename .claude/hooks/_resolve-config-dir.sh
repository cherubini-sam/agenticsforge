#!/usr/bin/env bash
# Shared helper: resolve CLAUDE_CONFIG_DIR (rename-agnostic two-probe, fail-closed).
# Source this from other hooks via: source "$(dirname "$0")/_resolve-config-dir.sh"
#
# Exports:
#   CLAUDE_CONFIG_DIR  — the config root, probed under both the canonical and the
#                        interim layer name; never a global or guessed path.
#   CLAUDE_ARTIFACT_DIR — always project-local .claude/artifacts/. This SANDBOX path is
#                        invariant under any config-tree rename and is never probed.
#
# Detection contract (ordered, two probes, no global fallback):
#   1. ${CLAUDE_PROJECT_DIR}/.claude                       — canonical layout, probed FIRST.
#   2. ${CLAUDE_PROJECT_DIR}/.claude_agentics_forge_layer   — interim layout, probed SECOND.
#   3. Neither presents the expected config layout (a protocols/ subdirectory): print a
#      prescriptive error naming both probed absolute paths and exit 1, exporting NOTHING.
#      There is no ${HOME} fallback and no guessed export.
set -euo pipefail

_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [[ -d "${_PROJECT_DIR}/.claude/protocols" ]]; then
  CLAUDE_CONFIG_DIR="${_PROJECT_DIR}/.claude"
elif [[ -d "${_PROJECT_DIR}/.claude_agentics_forge_layer/protocols" ]]; then
  CLAUDE_CONFIG_DIR="${_PROJECT_DIR}/.claude_agentics_forge_layer"
else
  echo "_resolve-config-dir: no governance config root found. Probed, in order:" >&2
  echo "  1. ${_PROJECT_DIR}/.claude" >&2
  echo "  2. ${_PROJECT_DIR}/.claude_agentics_forge_layer" >&2
  echo "Expected layout marker: a 'protocols/' subdirectory under one of the paths above." >&2
  echo "To fix: set CLAUDE_PROJECT_DIR to the repository root that holds the governance tree." >&2
  exit 1
fi

CLAUDE_ARTIFACT_DIR="${_PROJECT_DIR}/.claude/artifacts"

export CLAUDE_CONFIG_DIR
export CLAUDE_ARTIFACT_DIR
