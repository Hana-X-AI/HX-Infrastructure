# Document Quality Checklist

**Document Type:** Standards - Quality Assurance
**Version:** 1.1
**Last Updated:** 2025-11-24
**Owner:** Agent Zero (CC)
**Status:** Active

---

## Purpose

This checklist MUST be followed for ALL document creation and modification in HX-Infrastructure. It prevents the defect patterns identified in CodeRabbit review (2025-11-23) where 22 process-critical defects occurred due to insufficient attention to detail.

**Core Principle:** Quality over speed. Documentation defects are as critical as code defects.

---

## Workflow Enforcement Checklist

**CRITICAL: Before starting ANY task, verify you are following the correct workflow phase.**

### □ 0. Mandatory Workflow Verification

**For Service/Node Deployment:**
- [ ] **STOP:** Have you received charter approval? If NO → You MUST execute Charter Workflow first
- [ ] Read `/home/agent0/HX-Infrastructure/procedures/charter-workflow.md` completely
- [ ] Verify current phase against workflow documentation
- [ ] **NEVER skip Phase 1 (Charter Creation)** - This is MANDATORY before specification
- [ ] Confirm all prior phase gates are completed before proceeding
- [ ] If user says "deploy service" → Charter MUST exist first

**Workflow Phase Order (5-Phase Canonical Lifecycle):**

Reference: `/home/agent0/HX-Infrastructure/README.md` and `procedures/core-project-team.md`

```
Phase 1: Charter Creation
  ↓ ✅ Charter Approved
Phase 2: Specification Development
  ↓ ✅ Spec Approved
Phase 3: Task Breakdown & Planning
  ↓ ✅ Plan Approved (includes test planning - 100% coverage required)
Phase 4: Deployment Execution
  ↓ ✅ Implementation Complete & All Tests Passing
Phase 5: Project Closeout
  ↓ ✅ Complete
```

**Note:** Some detailed workflows (like `CLAUDE.md` state tracker) expand these 5 phases into more granular sub-phases (e.g., Phase 3 includes both task breakdown and test planning; Phase 4 includes development, testing, deployment, and promotion). The above shows the canonical 5-phase model that all HX-Infrastructure projects follow.

**Failure Modes to Avoid:**
- ❌ User says "deploy service" → Agent skips directly to asking for service details
- ✅ User says "deploy service" → Agent confirms: "Charter workflow required first"
- ❌ Agent assumes charter exists without verification
- ✅ Agent checks for `/nodes/<node-name>/charter.md` existence and approval status
- ❌ Agent jumps from Phase 1 → Phase 4 (skipping planning and test planning)
- ✅ Agent validates all prior phases complete before starting new phase

**Enforcement Rules:**
1. **Charter First:** NO specification, planning, or development without approved charter
2. **Sequential Phases:** Complete Phase N before starting Phase N+1
3. **Quality Gates:** Cannot proceed past gate without explicit approval
4. **No Phase-Skipping:** Agent has ZERO authority to skip phases
5. **Workflow Documentation is Law:** Follow procedures EXACTLY as written

**When User Requests Task:**
```
User: "Deploy new service"
Agent Response:
1. Check: Does charter exist at /nodes/<service-name>/charter.md?
2. If NO: "This requires charter workflow first (Phase 0). Please provide service description for charter creation."
3. If YES: Read charter, verify Status: APPROVED, then proceed to specification phase

NOT THIS:
"What service would you like to deploy?" (skips charter entirely - WRONG)
```

---

## Pre-Creation Checklist

**Before creating or modifying ANY document:**

### □ 1. Understand Context
- [ ] Read ALL related documents completely (not just beginning/end)
- [ ] Identify authoritative sources for numerical values
- [ ] Understand deployment philosophy and infrastructure standards
- [ ] Review existing templates and patterns
- [ ] Check for related standards that apply

### □ 2. Verify Requirements
- [ ] **Confirm current workflow phase** (charter, spec, planning, testing, deployment, closeout)
- [ ] **Verify all prior phases complete** before starting new phase
- [ ] **Check for required phase gate approvals** (charter approved, spec approved, etc.)
- [ ] Confirm which template to use (if applicable)
- [ ] Identify all required sections
- [ ] Understand target audience and purpose
- [ ] Check governance phase and lifecycle position
- [ ] Verify approval/review requirements

### □ 3. Gather References
- [ ] **Read complete workflow procedure** for current phase (`procedures/<workflow-name>.md`)
- [ ] **Verify phase prerequisites met** (prior documents exist and approved)
- [ ] Locate authoritative inventory files (nodes.md, hx-agent-inventory.md)
- [ ] Identify canonical directory structures
- [ ] Find related procedures and workflows
- [ ] Check naming conventions standards
- [ ] Review infrastructure philosophy documents

