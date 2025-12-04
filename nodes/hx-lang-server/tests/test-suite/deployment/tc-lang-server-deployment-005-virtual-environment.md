# Test Case: Verify Virtual Environment

**Test ID**: tc-lang-server-deployment-005-virtual-environment
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: Python Dependencies section, systemd Service Configuration
**Based on Plan**: Work Stream 2 - System Dependencies (Task 013)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the Python virtual environment has been created correctly at `/opt/hx-lang-server/venv` with Python 3.11+ and pip installed within the venv.

**Why This Test Is Important:**
The virtual environment isolates the service's Python dependencies from system packages, preventing conflicts and ensuring reproducible deployments.

---

## Prerequisites

**Service State:**
- [ ] Python 3.11+ installed (deployment-002 passed)
- [ ] Directory structure created (deployment-003 passed)

**Dependencies:**
- [ ] Python venv module available

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] Access as hx-lang-server user or sudo

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection to target node
2. Ensure directory structure exists

### Test Data
**Required Test Data:**
- Venv path: `/opt/hx-lang-server/venv`
- Expected Python version in venv: 3.11+
- Expected pip availability: yes

---

## Test Steps

### Step 1: Verify Venv Directory Exists
**Action:**
```bash
ls -ld /opt/hx-lang-server/venv
```

**Expected Behavior:**
Directory exists and contains venv structure.

**How to Verify:**
Directory is present with hx-lang-server ownership.

---

### Step 2: Verify Venv Python Binary
**Action:**
```bash
ls -l /opt/hx-lang-server/venv/bin/python
```

**Expected Behavior:**
Python binary exists in venv bin directory.

**How to Verify:**
Symlink or binary exists pointing to Python 3.11+.

---

### Step 3: Verify Venv Python Version
**Action:**
```bash
/opt/hx-lang-server/venv/bin/python --version
```

**Expected Behavior:**
Returns Python 3.11.x or higher.

**How to Verify:**
Version number >= 3.11.0.

---

### Step 4: Verify Venv pip Installation
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip --version
```

**Expected Behavior:**
pip is installed within venv.

**How to Verify:**
pip version returned, path should include venv directory.

---

### Step 5: Verify Venv Activation Script
**Action:**
```bash
ls -l /opt/hx-lang-server/venv/bin/activate
```

**Expected Behavior:**
Activation script exists.

**How to Verify:**
File is present and readable.

---

### Step 6: Verify Venv Isolation
**Action:**
```bash
/opt/hx-lang-server/venv/bin/python -c "import sys; print(sys.prefix)"
```

**Expected Behavior:**
sys.prefix points to venv directory.

**How to Verify:**
Output is `/opt/hx-lang-server/venv`.

---

### Step 7: Verify Venv Ownership
**Action:**
```bash
stat -c '%U:%G' /opt/hx-lang-server/venv/bin/python
```

**Expected Behavior:**
Owned by hx-lang-server user.

**How to Verify:**
Output shows `hx-lang-server:hx-lang-server`.

---

## Expected Results

### Primary Expected Results
- [ ] Venv directory exists at `/opt/hx-lang-server/venv`
- [ ] Python binary exists in venv/bin/
- [ ] Python version is 3.11+
- [ ] pip is installed within venv
- [ ] Activation script exists
- [ ] Venv is properly isolated
- [ ] Correct ownership

### Observable Indicators
**Files:**
- `/opt/hx-lang-server/venv/bin/python` exists
- `/opt/hx-lang-server/venv/bin/pip` exists
- `/opt/hx-lang-server/venv/bin/activate` exists
- `/opt/hx-lang-server/venv/lib/python3.11/` directory exists

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Venv directory exists
2. Python 3.11+ is the venv interpreter
3. pip is functional within venv
4. Venv is isolated from system Python
5. Correct ownership and permissions

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Venv directory does not exist
2. Python version in venv < 3.11
3. pip not available in venv
4. Venv not isolated (sys.prefix incorrect)
5. Wrong ownership/permissions

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Python not installed (deployment-002 failed)
2. Directory structure missing (deployment-003 failed)

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
1. No cleanup required for read-only verification

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Requires deployment-002 and deployment-003 to pass
- Required for deployment-006 (Python Dependencies)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Python Dependencies, systemd Configuration

**Related Test Cases:**
- `tc-lang-server-deployment-002-python-installation.md` - Prerequisite
- `tc-lang-server-deployment-006-python-dependencies.md` - Depends on this

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
