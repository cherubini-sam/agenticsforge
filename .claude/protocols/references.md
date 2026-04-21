<protocol_framework name="references">

<meta>
  <id>"references"</id>
  <description>"Forbidden patterns and execution checklist for agent-produced scripts."</description>
  <globs>[]</globs>
  <alwaysApply>false</alwaysApply>
  <tags>["type:protocol", "scripts", "references", "constraints"]</tags>
  <priority>"LOW"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### SCRIPT CONSTRAINTS (Strict Enforcement)

<scope>Forbidden patterns for all agent-produced scripts to ensure portability, safety, and Law 11 compliance.</scope>

- **No Git Operations:** Scripts never commit/push. Agent handles VCS.
- **No Hard Paths:** Use `os.getcwd()` or relative paths.
- **No User Interaction:** Use `argparse`, never `input()`.
- **No Placeholders:** Full implementation only (Law 11).

</axiom_core>
<authority_matrix>

### SCRIPT LIFECYCLE AUTHORITY

<scope>Defines the operational lifecycle and exit code contract for all agent-produced scripts.</scope>

#### Script Lifecycle

1. Delete one-time scripts after successful execution.
2. Exit codes: 0 = success | 1 = error | 2 = validation failure.

</authority_matrix>
<compliance_testing>

### EXECUTION CHECKLIST

<scope>Pre-execution verification steps to confirm script compliance before running.</scope>

- [ ] **Check 1:** No hardcoded paths (`os.getcwd()` or relative only).
- [ ] **Check 2:** No `input()` calls — all inputs via `argparse`.
- [ ] **Check 3:** No placeholder markers (`TODO`, `...`, `TBD`).
- [ ] **Check 4:** Exit codes match contract (0/1/2).

</compliance_testing>

<cache_control />

</protocol_framework>