---

## During Creation/Modification Checklist

### □ 4. Content Accuracy

**Numerical Values:**
- [ ] Cross-reference ALL counts against authoritative sources
  - Agent counts → `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md`
  - Node counts → `/home/agent0/HX-Infrastructure/inventory/nodes.md`
  - Phase counts → `/home/agent0/HX-Infrastructure/procedures/core-project-team.md`
- [ ] Never hardcode version numbers (reference inventory instead)
- [ ] Verify IP addresses against network documentation
- [ ] Confirm port numbers match service specifications

**File Paths:**
- [ ] Verify ALL paths actually exist using `ls` or `Read` tool
- [ ] Use current directory structure (`.claude/commands/`, not `x-claude`)
- [ ] Check template paths include subdirectories (`templates/testing/`, not `templates/`)
- [ ] Verify node-specific paths match canonical structure
  - Task results: `/nodes/[node-name]/task-results/`
  - Test executions: `/nodes/[node-name]/tests/test-executions/`

**References:**
- [ ] Verify all document references exist and are current
- [ ] Check section anchors are stable (use XML tags, not line numbers)
- [ ] Confirm workflow phase numbers are correct
- [ ] Validate agent names match inventory exactly

### □ 5. Infrastructure Philosophy Compliance

**Deployment Standards:**
- [ ] Bare-metal deployment for production/staging (hyphenated as compound adjective)
- [ ] Systemd service management (not Docker in production)
- [ ] Manual procedures (NO Ansible playbooks for deployment)
- [ ] Ansible Vault for credentials ONLY
- [ ] Docker allowed ONLY on dev server (`{DEV_SERVER_IP}`)

**Security Standards:**
- [ ] No hardcoded credentials
- [ ] No hardcoded IP addresses (use placeholders: `{PLACEHOLDER_NAME}`)
- [ ] Vault paths properly documented
- [ ] Samba AD authentication for humans (no local accounts)

### □ 6. Naming Conventions

**File/Directory Names:**
- [ ] All lowercase
- [ ] Hyphens only (NOT underscores) - Exception: vault passwords
- [ ] Proper prefixes (`tc-`, `defect-`, `poc-`, etc.)
- [ ] Sequential numbering is 3 digits (001, 002, 003)
- [ ] ISO date format (YYYY-MM-DD)

**Compound Adjectives:**
- [ ] Hyphenate when before noun: "bare-metal deployment", "test-driven development"
- [ ] No hyphen when after noun: "deployed on bare metal"

### □ 7. Markdown Quality

**Tables:**
- [ ] Leading and trailing pipes on ALL rows
- [ ] Column count matches header across ALL rows
- [ ] Separator row has correct number of columns
- [ ] No stray XML closing tags

**URLs:**
- [ ] Wrap bare URLs in angle brackets: `<https://example.com>`
- [ ] Or use explicit Markdown links: `[text](url)`

**Placeholders:**
- [ ] Use angle brackets for generic placeholders: `<service-name>`
- [ ] Use backticks to prevent link interpretation: `` `<placeholder>` ``
- [ ] Never use square brackets alone: `[placeholder]` (triggers link reference)

**Lists:**
- [ ] Parallel structure in bulleted lists
- [ ] Imperative voice for action items
- [ ] Consistent formatting across similar sections

### □ 8. Template Compliance

**If Using Template:**
- [ ] All required sections present
- [ ] Metadata complete and accurate
- [ ] Placeholders use correct syntax
- [ ] Examples are generic (no specific service names)
- [ ] Phase labels are correct

**Template Metadata:**
- [ ] Version number current
- [ ] Last updated date is today
- [ ] "Used In" phase is correct (Phase 1-5)
- [ ] Owner/maintainer identified

---

## Post-Creation Validation Checklist

### □ 9. Complete Document Review

**Read Entire Document:**
- [ ] Read EVERY line (not just beginning/end)
- [ ] Verify middle sections match patterns
- [ ] Check for consistency across sections
- [ ] Validate all cross-references work

**Cross-Document Consistency:**
- [ ] Compare with related documents for consistency
- [ ] Check standards are applied uniformly
- [ ] Verify terminology matches across documents
- [ ] Confirm workflow references are bidirectional

### □ 10. Technical Validation

**Path Verification:**
- [ ] Test all file paths using `Read` tool
- [ ] Verify directory paths using `ls` or `Glob`
- [ ] Check symbolic links resolve correctly
- [ ] Confirm template paths are accessible

**Reference Validation:**
- [ ] All agent names exist in hx-agent-inventory.md
- [ ] All node names exist in inventory/nodes.md
- [ ] All service names exist in services/ directory
- [ ] All procedure references are current

