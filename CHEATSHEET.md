# Agentics Forge — Developer Cheatsheet

A quick-reference guide for installing, configuring, and working with the Agentics Forge governance layer inside Claude Code.

## Table of Contents

- [Agentics Forge — Developer Cheatsheet](#agentics-forge--developer-cheatsheet)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Install — Project-Local](#install--project-local)
  - [Install — Global](#install--global)
  - [Install — Hybrid](#install--hybrid)
    - [Verify the Install](#verify-the-install)
  - [CLAUDE.md Resolution Order](#claudemd-resolution-order)
  - [Settings Scopes](#settings-scopes)
    - [Canonical `.claude/settings.json`](#canonical-claudesettingsjson)
  - [Hooks Configuration](#hooks-configuration)
  - [Pre-commit Hooks](#pre-commit-hooks)
  - [Conventional Commits Protocol](#conventional-commits-protocol)
  - [GitOps Anti-Patterns](#gitops-anti-patterns)

---

## Prerequisites

| Tool        | Min Version | Install                                                                                |
| :---------- | :---------- | :------------------------------------------------------------------------------------- |
| Claude Code | latest      | `npm install -g @anthropic-ai/claude-code` |

> **Claude Code is required.** Agentics Forge does not work properly with the raw Anthropic API or any other AI tool.

---

## Install — Project-Local

Governance layer lives in the repo. Committed to git and shared with the team.

```bash
git clone https://github.com/cherubini-sam/agenticsforge.git /tmp/agenticsforge

cp -r /tmp/agenticsforge/.claude   /path/to/your-project/
cp    /tmp/agenticsforge/CLAUDE.md /path/to/your-project/CLAUDE.md
```

Add to your project's `.gitignore`:

```
.claude/artifacts/*
!.claude/artifacts/.gitignore
.claude/settings.local.json
CLAUDE.local.md
```

Activate hooks:

```bash
cd /path/to/your-project
git config core.hooksPath .githooks   # commit-msg enforcement
poetry install
pre-commit install
```

---

## Install — Global

Install once. Every Claude Code session on your machine loads this protocol automatically.

```bash
cp -r ~/.claude ~/.claude.bak        # backup existing config first

cp -r /tmp/agenticsforge/.claude/. ~/.claude/
cp    /tmp/agenticsforge/CLAUDE.md   ~/.claude/CLAUDE.md

# Rewrite hook paths from project-scope to global-scope
sed -i.bak 's|${CLAUDE_PROJECT_DIR}|${HOME}|g' ~/.claude/settings.json
```

> **Why the `sed`?** The bundled `.claude/settings.json` references hooks via `${CLAUDE_PROJECT_DIR}/.claude/hooks/...` — correct when installed inside a project, but `${CLAUDE_PROJECT_DIR}` is undefined for a global install. Replacing it with `${HOME}` makes every hook resolve to `~/.claude/hooks/...`, which is the canonical global location. Skip this step and the hooks will silently no-op.

---

## Install — Hybrid

Protocol core globally, per-project extensions per repo. Recommended for multi-project setups.

```bash
# Step 1 — Core protocol globally
cp -r /tmp/agenticsforge/.claude/protocols ~/.claude/protocols
cp -r /tmp/agenticsforge/.claude/agents    ~/.claude/agents
cp -r /tmp/agenticsforge/.claude/rules     ~/.claude/rules
cp -r /tmp/agenticsforge/.claude/hooks     ~/.claude/hooks
cp    /tmp/agenticsforge/CLAUDE.md         ~/.claude/CLAUDE.md

# Step 2 — Per-project extensions (skills, project-specific rules)
mkdir -p .claude/{skills,rules,artifacts}

# Add project-specific rules
cp /tmp/agenticsforge/.claude/rules/stack.md .claude/rules/stack.md
```

### Verify the Install

```bash
cd /path/to/your-project
claude
```

Turn 0 should output Tier 1 + Tier 2 JSON as the **first output**. The `target_agent: "PROTOCOL"` line confirms the boot protocol loaded correctly.

---

## CLAUDE.md Resolution Order

Claude Code walks up the directory tree and **concatenates** all discovered files. Project rules extend global rules — they do not replace them.

| Priority    | Location                               | Scope                        | Committed       |
| :---------- | :------------------------------------- | :--------------------------- | :-------------- |
| 1 (highest) | Managed policy                         | Org-wide enforcement         | IT / org admin  |
| 2           | `~/.claude/CLAUDE.md`                  | All projects on your machine | Personal        |
| 3           | `./CLAUDE.md` or `./.claude/CLAUDE.md` | This project — team shared   | Yes             |
| 4 (lowest)  | `./CLAUDE.local.md`                    | Personal project overrides   | No — gitignored |

---

## Settings Scopes

Claude Code merges settings from four scopes. Later scopes override earlier ones on conflict.

| Scope   | File                          | Committed         | Use for                               |
| :------ | :---------------------------- | :---------------- | :------------------------------------ |
| Managed | Org-enforced                  | Org admin         | Enterprise policy                     |
| User    | `~/.claude/settings.json`     | Personal machine  | Personal defaults across all projects |
| Project | `.claude/settings.json`       | Yes — team shared | Hooks, permissions, shared config     |
| Local   | `.claude/settings.local.json` | No — gitignored   | Personal project-level overrides      |

### Canonical `.claude/settings.json`

This is the deliverable form bundled with Agentics Forge. For a global install, rewrite `${CLAUDE_PROJECT_DIR}` → `${HOME}` (see [Install — Global](#install--global)).

```json
{
  "env": {
    "CLAUDE_CODE_THINKING_ENABLED": "true",
    "CLAUDE_CODE_THINKING_LEVEL": "medium",
    "ANTHROPIC_REASONING_EFFORT": "medium"
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/session-bootstrap.sh", "timeout": 15000 },
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/validate-skills.sh", "timeout": 15000 }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/enforce-boot-gate.sh", "timeout": 10000 }
        ]
      },
      {
        "matcher": "Bash|Write|Edit|MultiEdit|Agent|Task",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-destructive.sh", "timeout": 10000 }
        ]
      },
      {
        "matcher": "Read|Glob|Grep|Bash|Write|Edit|MultiEdit|Agent|Task|WebSearch|WebFetch",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/enforce-phase-gate.sh", "timeout": 10000 }
        ]
      },
      {
        "matcher": "Agent|Task",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/enforce-spawn-transparency.sh", "timeout": 10000 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/format-code.sh", "timeout": 30000 },
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/verify-tests.sh", "timeout": 60000 }
        ]
      }
    ],
    "Stop": []
  }
}
```

---

## Hooks Configuration

| Hook                            | Trigger                              | Effect                                                                                          |
| :------------------------------ | :----------------------------------- | :---------------------------------------------------------------------------------------------- |
| `session-bootstrap.sh`          | SessionStart                         | Creates `.claude/artifacts/` sandbox; initialises session state                                 |
| `validate-skills.sh`            | SessionStart                         | Validates `triggers.json` schema; warns on malformed skill entries                              |
| `enforce-boot-gate.sh`          | PreToolUse — all tools               | Blocks every tool call until `.claude/artifacts/prompt_intake.md` exists                        |
| `enforce-phase-gate.sh`         | PreToolUse — read/write/exec tools   | Blocks tool calls until `task.md` (Phase 1) and `implementation_plan.md` (Phase 3) exist        |
| `block-destructive.sh`          | PreToolUse — Bash/Write/Edit/Agent   | Blocks `rm -rf /`, `git push --force`, writes to `main`/`master`, `--no-verify`                 |
| `enforce-spawn-transparency.sh` | PreToolUse — `Agent` / `Task`        | Blocks sub-agent spawns missing the `sub_agent_spawn` JSON block (Law 1 extension)              |
| `format-code.sh`                | PostToolUse — Write/Edit/MultiEdit   | Auto-formats changed files via the project's configured formatter                              |
| `verify-tests.sh`               | PostToolUse — Write/Edit/MultiEdit   | Runs the test suite after source writes; surfaces failures immediately                          |

PreToolUse hooks use exit code `2` to hard-block (Claude Code stops the tool call). Exit code `0` allows.

---

## Pre-commit Hooks

| Hook                      | Action                           |
| :------------------------ | :------------------------------- |
| `trailing-whitespace`     | Strips trailing whitespace       |
| `end-of-file-fixer`       | Ensures newline at EOF           |
| `check-yaml`              | Validates YAML syntax            |
| `check-added-large-files` | Blocks files > 1 MB              |
| `check-merge-conflict`    | Detects unresolved merge markers |
| `debug-statements`        | Detects Python debug statements  |

```bash
# Run all hooks manually
pre-commit run --all-files

# Run a specific hook
pre-commit run check-yaml --all-files

# Update hook revisions
pre-commit autoupdate
```

---

## Conventional Commits Protocol

| Prefix      | Meaning                                         | Semantic Version |
| :---------- | :---------------------------------------------- | :--------------- |
| `feat:`     | New feature                                     | MINOR bump       |
| `fix:`      | Bug patch                                       | PATCH bump       |
| `docs:`     | Documentation only                              | —                |
| `style:`    | Whitespace / formatting, no logic change        | —                |
| `refactor:` | Code restructure without API or behavior change | —                |
| `test:`     | Add or correct tests                            | —                |
| `chore:`    | Maintenance, dependency updates, build process  | —                |
| `perf:`     | Performance improvement                         | PATCH bump       |
| `ci:`       | CI/CD pipeline changes                          | —                |
| `build:`    | Build system changes                            | —                |

Commit message format enforced by `.githooks/commit-msg`:

```
{prefix}[(optional-scope)]: {Capital sentence ending with a period.}
```

Rules enforced by `.githooks/commit-msg`: single line · 50–500 characters · capital first word · trailing period.

---

## GitOps Anti-Patterns

| Anti-pattern                                    | Why it fails                                                                        |
| :---------------------------------------------- | :---------------------------------------------------------------------------------- |
| Writing to `main`/`master` directly             | `block-destructive.sh` rejects every tool call while HEAD is on a protected branch  |
| `git commit --no-verify`                        | Bypasses `enforce-boot-gate.sh` and `enforce-phase-gate.sh` — blocked by protocol   |
| Skipping `prompt_intake.md` creation            | `enforce-boot-gate.sh` blocks all tool calls until Phase 0(b) completes             |
| Typing `yes` before confidence 1.00             | Phase 4 requires BOTH conditions: REFLECTOR confidence 1.00 AND explicit user `yes` |
| Committing `.claude/artifacts/`                 | Gitignored by design — ephemeral artifacts are never tracked                        |
| Narrowing `.gitignore` for `.claude/artifacts/` | Violates Law 5 (Total Containment) — restore the blanket exclusion                  |
