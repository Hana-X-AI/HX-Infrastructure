# Test Case: Manual Deployment Procedure Verification

**Test ID**: tc-docling-mcp-deployment-012
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify deployment was executed manually (no automation artifacts like Ansible playbooks, deployment scripts) per HX-Infrastructure philosophy.

---

## Test Coverage

**Requirements Covered**:
- DR-007: Manual deployment verified
- HX-Infrastructure Constitution: Manual procedures only, no automation scripts

---

## Test Steps

### Step 1: Verify No Ansible Playbook Artifacts

**Action**:
```bash
# Check for Ansible playbooks (should NOT exist for deployment)
! test -f /opt/docling-mcp/deploy.yml && echo "PASS: No Ansible playbook for deployment"
! test -d /opt/docling-mcp/ansible && echo "PASS: No Ansible directory"
```

**Expected**: NO Ansible playbooks for deployment found

**IMPORTANT**: Ansible Vault for credentials is ALLOWED (security), but NOT deployment playbooks

---

### Step 2: Verify No Deployment Automation Scripts

**Action**:
```bash
# Check for deployment scripts (should NOT exist)
! test -f /opt/docling-mcp/deploy.sh && echo "PASS: No deploy.sh script"
! test -f /opt/docling-mcp/install.sh && echo "PASS: No install.sh script"
! test -d /opt/docling-mcp/scripts/deployment && echo "PASS: No deployment scripts directory"
```

**Expected**: NO deployment automation scripts found

---

### Step 3: Verify Manual Deployment Documentation Exists

**Action**:
```bash
test -f /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/deployment/DEPLOYMENT-PLAN.md && echo "PASS: Manual deployment plan exists"
test -f /home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/deployment/RUNBOOK.md && echo "PASS: Manual runbook exists"
```

**Expected**: Manual deployment documentation exists

---

### Step 4: Verify Configuration Files Created from Templates (Not Generated)

**Action**:
```bash
# Check .env file is NOT identical to template (should be customized)
! diff /etc/docling-mcp/.env /home/agent0/HX-Infrastructure/templates/.env.template > /dev/null && echo "PASS: .env customized from template"
```

**Expected**: Configuration files manually created/customized, not auto-generated

---

## Pass/Fail Criteria

**PASS**: No automation artifacts, manual documentation exists, configs customized

**FAIL**: Automation scripts found (violates HX-Infrastructure philosophy)

**CRITICAL FAIL**: Ansible playbook used for deployment (constitution violation)

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-012-automation-detected.md`

---

**Test Case Version**: 1.0
