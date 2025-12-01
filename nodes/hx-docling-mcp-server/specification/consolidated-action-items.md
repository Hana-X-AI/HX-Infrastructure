# Consolidated Action Items - hx-docling-mcp-server Specification Fixes

**Created**: 2025-11-30
**Source Audits**:
1. `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/spec-gap-analysis.md` (11 gaps)
2. `/home/agent0/HX-Infrastructure/x-claude/hx-docling-mcp-server-spec-audit.md` (12 gaps + security + propagation)
3. `/home/agent0/HX-Infrastructure/x-claude/node-spec-audit-2025-11-30.md` (design-implementation alignment)

**Total Issues**: 19 actionable tasks across 4 priority levels

---

## CRITICAL (IMMEDIATE - Service Would Fail)

### TASK-C1: Fix ALL Wrong IP Addresses Across 38 Files (245 Occurrences)

**Priority**: CRITICAL - Service will not start with wrong IPs

**Wrong → Correct**:
- `192.168.10.212` → `192.168.10.212` (hx-litellm-server) - 109 occurrences
- `192.168.10.207` → `192.168.10.207` (hx-qdrant-server) - 59 occurrences
- `192.168.10.210` → `192.168.10.210` (hx-redis-server) - 77 occurrences

**Affected File Categories**:
1. Specification files (`specification/node-spec.md`, `specification/reviews/*`)
2. Planning files (`planning/plan.md`, `planning/*.md`, `planning/reviews/*`)
3. Task files (`tasks/hx-docling-mcp-task-*.md`, `tasks/reviews/*`)
4. Test files (`tests/test-plan.md`, `tests/test-suite/**/*.md`)
5. Other files (`charter/charter.md`, `backlog.md`, `raidd-log.md`, `defect-log.md`, `lessons-learned.md`)

**How to Fix**:
```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Fix LiteLLM IP (109 occurrences)
find . -type f -name "*.md" -exec sed -i 's/192\.168\.10\.213/192.168.10.212/g' {} \;

# Fix Qdrant IP (59 occurrences)
find . -type f -name "*.md" -exec sed -i 's/192\.168\.10\.223/192.168.10.207/g' {} \;

# Fix Redis IP (77 occurrences)
find . -type f -name "*.md" -exec sed -i 's/192\.168\.10\.221/192.168.10.210/g' {} \;

# Verify all occurrences fixed
grep -r "192\.168\.10\.213\|192\.168\.10\.223\|192\.168\.10\.221" . --include="*.md"
# Should return no results
```

**Verification**:
- [ ] All 245 occurrences replaced
- [ ] No wrong IPs remain in any .md files
- [ ] Correct IPs verified against `/home/agent0/HX-Infrastructure/inventory/nodes.md`

**Source**: Gap #3, Audit Appendix B

---

### TASK-C2: Remove LightRAG Local Installation, Add hx-literag-server Integration

**Priority**: CRITICAL - Architectural violation, duplicate deployment

**Issue**: Spec plans to install LightRAG as local Python package (`lightrag==0.2.0`) when hx-literag-server (192.168.10.220) is already ✅ OPERATIONAL.

**Files to Update**:

1. **`specification/node-spec.md`**:
   - Line 664: Remove `lightrag==0.2.0` from Python packages
   - Line 771: Remove `lightrag` from import validation
   - Lines 365-402 (FR-011 through FR-017): Rewrite to describe HTTP API integration with hx-literag-server instead of local deployment
   - Lines 780-822: Add hx-literag-server to internal service dependencies
   - Lines 862-887: Add hx-literag-server to downstream services
   - Lines 894-897: Add `LIGHTRAG_API_URL` environment variable

2. **`planning/plan.md`**:
   - Remove LightRAG installation tasks
   - Add hx-literag-server HTTP API integration tasks

3. **`tasks/hx-docling-mcp-task-021-install-lightrag-framework.md`**:
   - Rename to `hx-docling-mcp-task-021-integrate-lightrag-api.md`
   - Rewrite to use HTTP client for hx-literag-server

