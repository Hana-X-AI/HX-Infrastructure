# HX-Infrastructure GitHub Remediation Instructions

**Source:** GitHub Copilot project review dated 2026-08-10  
**Purpose:** Direct the required repository changes identified by the review without expanding project scope.  
**Priority:** Correct automation defects first, then documentation/consistency issues, then establish the initial Git baseline.

---

## 1. Change Control

Apply only the changes required by this remediation document.

Do not:

- change the Phase 1 / Phase 2 project model;
- automate server role assignment;
- begin Phase 2 configuration;
- expose or commit `.env`;
- change active accepted risks unless their documented review trigger has been reached;
- add new orchestration systems, cloud dependencies, or unrelated infrastructure features.

Preserve these project rules:

- Phase 1 is discovery and documentation only.
- Role, workload, and model assignment remain manual.
- `discovery.md` is the immutable as-found record.
- `configuration.md` is a separate Phase 2 artifact.
- Phase 2 remains blocked until the fleet-wide Phase 1 gate is complete.

---

# 2. Required Remediation

## rem-001 — Fix discovery validator zero-problem failure

**Priority:** High  
**Source finding:** Discovery validators crash and fail open when a valid record has zero problems.

### Files

Review and correct:

```text
.claude/hooks/hx-common.ps1
.claude/hooks/hx-validate-discovery.ps1
.claude/hooks/hx-validate-subagent.ps1
claude-hooks/hooks/hx-common.ps1
claude-hooks/hooks/hx-validate-discovery.ps1
claude-hooks/hooks/hx-validate-subagent.ps1
```

### Required change

Ensure callers always receive a stable collection, including when there are zero problems.

Preferred caller pattern:

```powershell
$problems = @(Get-HxDiscoveryProblems $filePath)
```

Equivalent behavior is acceptable if `$problems.Count` is always safe.

### Required tests

Test representative hook payloads for:

1. zero validation problems;
2. one validation problem;
3. multiple validation problems.

For each test, verify:

- process exit code;
- JSON output shape;
- blocking/non-blocking decision;
- no `Set-StrictMode` failure.

### Acceptance criteria

```text
[ ] Valid discovery record does not crash either validator
[ ] Valid discovery record follows the expected success path
[ ] Invalid record is blocked with useful reason
[ ] SubagentStop blocks incomplete discovery
[ ] Active and distributable hook copies are synchronized
```

---

## rem-002 — Close relative-path Phase 1 guard bypass

**Priority:** Medium  
**Source finding:** Shell commands using bare relative paths can write `servers/.../configuration.md` without the Phase 1 hook denying them.

### Files

Review and correct:

```text
.claude/hooks/hx-phase1-guard.ps1
claude-hooks/hooks/hx-phase1-guard.ps1
```

### Required change

Detect writes to Phase 2 configuration files regardless of path form.

The guard must recognize at minimum:

```text
servers/hx-test/configuration.md
servers\hx-test\configuration.md
./servers/hx-test/configuration.md
.\servers\hx-test\configuration.md
"servers/hx-test/configuration.md"
"servers\hx-test\configuration.md"
<absolute-path>/servers/hx-test/configuration.md
```

Do not block unrelated files containing the word `configuration`.

Normalize path separators where practical.

### Regression cases

At minimum test:

```text
echo x > servers/hx-test/configuration.md
Set-Content servers\hx-test\configuration.md x
echo x > ./servers/hx-test/configuration.md
Set-Content .\servers\hx-test\configuration.md x
```

Also verify that:

```text
echo x > servers/hx-test/discovery.md
```

is not blocked solely because it is under `servers/`.

### Documentation

Keep the hook described as **defense in depth**, not a complete sandbox.

Where Claude permission deny rules can provide stronger deterministic enforcement, document that distinction rather than overstating the hook.

### Acceptance criteria

```text
[ ] Bare relative paths are denied
[ ] ./ and .\ paths are denied
[ ] Quoted paths are denied
[ ] Absolute paths are denied
[ ] Unrelated files are not falsely denied
[ ] Active/package hook copies match
```

---

## rem-003 — Establish one canonical Phase 1 gate and independent fleet baseline

**Priority:** Medium

### Problem

The project currently has inconsistent Phase 1 gate checklists and no independent source proving how many servers are expected.

### Required change

Create one canonical Phase 1 gate in:

```text
GOALS-AND-OBJECTIVES.md
```

Other files must reference or reproduce that same checklist without changing its meaning.

At minimum align:

```text
SERVER-REGISTRY.md
.claude/skills/phase1-gate/SKILL.md
CLAUDE.md
```

### Expected fleet baseline

Add an independently approved fleet baseline that is not derived from discovered registry rows.

Keep this simple.

Recommended approach:

```markdown
## Expected Fleet

Expected servers: 15
```

