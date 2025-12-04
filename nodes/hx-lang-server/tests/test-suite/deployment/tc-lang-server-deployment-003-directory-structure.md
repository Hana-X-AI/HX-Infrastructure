# Test Case: Verify Directory Structure

**Test ID**: tc-lang-server-deployment-003-directory-structure
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Node Requirements - Home Directory `/opt/hx-lang-server`
**Based on Plan**: Work Stream 1 - Identity & Infrastructure (Task 003)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the complete directory structure for hx-lang-server has been created with correct ownership and permissions, including application, configuration, logs, and data directories.

**Why This Test Is Important:**
The service requires specific directory layout for application code, configuration files, logs, and virtual environment. Incorrect structure or permissions will prevent service startup.

---

## Prerequisites

**Service State:**
- [ ] Service account `hx-lang-server` created (deployment-001 passed)

**Dependencies:**
- [ ] Filesystem mounted and accessible

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] sudo access for permission verification

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection to target node
2. Ensure deployment-001 has passed

### Test Data
**Required Test Data:**
- Base directory: `/opt/hx-lang-server`
- Expected subdirectories: `app`, `venv`, `logs`, `config`, `data`
- Expected owner: `hx-lang-server:hx-lang-server`
- Expected permissions: 750 (directories), 640 (config files)

---

## Test Steps

### Step 1: Verify Base Directory Exists
**Action:**
```bash
ls -ld /opt/hx-lang-server
```

**Expected Behavior:**
Directory exists with owner `hx-lang-server`.

**How to Verify:**
Output shows directory owned by hx-lang-server user and group.

---

### Step 2: Verify Application Directory
**Action:**
```bash
ls -ld /opt/hx-lang-server/app
```

**Expected Behavior:**
Application directory exists with correct ownership.

**How to Verify:**
Directory exists, owned by hx-lang-server, permissions 750 or similar.

---

### Step 3: Verify Virtual Environment Directory
**Action:**
```bash
ls -ld /opt/hx-lang-server/venv
```

**Expected Behavior:**
Virtual environment directory exists.

**How to Verify:**
Directory exists with hx-lang-server ownership.

---

### Step 4: Verify Logs Directory
**Action:**
```bash
ls -ld /opt/hx-lang-server/logs
```

**Expected Behavior:**
Logs directory exists and is writable.

**How to Verify:**
Directory exists, hx-lang-server can write to it.

---

### Step 5: Verify Config Directory
**Action:**
```bash
ls -ld /opt/hx-lang-server/config
```

**Expected Behavior:**
Configuration directory exists with restricted permissions.

**How to Verify:**
Directory exists, permissions restrict access appropriately.

---

### Step 6: Verify Data Directory
**Action:**
```bash
ls -ld /opt/hx-lang-server/data
```

**Expected Behavior:**
Data directory exists for persistent data storage.

**How to Verify:**
Directory exists with hx-lang-server ownership.

---

### Step 7: Verify Complete Directory Tree
**Action:**
```bash
find /opt/hx-lang-server -type d -exec ls -ld {} \; 2>/dev/null | head -20
```

**Expected Behavior:**
All directories owned by hx-lang-server with appropriate permissions.

**How to Verify:**
All listed directories show consistent ownership and permissions.

---

### Step 8: Verify Write Permissions
**Action:**
```bash
sudo -u hx-lang-server touch /opt/hx-lang-server/logs/test-write && rm /opt/hx-lang-server/logs/test-write && echo "Write test passed"
```

**Expected Behavior:**
Service account can write to logs directory.

**How to Verify:**
"Write test passed" message displayed.

---

## Expected Results

### Primary Expected Results
- [ ] Base directory `/opt/hx-lang-server` exists
- [ ] `app` subdirectory exists
- [ ] `venv` subdirectory exists
- [ ] `logs` subdirectory exists
- [ ] `config` subdirectory exists
- [ ] All directories owned by `hx-lang-server:hx-lang-server`
- [ ] Permissions allow service account access

### Observable Indicators
**Files:**
- All directories under `/opt/hx-lang-server` exist
- Ownership is consistent (hx-lang-server)
- Permissions are restrictive but functional

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Base directory exists and is accessible
2. All required subdirectories exist
3. All directories owned by hx-lang-server
4. Service account can write to logs directory
5. Permissions restrict unauthorized access

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Base directory does not exist
2. Any required subdirectory missing
3. Ownership incorrect
4. Service account cannot write to logs
5. Permissions too permissive (world-writable)

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service account does not exist (deployment-001 failed)
2. Cannot access filesystem

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

### Actual Observations
[Record what actually happened during test execution]

---

## Test Cleanup

### Post-Test Actions
1. Remove any test files created during verification

### Environment Reset
- [ ] Test write file removed

---

## Notes and Observations

### Dependencies on Other Tests
- Requires deployment-001 to pass first
- Required for deployment-005 (Virtual Environment)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Service Account and Home Directory

**Related Test Cases:**
- `tc-lang-server-deployment-001-service-account-creation.md` - Prerequisite
- `tc-lang-server-deployment-005-virtual-environment.md` - Depends on this

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