4. **All review files** mentioning LightRAG local deployment

**Correct Architecture**:
```
Docling MCP Server → HTTP API → hx-literag-server (192.168.10.220)
  (document processing)            (knowledge graph generation)
```

**NOT**:
```
Docling MCP Server (with embedded LightRAG library)
```

**Environment Variable to Add**:
```bash
LIGHTRAG_API_URL=http://192.168.10.220:8000
```

**Verification**:
- [ ] No `lightrag` package in requirements.txt or dependencies
- [ ] hx-literag-server added to internal dependencies section
- [ ] HTTP API integration documented in functional requirements
- [ ] Environment variable added for LightRAG API URL
- [ ] All references to local LightRAG installation removed

**Source**: Gap #1, Gap #2, GAP-C2, GAP-H1

---

### TASK-C3: Fix Charter Path Reference

**Priority**: CRITICAL - Broken reference

**Issue**: Spec references charter at root level, but actual file is in `charter/` subdirectory.

**Wrong Path**:
```
/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md
```

**Correct Path**:
```
/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md
```

**Files to Update**:
1. `specification/node-spec.md` (Line 12)
2. Any other files referencing charter path

**How to Fix**:
```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Find all charter path references
grep -r "charter\.md" . --include="*.md"

# Fix in specification
sed -i 's|nodes/hx-docling-mcp-server/charter\.md|nodes/hx-docling-mcp-server/charter/charter.md|g' specification/node-spec.md

# Fix in any other files
find . -type f -name "*.md" -exec sed -i 's|nodes/hx-docling-mcp-server/charter\.md|nodes/hx-docling-mcp-server/charter/charter.md|g' {} \;
```

**Verification**:
- [ ] Charter path includes `/charter/` subdirectory
- [ ] Path points to actual file location
- [ ] File exists at specified path

**Source**: GAP-C3

---

## HIGH PRIORITY (Architectural Corrections)

### TASK-H1: Document Relationship with Existing hx-docling-server (192.168.10.216)

**Priority**: HIGH - Architectural clarity needed

**Issue**: Two Docling-related nodes exist but relationship is undocumented:
- `hx-docling-server` (192.168.10.216) - ✅ Operational
- `hx-docling-mcp-server` (192.168.10.217) - ⬜ Planned

**Questions to Answer in Spec**:
1. What is the relationship between the two servers?
2. Does hx-docling-server provide document processing that hx-docling-mcp-server should integrate with?
3. Or is hx-docling-mcp-server meant to REPLACE hx-docling-server?
4. Should there be integration/coordination between the two?
5. Why are TWO Docling servers needed?

**Where to Document**:
- `specification/node-spec.md` - Add new section: "Relationship with hx-docling-server"
- Place after "Charter Reference" section

**Content to Add**:
```markdown
## Relationship with hx-docling-server

**Existing Service**: hx-docling-server (192.168.10.216) - ✅ Operational

**Relationship**: [TO BE CLARIFIED - Need to investigate actual hx-docling-server functionality]

**Integration Strategy**: [TO BE SPECIFIED after hx-docling-server review]

**Rationale for Separate MCP Server**: [TO BE DOCUMENTED]
```

**Action Required**:
1. Investigate what hx-docling-server currently does
2. Document integration or replacement strategy
3. Update specification with clear relationship definition

**Verification**:
- [ ] Relationship section added to spec
- [ ] Integration strategy documented
- [ ] Rationale for separate server explained

**Source**: Gap #6, GAP-H3

---

### TASK-H2: Fix Qdrant Collection Naming to Avoid Conflicts

**Priority**: HIGH - Prevents data corruption

**Issue**: Spec plans generic collection names that may collide with hx-literag-server's collections:
- `hx_docling_mcp_entities`
- `hx_docling_mcp_relationships`

**Recommended Naming** (service-specific prefixes):
- `hx_docling_mcp_entities`
- `hx_docling_mcp_relationships`

**Files to Update**:
1. `specification/node-spec.md` (Lines 387-390, FR-015)
2. All task files mentioning Qdrant collection creation
3. Test files validating collection structure