If the server names are already approved, a named list is better. If names are not yet approved, the explicit expected count is sufficient until names are established.

The phase gate must be able to compare:

```text
expected fleet count
vs
registry count
vs
completed discovery count
```

### Canonical gate

The canonical gate must include:

```text
[ ] Every expected server is present in the registry
[ ] Every server has a complete discovery.md
[ ] Fleet hardware capabilities are documented and comparable
[ ] Fleet capabilities have been manually reviewed
[ ] Every server has a manually assigned role
[ ] Every assigned role is recorded in SERVER-REGISTRY.md
[ ] No role-specific configuration has begun
```

Role assignment remains manual.

---

## rem-004 — Align Phase 2 configuration template with change-record contract

**Priority:** Medium

### Files

Review:

```text
INFRASTRUCTURE-CONTRACT.md
servers/_templates/configuration.md
```

### Problem

The infrastructure contract requires more change evidence than the Phase 2 template can currently record.

### Required change

Update the Phase 2 configuration template so material changes can record:

- target host/device;
- timestamp;
- previous state;
- changed state;
- configuration files touched;
- commands or automation used;
- validation result;
- rollback method;
- unresolved issues.

A single expanded table is preferred over creating additional documents.

Recommended structure:

```markdown
## Material Change Record

| Timestamp | Previous State | Change | Files / Commands | Validation | Rollback | Unresolved Issues |
|---|---|---|---|---|---|---|
```

The server identity already supplies the target host, so it does not need to be repeated in every row if the record clearly applies to one server.

---

## rem-005 — Strengthen discovery completeness validation and remove duplicate status

**Priority:** Medium

### Files

Review:

```text
servers/_templates/discovery.md
.claude/hooks/hx-common.ps1
.claude/hooks/hx-validate-discovery.ps1
.claude/hooks/hx-validate-subagent.ps1
.claude/skills/audit-discovery/SKILL.md
SERVER-REGISTRY.md
```

### Required change

Use one canonical discovery status field.

Remove the duplicate/conflicting status model.

Preferred field:

```markdown
**Discovery Status:** IN PROGRESS
```

Canonical values:

```text
IN PROGRESS
COMPLETE
BLOCKED
```

### Validation requirements

A record must not pass merely because headings exist.

For each required section, require either:

- substantive discovered data; or
- an explicit factual unavailable/not-detected statement.

Reject unchanged placeholders such as:

```text
<server-name>
```

Do not invent values to satisfy validation.

Examples of acceptable explicit absence:

```text
No discrete GPU detected
Not available from firmware
Not reported by current hardware/tooling
```

Ensure the audit skill and hook validators apply compatible completeness rules.

### Registry status

Define the registry's `Discovery` column values from the same canonical status model.

---

## rem-006 — Create initial tracked Git baseline

**Priority:** Medium  
**Sequence:** Perform only after rem-001 through rem-005 are corrected and reviewed.

### Required checks before commit

```text
[ ] git status reviewed
[ ] .env remains ignored
[ ] no password/token/private-key values are staged
[ ] hook tests pass
[ ] JSON files parse
[ ] PowerShell hooks parse
[ ] Bash fact collector syntax passes
[ ] active/distributable hooks are synchronized
```

Then create the first reviewed commit containing non-secret project artifacts.

Do not force-add `.env`.

---

# 3. Documentation Cleanup

These items are lower priority but should be resolved in the same remediation pass if they are straightforward.

## rem-007 — Correct router action ownership wording

**Priority:** Low

Update:

```text
governance/actions-and-issues.md
```

Reword the router action so it does not imply that the router owns server static-IP configuration.

Required model:

```text
- approved server IP assignment is recorded in SERVER-REGISTRY.md;
- static addressing is configured on the Ubuntu server;
- ASUSWRT provides persistent hx.local.arpa name resolution for those approved addresses;
- DHCP reservations remain out of scope for the primary LAN.
```

Suggested action wording:

> Establish persistent router-side `hx.local.arpa` DNS records for approved server-managed static IP addresses.

---

## rem-008 — Define role/workload/lifecycle authority

**Priority:** Low

### Required rules

`SERVER-REGISTRY.md` remains authoritative for:

- assigned role;
- approved workload/model;
- discovery lifecycle status;
- Phase 2 lifecycle status.

`configuration.md` copies approved role/workload values from the registry; it does not independently assign them.

Define the meaning of `Approved by`.

Recommended:

```text
Approved by = person who approved the Phase 2 configuration for the role already assigned in SERVER-REGISTRY.md.
```

It must not imply that the configuration template can approve or assign the role itself.

Define canonical lifecycle values.

Recommended:

### Discovery

```text
IN PROGRESS
COMPLETE
BLOCKED
```

### Phase 2

```text
BLOCKED
READY
IN PROGRESS
COMPLETE
```

Suggested transition:

