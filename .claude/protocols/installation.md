---
description: "Installation modes, resolution order, artifact sandbox rules, and native Claude Code load table."
---

## GLOBAL INSTALLATION

This protocol system supports two installation modes:

### Resolution Order

When reading `.claude/` paths (protocols, resources, skills, agents, rules), resolve in this order:

1. **Project-local**: `${CLAUDE_PROJECT_DIR}/.claude/` — if the project has its own `.claude/protocols/` directory, use project-local files. This allows per-project overrides.
2. **Global fallback**: `${HOME}/.claude/` — if no project-local `.claude/protocols/` exists, use the global installation.

This resolution applies to ALL `.claude/` subdirectories: `protocols/`, `resources/`, `skills/`, `agents/`, `rules/`, `hooks/`.

### Artifact Sandbox

`.claude/artifacts/` is ALWAYS project-local (`${CLAUDE_PROJECT_DIR}/.claude/artifacts/`), even when the rest of `.claude/` is global. Each project gets its own scratch space. The `session-bootstrap.sh` hook creates it automatically.

### settings.json Dual-Mode

- `~/.claude/settings.json` — global config. Hook paths use `${HOME}/.claude/hooks/`.
- `<project>/.claude/settings.json` — project override. Hook paths use `${CLAUDE_PROJECT_DIR}/.claude/hooks/`. Claude Code merges natively; project settings win on conflict.

### What Claude Code Loads Natively

| Location                   | Loaded by Claude Code          | Notes                             |
| :------------------------- | :----------------------------- | :-------------------------------- |
| `~/.claude/CLAUDE.md`      | Yes — global instructions      | Always loaded                     |
| `~/.claude/rules/*.md`     | Yes — global rules             | Always loaded                     |
| `~/.claude/agents/*.md`    | Yes — global agent definitions | Always loaded                     |
| `~/.claude/settings.json`  | Yes — global settings + hooks  | Always loaded                     |
| `~/.claude/protocols/*.md` | No — read on-demand by agent   | Agent uses resolution order above |
| `~/.claude/resources/*.md` | No — read on-demand by agent   | Agent uses resolution order above |
| `~/.claude/skills/`        | No — read on-demand by agent   | Agent uses resolution order above |
