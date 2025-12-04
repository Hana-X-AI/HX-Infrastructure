# Test Case: Verify Python Installation

**Test ID**: tc-lang-server-deployment-002-python-installation
**Service**: hx-lang-server
**Test Area**: deployment
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-001 (System up on Ubuntu 24.04 with Python 3.11+)
**Based on Plan**: Work Stream 2 - System Dependencies (Task 011)
**Test Type**: Manual
**Estimated Execution Time**: 3 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that Python 3.11 or higher is installed on the target system, including pip and required build dependencies for LangGraph and its dependencies.

**Why This Test Is Important:**
LangGraph and LangChain require Python 3.11+ for async features and type annotations. Without the correct Python version, the service cannot be installed or run.

---

## Prerequisites

**Service State:**
- [ ] Ubuntu 24.04 LTS installed on target node
- [ ] System package manager (apt) functional

**Dependencies:**
- [ ] Network connectivity for package verification

**Environment:**
- [ ] SSH access to hx-lang-server.hx.dev.local

**Permissions:**
- [ ] Standard user access sufficient for version checks

---

## Test Setup

### Pre-Test Actions
1. Establish SSH connection to target node
2. Prepare to capture version information

### Test Data
**Required Test Data:**
- Minimum Python version: 3.11.0
- Required pip version: 23.0+

---

## Test Steps

### Step 1: Verify Python 3 Version
**Action:**
```bash
python3 --version
```

**Expected Behavior:**
Returns Python version 3.11.x or higher.

**How to Verify:**
Version number should be >= 3.11.0

---

### Step 2: Verify Python3.11 Binary Exists
**Action:**
```bash
which python3.11 || which python3
```

**Expected Behavior:**
Returns path to Python 3.11+ binary.

**How to Verify:**
Path should be returned (e.g., `/usr/bin/python3` or `/usr/bin/python3.11`).

---

### Step 3: Verify pip Installation
**Action:**
```bash
python3 -m pip --version
```

**Expected Behavior:**
Returns pip version and Python version it is associated with.

**How to Verify:**
pip should be installed and associated with Python 3.11+.

---

### Step 4: Verify venv Module Available
**Action:**
```bash
python3 -m venv --help | head -5
```

**Expected Behavior:**
Returns help text for venv module.

**How to Verify:**
Help text should be displayed without errors.

---

### Step 5: Verify Essential Build Dependencies
**Action:**
```bash
dpkg -l | grep -E "python3-dev|build-essential|libpq-dev" | wc -l
```

**Expected Behavior:**
Returns count of installed build packages (should be >= 2).

**How to Verify:**
Count should be >= 2 indicating essential build tools are installed.

---

### Step 6: Verify Async Support
**Action:**
```bash
python3 -c "import asyncio; print(asyncio.__version__ if hasattr(asyncio, '__version__') else 'built-in')"
```

**Expected Behavior:**
Returns asyncio availability (built-in for Python 3.11+).

**How to Verify:**
No import error; asyncio is available.

---

## Expected Results

### Primary Expected Results
- [ ] Python version is 3.11.0 or higher
- [ ] pip is installed and functional
- [ ] venv module is available
- [ ] Build dependencies are installed
- [ ] asyncio module is available

### Observable Indicators
**System State:**
- Python 3.11+ available in PATH
- pip can install packages
- venv can create virtual environments

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Python version >= 3.11.0
2. pip is installed and functional
3. venv module works
4. Build dependencies installed
5. No errors during verification

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Python version < 3.11.0
2. Python not installed
3. pip not available
4. venv module missing
5. Build dependencies missing

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Cannot SSH to target node
2. System package database corrupted

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
1. No cleanup required for read-only verification test

### Environment Reset
- [ ] No changes made to environment

---

## Notes and Observations

### Dependencies on Other Tests
- This test must pass before deployment-005 (Virtual Environment)
- This test validates SC-001 partially

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - Node Requirements section (Python 3.11+)

**Related Test Cases:**
- `tc-lang-server-deployment-005-virtual-environment.md` - Depends on this test
- `tc-lang-server-deployment-006-python-dependencies.md` - Depends on this test

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
