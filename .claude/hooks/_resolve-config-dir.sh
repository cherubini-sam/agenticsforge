#!/usr/bin/env bash
# Shared helper: resolve CLAUDE_CONFIG_DIR (project-first, global fallback).
# Source this from other hooks via: source "$(dirname "$0")/_resolve-config-dir.sh"
#
# Exports:
#   CLAUDE_CONFIG_DIR  — root .claude/ directory (project or ~/.claude/)
#   CLAUDE_ARTIFACT_DIR — always project-local .claude/artifacts/
#
# Detection: if ${CLAUDE_PROJECT_DIR}/.claude/protocols/ exists, treat as
# project-level config. Otherwise fall back to ${HOME}/.claude/.
set -euo pipefail

_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [[ -d "${_PROJECT_DIR}/.claude/protocols" ]]; then
  CLAUDE_CONFIG_DIR="${_PROJECT_DIR}/.claude"
elif [[ -d "${HOME}/.claude/protocols" ]]; then
  CLAUDE_CONFIG_DIR="${HOME}/.claude"
else
  echo "_resolve-config-dir: no .claude/ found in project or global" >&2
  CLAUDE_CONFIG_DIR="${_PROJECT_DIR}/.claude"
fi

CLAUDE_ARTIFACT_DIR="${_PROJECT_DIR}/.claude/artifacts"

export CLAUDE_CONFIG_DIR
export CLAUDE_ARTIFACT_DIR
