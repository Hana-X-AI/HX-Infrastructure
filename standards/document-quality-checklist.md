# Document Quality Checklist

**Document Type:** Standards - Quality Assurance
**Version:** 1.0
**Last Updated:** 2025-11-23
**Owner:** Agent Zero (CC)
**Status:** Active

---

## Purpose

This checklist MUST be followed for ALL document creation and modification in HX-Infrastructure. It prevents the defect patterns identified in CodeRabbit review (2025-11-23) where 22 process-critical defects occurred due to insufficient attention to detail.

**Core Principle:** Quality over speed. Documentation defects are as critical as code defects.

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
- [ ] Confirm which template to use (if applicable)
- [ ] Identify all required sections
- [ ] Understand target audience and purpose
- [ ] Check governance phase and lifecycle position
- [ ] Verify approval/review requirements

### □ 3. Gather References
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

1. **Hardcoded Agent Counts**
   - ❌ "All 45 agents" → ✅ "See hx-agent-inventory.md for current agent list"

2. **Hardcoded IP Addresses**
   - ❌ Hardcoded IPs → ✅ Use placeholders like `{DEV_SERVER_IP}` (actual: 192.168.10.222 for hx-dev-server)

3. **Deprecated Paths**
   - ❌ `/x-claude/claude-code-commands/` → ✅ `/.claude/commands/`

4. **Wrong Phase Numbers**
   - ❌ "Phase 5 of Charter Creation" → ✅ "Phase 1 of Project Lifecycle"

5. **Deployment Philosophy Violations**
   - ❌ "Request Ansible playbook" → ✅ "Execute manual deployment procedures"
   - ❌ "Docker deployment to production" → ✅ "Docker dev-only (not production/staging)"

6. **Brittle References**
   - ❌ "See lines 100-150" → ✅ "See `<section_name>` section"

7. **Inconsistent Hyphenation**
   - ❌ "bare metal deployment" (as adjective) → ✅ "bare-metal deployment"

8. **Malformed Tables**
   - ❌ Missing pipes, mismatched columns → ✅ Proper Markdown table syntax

9. **Placeholder Syntax Issues**
   - ❌ `[group-name]` (triggers link ref) → ✅ `` `<group-name>` ``

10. **Bare URLs**
    - ❌ `https://example.com` → ✅ `<https://example.com>`

---

## Quality Metrics

**Success Criteria for Document Quality:**

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
| Agent Count/Names | `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` | Agent names, counts, capabilities |
| Node Count/Names | `/home/agent0/HX-Infrastructure/inventory/nodes.md` | Node names, counts, status |
| Lifecycle Phases | `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` | Phase numbers, names |
| Directory Structure | `.claude/commands/` | Command file paths |
| Template Paths | `/home/agent0/HX-Infrastructure/templates/` | Template file locations |
| Deployment Philosophy | `/home/agent0/HX-Infrastructure/constitution.md` | Infrastructure principles |
| Naming Conventions | `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` | File/directory naming rules |
| Network Config | `/home/agent0/HX-Infrastructure/network/README.md` | Network topology, IPs |
| Config Placeholders | `/home/agent0/HX-Infrastructure/inventory/config-placeholders.md` | Placeholder definitions |

---

## Accountability

**Document Creator Responsibilities:**
- Complete 100% of checklist before marking document ready
- Verify every reference against authoritative sources
- Read entire document completely (not just beginning/end)
- Apply standards consistently throughout
- Treat documentation defects as critical (they ARE critical)

**Reviewer Responsibilities:**
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

---

**Remember:** Speed without accuracy is waste. Quality first, always.

**Principle:** Assume nothing, verify everything. Read completely, not partially.

**Standard:** Zero defects is the only acceptable target for process-critical documentation.