```text
BLOCKED
  -> READY only after fleet-wide Phase 1 gate is complete
  -> IN PROGRESS when approved role configuration starts
  -> COMPLETE after configuration.md and role validation are complete
```

---

## rem-009 — Correct root installation guidance

**Priority:** Low

Update:

```text
INSTALL.md
```

The install instructions must explicitly include both:

1. skills/subagent installation;
2. hook installation.

Show the expected project assets:

```text
.claude/
├── settings.json
├── hooks/
├── skills/
└── agents/
```

Reference:

```text
claude-hooks/README.md
```

Include verification:

```text
/hooks
```

Do not duplicate the full hook installer instructions if linking to the existing hook README is sufficient.

---

## rem-010 — Repair malformed skill descriptions

**Priority:** Low

Correct duplicated/malformed prose in:

```text
.claude/skills/audit-discovery/SKILL.md
.claude/skills/sync-registry/SKILL.md
```

Replace malformed phrases with:

```text
a server discovery record
```

Review both YAML descriptions and workflow text after editing.

Do not alter the intended trigger or workflow semantics.

---

## rem-011 — Resolve undefined router DNS validation hostname

**Priority:** Low

The current contract uses:

```text
HX-Router.hx.local.arpa
```

without a project record establishing that name as canonical.

Choose one of two approaches:

### Option A — Preferred if approved

Explicitly define:

```text
HX-Router.hx.local.arpa -> 192.168.50.1
```

as the router's canonical local DNS record.

### Option B

Replace the validation command with:

```text
<known-host>.hx.local.arpa
```

until a canonical router record exists.

Do not pretend the DNS record is implemented if the persistent ASUSWRT DNS action remains open.

---

## rem-012 — Correct infrastructure contract heading hierarchy

**Priority:** Low

Update:

```text
INFRASTRUCTURE-CONTRACT.md
```

Keep only the document title as H1:

```markdown
# HX Local Infrastructure Automation Contract
```

Use H2 for numbered top-level sections:

```markdown
## 1. Purpose
## 2. Environment Boundaries
...
## 16. HX Infrastructure Standard Summary
```

Use H3 for subsections.

Do not change content merely to fix heading levels.

---

# 4. Items Requiring No Corrective Change

Do not modify the project merely because these items were reviewed.

The report confirmed the following areas are currently clean:

- Phase 2 remains blocked until fleet-wide discovery, manual review, and manual role assignment are complete.
- Agents/skills prohibit automatic role, workload, and model assignment.
- `discovery.md` and `configuration.md` are separate lifecycle artifacts.
- Active PowerShell hooks parse.
- The Bash discovery collector is syntactically valid and read-only by inspection.
- Active and distributable hook files are synchronized.
- JSON project configuration parses.
- Context7 is configured without an embedded credential.
- `.env` is ignored.
- routine action/issue tracking points to the governance log.

Do not refactor these areas without a specific reason.

---

# 5. Accepted Risks

Do not reopen accepted risks solely because this remediation is being performed.

Follow:

```text
governance/risk-acceptances.md
```

Only re-report an accepted risk if:

- its review/expiry trigger has been reached;
- actual conditions exceed its accepted scope; or
- new evidence materially changes likelihood or impact.

Never copy credential values into GitHub issues, remediation notes, commits, or governance documents.

---

# 6. Execution Order

Apply changes in this order:

```text
1. rem-001  validator fail-open
2. rem-002  Phase 1 guard relative paths
3. rem-003  canonical gate / expected fleet
4. rem-004  Phase 2 change record
5. rem-005  substantive discovery validation
6. rem-007 through rem-012 documentation cleanup
7. run project validation
8. rem-006 initial Git baseline
```

Do not create the Git baseline until the automation fixes have been tested.

---

# 7. Final Validation

Before declaring remediation complete, verify:

```text
[ ] zero/one/multiple-problem hook tests pass
[ ] Phase 1 guard blocks representative configuration.md path variants
[ ] discovery validator rejects empty/template-only records
[ ] only one discovery status exists
[ ] expected fleet baseline exists independently of registry rows
[ ] canonical Phase 1 gate is consistent across project references
[ ] Phase 2 template satisfies the infrastructure change-record requirement
[ ] router action clearly separates server static IP from router DNS
[ ] lifecycle values are defined
[ ] malformed skill prose is corrected
[ ] install guidance includes hooks
[ ] router DNS validation uses an approved record or placeholder
[ ] infrastructure contract heading hierarchy is corrected
[ ] active and packaged hooks remain synchronized
[ ] .env remains ignored and unstaged
[ ] initial non-secret Git baseline is committed
```

---

# 8. Completion Report

When finished, return a concise report containing:

```text
files changed
tests executed
test results
remaining open issues
Git commit hash
```

If any recommendation cannot be implemented safely or conflicts with another project rule, do not improvise. Record the conflict and explain it before changing the project.