**How to Fix**:
```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Replace collection names
find . -type f -name "*.md" -exec sed -i 's/`hx_docling_mcp_entities`/`hx_docling_mcp_entities`/g' {} \;
find . -type f -name "*.md" -exec sed -i 's/`hx_docling_mcp_relationships`/`hx_docling_mcp_relationships`/g' {} \;
find . -type f -name "*.md" -exec sed -i 's/hx_docling_mcp_entities/hx_docling_mcp_entities/g' {} \;
find . -type f -name "*.md" -exec sed -i 's/hx_docling_mcp_relationships/hx_docling_mcp_relationships/g' {} \;
```

**Rationale**: Service-specific prefixes prevent collection name collisions between services sharing the same Qdrant instance.

**Verification**:
- [ ] All collection references use `hx_docling_mcp_` prefix
- [ ] No generic `docling_*` collection names remain
- [ ] Naming documented in Qdrant integration sections

**Source**: Gap #5, GAP-H2

---

### TASK-H3: Create or Link to Agent Definition Files

**Priority**: HIGH - Documentation integrity

**Issue**: Spec references 6 agents that don't exist in `hx-agents/` directory:
- `alex-rivera` (Architect)
- `albert-singh` (Contributor - Docling)
- `andy-taylor` (Contributor - LightRAG)
- `marcus-johnson` (Contributor - LightRAG)
- `shane-black` (Contributor - LiteLLM)
- `james-rodriguez` (Contributor - MCP)

**Current hx-agents/ Contents**:
- `hx-agent-inventory.md`
- `hx-knowledge-vault-catalog.md`
- `hx-orchestration-guide.md`
- `hx-orchestration-quick-ref.md`
- `README.md`

**Options**:
1. **Check if agents exist under different names** in hx-agent-inventory.md
2. **Create agent definition files** if they should exist
3. **Use generic role references** instead of specific agent names
4. **Update to reference actual agents** from hx-agent-inventory.md

**Recommended Action**:
1. Review `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` for actual agent names
2. Map spec references to actual agents OR
3. Replace with generic role references ("Platform Architect", "LightRAG Specialist", etc.)

**Files to Update**:
- `specification/node-spec.md` (Line 9 - Architect & Contributors)
- All review files referencing agent names

**Verification**:
- [ ] All agent references valid (exist in hx-agent-inventory.md OR generic roles used)
- [ ] No references to non-existent agents
- [ ] Contributor assignments match actual agent capabilities

**Source**: Gap #8, GAP-M1

---

### TASK-H4: Remove Firewall Configuration Section Entirely

**Priority**: HIGH - Philosophy violation

**Issue**: Firewall Configuration section exists (Lines 1281-1286) despite HX-Infrastructure policy that **ALL FIREWALLS ARE DISABLED**.

**From lessons-learned.md**:
> ALL HX-Infrastructure servers have firewalls DISABLED per charter

**Files to Update**:
1. `specification/node-spec.md` (Lines 1281-1286)

**Content to Remove**:
```markdown
**Firewall Configuration**:

**HX-Infrastructure Development Environment Policy**: Firewalls are DISABLED on all development infrastructure nodes.
```

**Replacement** (if any reference needed):
```markdown
**Network Security**:

Network security provided by physical isolation. Per HX-Infrastructure policy, firewalls are disabled on all nodes.
```

**How to Fix**:
```bash
# Manual edit required - remove entire Firewall Configuration subsection
# Replace with brief note about physical isolation if needed
```

**Verification**:
- [ ] No "Firewall Configuration" section in spec
- [ ] No firewall-related content in any planning/task files
- [ ] Physical isolation noted if security section exists

**Source**: Gap #4, Gap #7, GAP-M2

---

## MEDIUM PRIORITY (Standards & Cleanup)

### TASK-M1: Remove 38 Plaintext Password References from 8 Files

**Priority**: MEDIUM - Security hygiene

**Issue**: Standard password `Major8859!` appears in plaintext 38 times across 8 files.

