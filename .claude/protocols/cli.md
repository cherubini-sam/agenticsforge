<protocol_framework name="cli">

<meta>
  <id>"cli"</id>
  <description>"Unified standards for non-interactive CLI execution."</description>
  <globs>[]</globs>
  <alwaysApply>false</alwaysApply>
  <tags>["type:protocol", "cli", "execution", "safety"]</tags>
  <priority>"LOW"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### CLI EXECUTION STANDARDS

<scope>Unified governance for ALL CLI interfaces (Shopify, Clasp, etc.) to ensure Law 19 (Immediate Execution) and Anti-Hang compliance.</scope>

#### 1. Non-Interactive Execution

**FORBIDDEN:** Commands that open a browser (`login`, `auth`) or wait for keyboard input.
**MANDATORY:** Use headless flags (`--force`, `-y`, `--headless`). **TIMEOUT:** Kill processes exceeding 60s without output.

#### 2. Output & Credentials

**Output:** Prefer JSON (`--json`, `--output json`). Minimize terminal noise (Law 19). Redirect `stderr` where appropriate.
**Credentials:** NEVER output to console, markdown, or logs. USE Environment Variables or local ignored config files.

#### 3. Containment (Law 5)

All CLI operations scoped to project root. Block `--root` or `/` level operations unless whitelisted.

</axiom_core>
<authority_matrix>

### TOOL-SPECIFIC REGISTRY

<scope>Per-tool rules and override tokens for authorized CLI integrations.</scope>

#### 4. Tool-Specific Registry

**Clasp:** Mandatory `--force` flag | `clasp status` MUST precede `clasp push` | Auth via `.clasprc.json` only | Restricted to project root.
**Shopify:** Mandatory `--json` + `--store` flags | FORBIDDEN to push to Live Theme ID without explicit override | `--allow-live` blocked without "Override Token".

</authority_matrix>
<compliance_testing>

### TEST VECTORS

<scope>Verification commands to confirm non-interactive compliance for all registered CLI tools.</scope>

#### 5. Test Vector

Execute command with `-y` to verify non-interactive flow.

</compliance_testing>

<cache_control />

</protocol_framework>