**Numerical Accuracy:**
- [ ] Counts match authoritative sources
- [ ] Version numbers are current
- [ ] Phase numbers align with lifecycle
- [ ] Sequence numbers are consecutive

### □ 11. Standards Compliance

**Documentation Requirements:**
- [ ] Follows `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md`
- [ ] Meets `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`
- [ ] Complies with `/home/agent0/HX-Infrastructure/constitution.md` principles

**Testing Requirements (if applicable):**
- [ ] 100% test coverage documented
- [ ] All test areas covered (deployment, functionality, integration, health-check)
- [ ] Test-driven deployment workflow followed

**Architecture Requirements (if applicable):**
- [ ] Security zone placement documented
- [ ] Network topology updates included
- [ ] Integration points identified
- [ ] ADR created for significant decisions

### □ 12. Security Review

**Sensitive Information:**
- [ ] No hardcoded passwords
- [ ] No hardcoded IP addresses (use placeholders)
- [ ] No API keys or tokens
- [ ] No certificate private keys
- [ ] Vault references use proper paths

**Configuration Management:**
- [ ] Placeholders documented in `/home/agent0/HX-Infrastructure/inventory/config-placeholders.md`
- [ ] Environment-specific values externalized
- [ ] Secrets management approach documented

---

## Pre-Commit Final Checks

### □ 13. Final Quality Gate

**Before Committing:**
- [ ] All checklist items above completed
- [ ] Document read completely one final time
- [ ] No "TODO" or placeholder text remains (unless intentional template markers)
- [ ] No typos or grammar errors
- [ ] Formatting is consistent and professional

**Peer Review Ready:**
- [ ] Document is self-documenting and clear
- [ ] Target audience can understand without context
- [ ] Examples are helpful and accurate
- [ ] Cross-references aid navigation

**Git Commit:**
- [ ] `.gitignore` excludes vault files
- [ ] No sensitive data in commit
- [ ] Commit message follows conventions
- [ ] Branch naming follows standards

---

## Defect Patterns to Avoid

**Based on CodeRabbit Review 2025-11-23:**

### ❌ Anti-Patterns (NEVER DO THIS)

1. **Workflow Phase Skipping (CRITICAL)**
   - ❌ User says "deploy service" → Agent asks "What service?" (skips charter)
   - ✅ User says "deploy service" → Agent responds "Charter workflow required first"
   - ❌ Agent jumps from charter to development (skips spec, planning, test planning)
   - ✅ Agent validates all phases complete sequentially with quality gates
   - ❌ Agent assumes "probably don't need charter for this"
   - ✅ Agent follows workflow documentation EXACTLY with zero exceptions

2. **Hardcoded Agent Counts**
   - ❌ Hardcoded agent counts → ✅ "See hx-agent-inventory.md for current agent list (32 agents: 5 Core Team SMEs + 27 Technology SMEs)"

3. **Hardcoded IP Addresses**
   - ❌ Hardcoded IPs → ✅ Use placeholders like `{DEV_SERVER_IP}` (actual: 192.168.10.222 for hx-dev-server)

4. **Deprecated Paths**
   - ❌ `/x-claude/claude-code-commands/` → ✅ `/.claude/commands/`

5. **Wrong Phase Numbers**
   - ❌ "Phase 5 of Charter Creation" → ✅ "Phase 1 of Project Lifecycle"

6. **Deployment Philosophy Violations**
   - ❌ "Request Ansible playbook" → ✅ "Execute manual deployment procedures"
   - ❌ "Docker deployment to production" → ✅ "Docker dev-only (not production/staging)"

7. **Brittle References**
   - ❌ "See lines 100-150" → ✅ "See `<section_name>` section"

8. **Inconsistent Hyphenation**
   - ❌ "bare metal deployment" (as adjective) → ✅ "bare-metal deployment"

9. **Malformed Tables**
   - ❌ Missing pipes, mismatched columns → ✅ Proper Markdown table syntax

10. **Placeholder Syntax Issues**
   - ❌ `[group-name]` (triggers link ref) → ✅ `` `<group-name>` ``

11. **Bare URLs**
    - ❌ `https://example.com` → ✅ `<https://example.com>`

---

## Quality Metrics

**Success Criteria for Document Quality:**

- ✅ **Zero workflow phase violations** (all phases executed sequentially)
- ✅ **Zero phase-skipping** (charter → spec → planning → testing → deployment → closeout)
- ✅ **All quality gates passed** (charter approved, spec approved, plan approved, tests passing)
- ✅ Zero hardcoded values that should reference authoritative sources
- ✅ Zero path references that don't exist
- ✅ Zero deployment philosophy violations
- ✅ Zero markdown linting errors
- ✅ Zero inconsistencies with related documents
- ✅ 100% checklist completion before commit