**Affected Files**:
1. `defect-log.md` (documents the issue - meta, can keep)
2. `tasks/hx-docling-mcp-task-008-configure-environment-files.md` (commented example)
3. `tasks/hx-docling-mcp-task-001-create-samba-ad-service-account.md` (kinit command)
4. `planning/deployment-architecture.md` (samba_password field)
5. `planning/plan.md` (samba_password field)
6. `planning/reviews/alex-rivera-architecture-review.md` (documentation reference)
7. `planning/reviews/frank-lucas-re-review.md` (multiple references)
8. `planning/reviews/frank-lucas-security-review.md` (multiple references)

**Replacement Patterns**:
- `Major8859!` → `[SEE VAULT: vault/credentials.yml]`
- `samba_password: Major8859!` → `samba_password: ${SAMBA_PASSWORD}`
- kinit commands → `kinit <username>@HX.DEV.LOCAL` (prompt for password)

**How to Fix**:
```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Replace plaintext passwords (exclude defect-log.md)
find . -type f -name "*.md" ! -name "defect-log.md" -exec sed -i 's/Major8859!/[SEE VAULT: vault\/credentials.yml]/g' {} \;

# Verify remaining occurrences only in defect-log.md (meta documentation)
grep -r "Major8859!" . --include="*.md"
```

**Verification**:
- [ ] No plaintext passwords in task files
- [ ] No plaintext passwords in planning files
- [ ] No plaintext passwords in review files
- [ ] Only defect-log.md contains password (documenting the issue itself)
- [ ] All password references use vault placeholders

**Source**: Audit Appendix A

---

### TASK-M2: Update Specification Status from "Integration Complete" to "Specification Phase Complete"

**Priority**: MEDIUM - Status accuracy

**Issue**: Spec claims "Status: Draft - Integration Complete" but:
- No Python code exists in `/opt/docling-mcp/application/`
- No pytest code exists
- Only infrastructure directories created

**Current Status** (Line 7):
```
**Status**: Draft - Integration Complete
```

**Correct Status**:
```
**Status**: Draft - Specification Phase Complete, Implementation Pending
```

**Files to Update**:
1. `specification/node-spec.md` (Line 7)

**Rationale**: Infrastructure is ready, but Python implementation hasn't started. Status should reflect specification work is complete, not implementation.

**Verification**:
- [ ] Status updated to reflect actual implementation state
- [ ] Status matches reality (no Python code yet)

**Source**: Audit #2 (node-spec-audit-2025-11-30.md)

---

### TASK-M3: Fix Template Version Mismatch

**Priority**: MEDIUM - Documentation consistency

**Issue**: Spec claims Template Version 1.1, but actual template shows 1.0.

**Spec Claims** (if present):
```
**Template Version**: 1.1
```

**Actual Template** (`templates/node-template.md`):
```
**Template Version**: 1.0
```

**Action Required**:
1. Verify actual template version
2. Update spec to match, OR
3. Update template if spec is correct

**How to Fix**:
```bash
# Check template version
grep "Template Version" /home/agent0/HX-Infrastructure/templates/node-template.md

# Update spec to match template version
sed -i 's/Template Version: 1\.1/Template Version: 1.0/g' specification/node-spec.md
```

**Verification**:
- [ ] Template version in spec matches actual template
- [ ] No version mismatches

**Source**: GAP-M3

---

### TASK-M4: Fix Service Account Password Documentation Reference

**Priority**: MEDIUM - Documentation accuracy

**Issue**: References `lessons-learned.md` line 710 for password standard, but should reference Ansible Vault procedure.

**Current Reference** (Line 1535):
```
Standard password: See /home/agent0/HX-Infrastructure/lessons-learned.md line 710
```

**Correct Reference**:
```
Standard password: See vault/credentials.yml (Ansible Vault encrypted)
Vault management: /home/agent0/HX-Infrastructure/standards/credentials-vault-management.md
```

**Files to Update**:
1. `specification/node-spec.md` (Line 1535, Ansible Vault README section)

