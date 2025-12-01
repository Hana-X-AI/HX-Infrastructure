# Test Case: Rollback Procedure Validation (MANDATORY)

**Test ID**: tc-docling-mcp-deployment-014
**Test Area**: Deployment Validation
**Priority**: CRITICAL
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

**CRITICAL**: Validate rollback procedure works correctly before operational promotion. This test is MANDATORY per test plan lines 2299-2305.

---

## Test Coverage

**Requirements Covered**:
- DR-008: Rollback capability validated
- Plan Section: Rollback Strategy (lines 847-957)

---

## Test Execution Strategy

This test MUST be executed during non-operational phase and MUST PASS before operational promotion.

**Workflow**:
1. Service deployed to non-operational
2. Execute this rollback test
3. Rollback validates successfully
4. Re-deploy to non-operational
5. Validate identical results
6. ONLY THEN promote to operational

---

## Test Steps

### Step 1: Capture Pre-Rollback State

**Action**:
```bash
# Capture current service state
systemctl status docling-mcp.service > /tmp/pre-rollback-status.txt
sudo netstat -tulpn | grep :8000 > /tmp/pre-rollback-ports.txt
curl -s http://192.168.10.217:8000/health > /tmp/pre-rollback-health.json
ls -la /opt/docling-mcp/venv > /tmp/pre-rollback-venv.txt
```

**Expected**: All state captured to /tmp/ files

---

### Step 2: Execute Rollback Procedure

**Action**:
```bash
# Follow manual rollback procedure from plan.md lines 861-943
sudo systemctl stop docling-mcp.service
sudo systemctl disable docling-mcp.service

# Backup current state
sudo mkdir -p /opt/docling-mcp/backups/rollback-test-$(date +%Y%m%d-%H%M%S)
sudo cp -r /etc/docling-mcp /opt/docling-mcp/backups/rollback-test-$(date +%Y%m%d-%H%M%S)/etc
sudo cp /etc/systemd/system/docling-mcp.service /opt/docling-mcp/backups/rollback-test-$(date +%Y%m%d-%H%M%S)/

# Remove service configuration
sudo rm /etc/systemd/system/docling-mcp.service
sudo systemctl daemon-reload

# Remove application
sudo rm -rf /opt/docling-mcp/venv
sudo rm -rf /opt/docling-mcp/application

# Clean working directories
sudo rm -rf /var/lib/docling-mcp/cache/*
sudo rm -rf /var/lib/docling-mcp/workspace/*
```

**Expected**: Rollback executes without errors

---

### Step 3: Verify Clean State After Rollback

**Action**:
```bash
# Verify service stopped
systemctl status docling-mcp.service 2>&1 | grep -q "could not be found" && echo "PASS: Service removed"

# Verify application removed
! test -d /opt/docling-mcp/venv && echo "PASS: venv removed"

# Verify service unit removed
! test -f /etc/systemd/system/docling-mcp.service && echo "PASS: Service unit removed"

# Verify port released
! sudo netstat -tulpn | grep :8000 && echo "PASS: Port 8000 released"
```

**Expected**: All rollback cleanup successful, clean state achieved

**Pass Criteria**: ALL verification checks PASS

---

### Step 4: Re-Deploy and Verify Identical Results

**Action**:
```bash
# Re-execute deployment tasks 001-019
# (Follow deployment procedure again)

# After re-deployment, compare to pre-rollback state
systemctl status docling-mcp.service > /tmp/post-rollback-status.txt
curl -s http://192.168.10.217:8000/health > /tmp/post-rollback-health.json

# Verify service operational again
systemctl is-active docling-mcp.service
curl -s http://192.168.10.217:8000/health | jq '.status'
```

**Expected**: Service operational again, health endpoint responds identically

**Pass Criteria**: Re-deployment successful, service functional

---

### Step 5: Verify Rollback Didn't Damage Node

**Action**:
```bash
# Verify no system damage from rollback
df -h  # Check disk space unchanged
sudo systemctl status  # Check systemd still functional
ping -c 3 192.168.10.212  # Check network still functional
```

**Expected**: Node fully functional, no system damage

---

## Pass/Fail Criteria

**PASS Conditions (ALL MUST BE TRUE)**:
1. Rollback procedure executes without errors
2. Clean state achieved (service stopped, files removed, port released)
3. Re-deployment successful
4. Service functional after re-deployment (health endpoint responds)
5. No system damage from rollback procedure

**FAIL Conditions (ANY IS TRUE)**:
- Rollback procedure errors
- Cannot achieve clean state
- Re-deployment fails
- Service not functional after re-deployment
- System damage detected

**CRITICAL**: If this test FAILS, service MUST NOT be promoted to operational.

---

## Rollback Time Measurement

**Action**:
```bash
# Time the rollback procedure
time {
  sudo systemctl stop docling-mcp.service
  # ... (all rollback steps)
  sudo systemctl daemon-reload
}
```

**Expected**: Rollback completes within 15-30 minutes (manual procedure)

**Pass Criteria**: Rollback time < 30 minutes

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-critical-014-rollback-failure.md`, assign to william-chen

**Severity**: CRITICAL (blocks operational promotion)

**Resolution Required**: BEFORE operational promotion (zero exceptions)

---

## Sign-Off Requirement

**Rollback Test Sign-Off**:

This rollback test has been executed and validated successfully:

- [ ] Rollback procedure executed successfully
- [ ] Clean state achieved
- [ ] Re-deployment successful
- [ ] Service functional after re-deployment
- [ ] No system damage
- [ ] Rollback time < 30 minutes

**Tested By**: ___________________
**Date**: ___________________
**Signature**: ___________________

**Reviewed By (william-chen)**: ___________________
**Date**: ___________________
**Signature**: ___________________

**MANDATORY**: Sign-off REQUIRED before operational promotion.

---

**Test Case Version**: 1.0
