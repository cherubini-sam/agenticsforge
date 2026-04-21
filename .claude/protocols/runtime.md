<protocol_framework name="runtime">

<meta>
  <id>"runtime"</id>
  <description>"Consolidated runtime protocols — output stream serialization, output quality, and tool safety with MCP governance."</description>
  <globs>[]</globs>
  <alwaysApply>true</alwaysApply>
  <tags>["type:protocol", "runtime", "timing", "quality", "tools", "safety"]</tags>
  <priority>"HIGH"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

## Output Stream Serialization

<scope>Defines serialization constraints on the output stream to preserve Law 1 (Transparency Lock) against native model tool-call prioritization.</scope>

### Race Condition Fix (Law 1 Preservation)

The `task_boundary` tool is aggressively prioritized by the native model. To preserve Law 1 (Transparency Lock), artificially delay the tool call.

Treat the output stream as a serialized pipe: `[JSON_BLOCK] + [NEWLINE] + [TOOL_CALL]`

**Forbidden:** Calling a tool as the very first token. The first token MUST be the backtick `` ` `` of the JSON block.

**Enforcer:** TARGET AGENT | **Detection:** MANAGER (Audit Trail).

### Enforcement Chain

- **Enforcer:** Target Agent (output stream control).
- **Detector:** MANAGER via Audit Trail.
- **Escalation:** PROTOCOL on confirmed violation → SESSION TERMINATION (Law 39).

## Output Quality

<scope>Defines content depth, writing style, naming conventions, and artifact schemas for all agent-produced output.</scope>

> [!IMPORTANT]
> **Emoji Policy:** STRICTLY FORBIDDEN. **Tone:** Technical, Professional, Zero-Fluff.
> **Input:** `@File` preferred. **Output:** Unified Diff or New File.

### 1. Content Depth (Zero Tolerance)

**Forbidden:** "TODO", "TBD", Placeholders. **Requirement:** Complete, working code/docs.

### 2. Writing Style

**Allowed:** Passive (desc), Active (instr). **Forbidden:** Slang, First-person.

### 3. Naming Conventions

`README.md`: "{Project} Documentation" | `CHEATSHEET.md`: "{Project} Cheatsheet" | `CHANGELOG.md`: "{Project} Changelog"

### 4. Artifact Schemas (JSON Enforced)

- **Session Report:** `executive_summary`, `activities`, `blockers`, `next_steps`, `metrics`.
- **Architecture Decision:** `context`, `decision`, `rationale`, `alternatives`, `consequences`.
- **Conversation Log:** `user_request`, `solution`, `plan`.

### 5. Definition of Done (Strict 6-Phase)

- **Workflow Completion:** All phases (0 through 6) verified.
- **Context Retention:** 100% of artifacts saved.
- **Template Compliance:** Artifacts match `.claude/resources/` definitions exactly.

### 6. Verification Protocol

Before completion: No emojis | Copyright present | No placeholders | Schemas valid | Phase Isolation enforced (Law 33).

## Tool Safety & MCP Governance

<scope>Strict directives for tool invocation and path containment to enforce Law 5 (Containment) and prevent unauthorized writes.</scope>

### File System Operations

**Write Containment:** All generated files MUST be written to the artifact sandbox. Always provide the target path explicitly — never rely on tool defaults.

**Forbidden:** Writing to any path outside the artifact sandbox.

### Safety Check

- **Trigger:** Before any file write operation.
- **Check:** Does the target path resolve to `.claude/artifacts/` (artifact sandbox)?
- **Success:** Path resolves to artifact sandbox → proceed with write.
- **Failure:** Path resolves outside artifact sandbox → STOP. DO NOT execute.
- **Fallback:** Log the attempted path, redirect to artifact sandbox.

### MCP Governance

#### Tool Preference Hierarchy

When a task can be accomplished by multiple tool types, prefer in this order:

1. **Native Claude Code tools** (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`) — zero overhead, maximum token efficiency.
2. **CLI tools via `Bash`** (e.g., `gh` for GitHub, `git` for version control) — lower token cost than MCP servers.
3. **MCP servers** — ONLY when no CLI equivalent exists or the data source is proprietary.

**Rationale:** MCP servers consume context budget for schema transmission at initialization. CLI tools via `Bash` avoid this overhead entirely.

#### Programmatic Tool Calling

For tasks involving large datasets, iterative API pagination, or complex data transformations:

- **FORBIDDEN:** Orchestrating multi-step data loops via LLM natural language reasoning. This creates massive context bloat.
- **REQUIRED:** Write deterministic Python or Bash scripts to handle loops, conditionals, and transformations. Execute via `Bash`. Return only the final distilled result.

#### MCP Schema Mitigation

- Limit connected MCP servers to those actively needed for the current task.
- Use Claude Code's `ToolSearch` to load tool schemas on-demand rather than at initialization.
- After MCP tool execution, clear raw JSON results from context once semantic knowledge is extracted.

#### Context Virtualization (Future)

**Recommendation:** adopt a local indexer MCP (qmd / Context-mode or equivalent) to virtualize large codebases. Instead of streaming whole files into context, the indexer returns ranked excerpts on demand.

**Expected savings:** 40–70% token reduction on exploration-heavy tasks versus streaming `Read`/`Grep` output directly.

**Status:** not yet wired. Evaluate before enabling in `.mcp.json`.

### Error Recovery

#### Search Fail

If a web search fails: retry once with a simpler query. If fail again, proceed with internal knowledge. **DO NOT** output the raw error to the user.

#### Write Fail

If a file is accidentally written outside the artifact sandbox: **MOVE** to artifact sandbox, **DELETE** the misplaced file.

</axiom_core>
<compliance_testing>

### RUNTIME AUDIT

<scope>Consolidated compliance checks for output stream, quality, and tool safety.</scope>

- [ ] **Check 1:** First emitted token is `` ` `` (start of JSON fence), not a tool call handle.
- [ ] **Check 2:** Tool call handle appears AFTER both Tier 1 and Tier 2 JSON blocks.
- [ ] **Check 3:** No emojis, no placeholders, no TODO/TBD in output.
- [ ] **Check 4:** All writes target the artifact sandbox with explicit path.
- [ ] **Check 5:** MCP servers used only when no CLI equivalent exists.

</compliance_testing>

<cache_control />

</protocol_framework>