**Rationale**: Operational procedures shouldn't reference lessons-learned.md. Use proper credentials vault documentation.

**Verification**:
- [ ] Password reference points to vault, not lessons-learned
- [ ] Vault management documentation referenced
- [ ] No line number references (unstable)

**Source**: Gap #10

---

### TASK-M5: Add Missing hx-literag-server to Environment Variables

**Priority**: MEDIUM - Configuration completeness

**Issue**: hx-literag-server (192.168.10.220) missing from environment variables section.

**Where to Add** (`specification/node-spec.md`, Lines 894-897):
```bash
# LightRAG Knowledge Graph Service
LIGHTRAG_API_URL=http://192.168.10.220:8000
```

**Context**: After removing local LightRAG installation (TASK-C2), need HTTP API endpoint configuration.

**Verification**:
- [ ] LIGHTRAG_API_URL environment variable documented
- [ ] URL points to hx-literag-server at correct IP and port
- [ ] Variable included in all environment configuration sections

**Source**: Gap #2 follow-up

---

### TASK-M6: Verify Charter Status is Actually APPROVED

**Priority**: MEDIUM - Verification needed

**Issue**: Spec claims "Status: APPROVED" but not verified.

**Spec Claims** (Line 12):
```
**Charter Reference**: .../charter/charter.md (Status: APPROVED)
```

**Action Required**:
```bash
# Read charter and verify approval status
grep -i "status.*approved" /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md
```

**If charter shows APPROVED**: Gap resolved, no action needed
**If charter NOT approved**: Update spec to reflect actual status

**Verification**:
- [ ] Charter actually contains "Status: APPROVED"
- [ ] Spec status matches charter status

**Source**: Gap #8, GAP-L1

---

### TASK-M7: Fill Configuration Template Placeholders

**Priority**: MEDIUM - Configuration readiness

**Issue**: Configuration files have unfilled placeholders.

**Affected Files**:
1. `configuration/env-vars.md` - Status: TEMPLATE - "[TO BE SPECIFIED]"
2. `configuration/network-config.md` - Status: TEMPLATE - "[TO BE SPECIFIED]"

**Action Required**:
1. Review configuration requirements from spec
2. Fill in actual environment variables
3. Fill in actual network configuration
4. Remove "[TO BE SPECIFIED]" placeholders

**Verification**:
- [ ] env-vars.md has actual variables, no placeholders
- [ ] network-config.md has actual configuration, no placeholders
- [ ] All "[TO BE SPECIFIED]" removed

**Source**: Audit Appendix C

---

## LOW PRIORITY (Documentation Hygiene)

### TASK-L1: Add vault/README.md Documentation

**Priority**: LOW - Documentation completeness

**Issue**: `vault/` directory has no README.md documenting structure.

**Current vault/ Contents**:
- `credentials.yml` (✅ ENCRYPTED)
- `.vault_password` (⚠️ EXISTS - should be git-ignored)

**README.md Content to Create**:
```markdown
# Ansible Vault - hx-docling-mcp-server Credentials

**Encryption**: AES256 (Ansible Vault 1.1)
**Vault Password File**: `.vault_password` (git-ignored)

## Credentials Structure

See `credentials.yml` for:
- Samba AD service account credentials
- Domain authentication details

## Vault Management

See: /home/agent0/HX-Infrastructure/standards/credentials-vault-management.md

## Decrypting Vault

```bash
ansible-vault view credentials.yml --vault-password-file .vault_password
```

## Security Notes

- `.vault_password` must be in .gitignore
- Never commit decrypted credentials
- Rotate credentials per security policy
```

**Verification**:
- [ ] vault/README.md created
- [ ] Documentation describes vault structure
- [ ] References credentials-vault-management.md
- [ ] Includes usage examples

**Source**: Audit Appendix C

---

### TASK-L2: Verify .vault_password is Git-Ignored

**Priority**: LOW - Security verification

**Issue**: `.vault_password` exists but may not be git-ignored.