**If Any Checklist Item Fails:**
- STOP immediately
- Fix the issue
- Re-validate all related items
- Only proceed when ALL items pass

---

## Tool Usage for Quality Validation

### Verification Commands

**Path Validation:**
```bash
# Verify file exists
ls -la /path/to/file

# Verify directory exists and list contents
ls -la /path/to/directory/

# Use Read tool to verify file content
Read: /path/to/file
```

**Reference Validation:**
```bash
# Find all agent references
grep -r "agent-name" /home/agent0/HX-Infrastructure/

# Verify node exists
grep "node-name" /home/agent0/HX-Infrastructure/inventory/nodes.md

# Check service exists
ls /home/agent0/HX-Infrastructure/services/operational/ | grep service-name
```

**Count Validation:**
```bash
# Count agents in inventory
grep -c "^###" /home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md

# Count operational nodes
grep -A 1 "Operational" /home/agent0/HX-Infrastructure/inventory/nodes.md
```

**Markdown Validation:**
```bash
# Check for bare URLs (should be wrapped)
grep -E 'https?://[^ ]+[^>)]' file.md

# Check for malformed tables (manual review)
grep "|" file.md
```

---

## Authoritative Source Reference

**Always Consult These Files:**

| Category | Authoritative Source | What to Verify |
|----------|---------------------|----------------|
| **Workflow Phases** | `/home/agent0/HX-Infrastructure/procedures/charter-workflow.md` | **Charter creation mandatory first** |
| **Lifecycle Phases** | `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` | **Sequential phase execution** |
| **Spec Workflow** | `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` | **Phase 1 requirements** |
| **Task Workflow** | `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` | **Phase 2-3 requirements** |
| **Execution Workflow** | `/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md` | **Phase 4-5 requirements** |
| **Closeout Workflow** | `/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md` | **Phase 6 requirements** |
| Agent Count/Names | `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` | Agent names, counts, capabilities |
| Node Count/Names | `/home/agent0/HX-Infrastructure/inventory/nodes.md` | Node names, counts, status |
| Directory Structure | `.claude/commands/` | Command file paths |
| Template Paths | `/home/agent0/HX-Infrastructure/templates/` | Template file locations |
| Deployment Philosophy | `/home/agent0/HX-Infrastructure/constitution.md` | Infrastructure principles |
| Naming Conventions | `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` | File/directory naming rules |
| Network Config | `/home/agent0/HX-Infrastructure/network/README.md` | Network topology, IPs |
| Config Placeholders | `/home/agent0/HX-Infrastructure/inventory/config-placeholders.md` | Placeholder definitions |

---

## Accountability

**Document Creator Responsibilities:**
- **Verify correct workflow phase before starting ANY work**
- **Never skip mandatory phases** (charter, spec, planning, testing)
- **Validate all quality gates passed** before proceeding to next phase
- Complete 100% of checklist before marking document ready
- Verify every reference against authoritative sources
- Read entire document completely (not just beginning/end)
- Apply standards consistently throughout
- Treat documentation defects as critical (they ARE critical)
- **Treat workflow violations as CRITICAL FAILURES** (they block all downstream work)

**Reviewer Responsibilities:**
- **Verify workflow phase is correct** (charter before spec, spec before planning, etc.)
- **Confirm all prior quality gates passed** (charter approved, spec approved, etc.)
- **Reject any work that skipped mandatory phases** (immediate STOP and correction)
- Verify checklist was completed
- Spot-check references against authoritative sources
- Validate standards compliance
- Check for defect patterns from historical issues
- Reject non-compliant documents

---

## Continuous Improvement

**After Each CodeRabbit Review:**
- Analyze new defect patterns
- Add to anti-patterns section
- Update checklist if gaps identified
- Share lessons learned with team

**Monthly Review:**
- Analyze defect trends
- Update authoritative source references
- Refresh examples with current data
- Verify tool commands still work

---

## Version History

- **v1.0** (2025-11-23): Initial creation based on CodeRabbit defect analysis (22 issues)
- **v1.1** (2025-11-24): Added Workflow Enforcement Checklist (Section 0) to prevent phase-skipping failures. Added workflow phase validation to all checklists. Elevated workflow violations to CRITICAL status.

---

**Remember:** Speed without accuracy is waste. Quality first, always.

**Principle:** Assume nothing, verify everything. Read completely, not partially.

**Standard:** Zero defects is the only acceptable target for process-critical documentation.

**CRITICAL:** Workflows exist for a reason. Phase-skipping is a CRITICAL FAILURE that invalidates all downstream work. When user says "deploy service", your FIRST action is verify charter exists and is approved. No exceptions.
