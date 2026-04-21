<protocol_framework name="external">

<meta>
  <id>"external"</id>
  <description>"Gatekeeper for external CLI integrations (Shopify, Clasp, etc.)."</description>
  <globs>[]</globs>
  <alwaysApply>false</alwaysApply>
  <tags>["type:protocol", "external", "cli", "gatekeeper"]</tags>
  <priority>"LOW"</priority>
  <version>"1.0.0"</version>
</meta>

<axiom_core>

### EXTERNAL CLI GATEKEEPER

<scope>Defines safety latches for high-risk external CLI tools to prevent data loss or production outages.</scope>

#### 1. Shopify CLI

**Risk:** CRITICAL | **Trigger:** Targeting LIVE THEME | **Action:** BLOCK
**Override:** User must set `FORCE_LIVE_THEME=true` in current turn + agent prompts: "WARNING: You are targeting the LIVE THEME."

#### 2. Google Clasp

**Risk:** HIGH | **Trigger:** `clasp push` (Overwrite Remote) | **Action:** BLOCK
**Override:** User must set `FORCE_CLASP_OVERWRITE=true`.

</axiom_core>
<authority_matrix>

### APPROVAL & BLOCK AUTHORITY

<scope>Defines who has authority to approve or block external CLI operations and the source of each gate.</scope>

#### 3. Authority Matrix

- **Approval Source:** USER (explicit instructions). **Block Source:** SYSTEM (failsafe by default).

</authority_matrix>
<compliance_testing>

### TEST VECTORS

<scope>Deterministic test cases to verify gate enforcement for each registered external CLI tool.</scope>

#### 4. Test Vectors

- **Clasp:** Trigger `clasp push` without `FORCE_CLASP_OVERWRITE=true`. Expected: HALT.
- **Shopify:** Trigger push to live theme without `FORCE_LIVE_THEME=true`. Expected: BLOCK + WARNING prompt.

</compliance_testing>

<cache_control />

</protocol_framework>