**Action Required**:
```bash
cd /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server

# Check if .vault_password is git-ignored
git check-ignore vault/.vault_password

# If not ignored, add to .gitignore
echo "vault/.vault_password" >> .gitignore
```

**Verification**:
- [ ] .vault_password in .gitignore
- [ ] Verified with `git check-ignore`
- [ ] File not tracked by git

**Source**: Audit Appendix C

---

### TASK-L3: Verify Resource Requirements Against Actual Node

**Priority**: LOW - Accuracy validation

**Issue**: Resource specs provided without verifying actual hx-docling-mcp-server (192.168.10.217) resources.

**Spec Claims** (Lines 630-652):
- CPU: 2 cores minimum, 4 cores recommended
- Memory: 4GB minimum, 8GB recommended
- Storage: 10GB minimum, 50GB recommended

**Action Required**:
```bash
# SSH to hx-docling-mcp-server and check actual resources
ssh agent0@192.168.10.217

# Check CPU
lscpu | grep "^CPU(s):"

# Check Memory
free -h

# Check Storage
df -h /opt/docling-mcp
```

**Documentation Update**:
Add section to spec comparing required vs actual resources.

**Verification**:
- [ ] Actual node resources verified
- [ ] Spec updated with actual vs required comparison
- [ ] Any resource upgrades needed documented

**Source**: Gap #9, GAP-L2

---

### TASK-L4: Verify Test Cases Exist or Mark as "TO BE CREATED"

**Priority**: LOW - Documentation accuracy

**Issue**: Spec references test cases (TC-INT-001, TC-MM-001, etc.) without verifying they exist.

**Test Case References** (Lines 1727-1843):
- TC-INT-005 (LiteLLM connectivity)
- TC-MM-001 through TC-MM-014
- TC-INT-002 (knowledge graph E2E)
- Many others

**Action Required**:
```bash
# Check if test case files exist
ls -la /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/

# List all test case files
find /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests -name "tc-*.md"
```

**If test cases DON'T exist**:
- Update spec to mark as "TO BE CREATED"
- OR create placeholder test case files

**Verification**:
- [ ] All referenced test cases verified (exist or marked "TO BE CREATED")
- [ ] No references to non-existent test cases
- [ ] Test directory structure documented

**Source**: Gap #11, GAP-L3

---

### TASK-L5: Review and Update "Directory Structure Exists But Empty" Status

**Priority**: LOW - Status accuracy

**Issue**: Spec should document which directories exist but are empty vs populated.

**From Audit #2**:
```
Directory Structure:
✅ EXISTS: charter/, specification/, planning/, inventory/, deployment/,
           configuration/, tests/, vault/
⚠️ EMPTY: Most subdirectories (tests/test-suite/, configuration/ansible-vault/)
```

**Action Required**:
1. Document current directory population status in spec
2. Note which directories are placeholders vs populated
3. Update as implementation progresses

**Documentation Location**:
Add section after "Directory Structure Validation" noting:
- Which directories have content
- Which are placeholders for future implementation
- Expected population during implementation phase

**Verification**:
- [ ] Directory status documented
- [ ] Empty vs populated directories noted
- [ ] Status reflects actual file system state

**Source**: Audit #2 (node-spec-audit-2025-11-30.md)

---

## SUMMARY

**Total Tasks**: 19
- **Critical**: 3 (service-breaking issues)
- **High**: 4 (architectural corrections)
- **Medium**: 7 (standards & cleanup)
- **Low**: 5 (documentation hygiene)

**Recommended Execution Order**:
1. TASK-C1 (fix IPs) - Most pervasive issue
2. TASK-C2 (LightRAG architecture) - Fundamental design change
3. TASK-C3 (charter path) - Quick fix
4. TASK-H1 through TASK-H4 (architectural clarity)
5. TASK-M1 through TASK-M7 (cleanup & standards)
6. TASK-L1 through TASK-L5 (documentation polish)

**After Completion**:
- All service-breaking issues resolved
- Architecture aligns with HX-Infrastructure standards
- Documentation accurate and complete
- Ready for implementation phase

---

**All tasks documented. No changes made to any files per user directive.**
