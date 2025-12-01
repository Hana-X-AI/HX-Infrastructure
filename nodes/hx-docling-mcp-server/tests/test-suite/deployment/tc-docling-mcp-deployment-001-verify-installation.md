# Test Case: Verify Service Installation

**Test ID**: tc-docling-mcp-deployment-001
**Test Area**: Deployment Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos (Testing & Quality Specialist)

---

## Test Objective

Verify that the Docling MCP Server is correctly installed on hx-docling-mcp-server (192.168.10.217) with all required components in place.

---

## Prerequisites

- Deployment tasks 001-013 executed (Tasks in `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/`)
- SSH access to hx-docling-mcp-server (192.168.10.217)
- `sudo` privileges for validation commands

---

## Test Coverage

**Requirements Covered**:
- DR-001: Service installed correctly
- Charter Section: Deployment Strategy (lines 342-363)
- Plan Section: Phase 2 - Installation Tasks (lines 766-777)

**Success Criteria**:
- Python virtual environment exists at `/opt/docling-mcp/venv`
- FastMCP framework installed (version >=0.2)
- docling library installed (version ~=2.25)
- LightRAG framework installed
- All Python dependencies from requirements.txt installed
- Application code deployed to `/opt/docling-mcp/application/`

---

## Test Steps

### Step 1: Verify Python Virtual Environment

**Action**:
```bash
# Check virtual environment exists
test -d /opt/docling-mcp/venv && echo "PASS: venv exists" || echo "FAIL: venv missing"

# Check venv activation script exists
test -f /opt/docling-mcp/venv/bin/activate && echo "PASS: activate script exists" || echo "FAIL: activate script missing"

# Verify Python version in venv
/opt/docling-mcp/venv/bin/python --version
```

**Expected Result**:
- Directory `/opt/docling-mcp/venv` exists
- Activation script exists
- Python version >= 3.11 (e.g., "Python 3.12.7")

**Pass Criteria**: All three checks PASS

---

### Step 2: Verify FastMCP Framework Installation

**Action**:
```bash
# Check FastMCP installed
/opt/docling-mcp/venv/bin/pip show fastmcp

# Verify version >=0.2
/opt/docling-mcp/venv/bin/python -c "import fastmcp; print(f'FastMCP version: {fastmcp.__version__}')"
```

**Expected Result**:
```
Name: fastmcp
Version: 0.2.x or higher
Location: /opt/docling-mcp/venv/lib/python3.12/site-packages
Requires: pydantic, httpx, ...
```

**Pass Criteria**: FastMCP installed with version >=0.2

---

### Step 3: Verify Docling Library Installation

**Action**:
```bash
# Check docling installed
/opt/docling-mcp/venv/bin/pip show docling

# Verify version ~=2.25
/opt/docling-mcp/venv/bin/python -c "import docling; print(f'Docling version: {docling.__version__}')"
```

**Expected Result**:
```
Name: docling
Version: 2.25.x
Location: /opt/docling-mcp/venv/lib/python3.12/site-packages
```

**Pass Criteria**: Docling installed with version 2.25.x

---

### Step 4: Verify LightRAG Framework Installation

**Action**:
```bash
# Check lightrag installed
/opt/docling-mcp/venv/bin/pip show lightrag

# Verify import works
/opt/docling-mcp/venv/bin/python -c "import lightrag; print('LightRAG import successful')"
```

**Expected Result**:
```
Name: lightrag
Version: (latest stable)
Location: /opt/docling-mcp/venv/lib/python3.12/site-packages
LightRAG import successful
```

**Pass Criteria**: LightRAG installed and imports successfully

---

### Step 5: Verify Core Python Dependencies

**Action**:
```bash
# Check all required packages installed
/opt/docling-mcp/venv/bin/pip list | grep -E "pydantic|qdrant-client|redis|litellm"

# Verify critical imports work
/opt/docling-mcp/venv/bin/python << 'EOF'
import pydantic
import qdrant_client
import redis
import litellm
print("All core dependencies imported successfully")
EOF
```

**Expected Result**:
```
pydantic        2.10.x
qdrant-client   1.x.x
redis           5.x.x
litellm         1.x.x
All core dependencies imported successfully
```

**Pass Criteria**: All dependencies installed and importable

---

### Step 6: Verify Application Code Deployment

**Action**:
```bash
# Check application directory exists
test -d /opt/docling-mcp/application && echo "PASS: application directory exists" || echo "FAIL: application directory missing"

# Check main server module exists
test -f /opt/docling-mcp/application/docling_mcp/server.py && echo "PASS: server.py exists" || echo "FAIL: server.py missing"

# Check MCP tools directory exists
test -d /opt/docling-mcp/application/docling_mcp/tools && echo "PASS: tools directory exists" || echo "FAIL: tools directory missing"

# List key application files
ls -la /opt/docling-mcp/application/docling_mcp/
```

**Expected Result**:
```
PASS: application directory exists
PASS: server.py exists
PASS: tools directory exists

Directory listing shows:
- server.py (main MCP server entry point)
- tools/ (directory with MCP tool implementations)
- __init__.py
- config.py (configuration module)
```

**Pass Criteria**: All application code files present

---

### Step 7: Verify Installation Completeness

**Action**:
```bash
# Run comprehensive installation check script
/opt/docling-mcp/tests/scripts/check-installation.sh
```

**Expected Result**:
```
Installation Validation Report
==============================
[PASS] Python virtual environment
[PASS] FastMCP framework (version 0.2.x)
[PASS] Docling library (version 2.25.x)
[PASS] LightRAG framework
[PASS] Python dependencies (48/48 installed)
[PASS] Application code deployed
[PASS] Configuration templates present

Overall Status: PASS
```

**Pass Criteria**: Overall status = PASS

---

## Expected Results

**All Steps Pass**:
- Virtual environment created and functional
- All required Python packages installed with correct versions
- Application code deployed to correct location
- Installation validation script reports PASS

**Evidence Files**:
- `/tmp/tc-deployment-001-installation-verification.log` (command outputs)
- `/tmp/tc-deployment-001-pip-list.txt` (complete package list)

---

## Pass/Fail Criteria

**PASS Conditions**:
1. Python virtual environment exists at `/opt/docling-mcp/venv`
2. FastMCP >=0.2 installed and importable
3. docling ~=2.25 installed and importable
4. LightRAG installed and importable
5. All core dependencies (pydantic, qdrant-client, redis, litellm) installed
6. Application code deployed to `/opt/docling-mcp/application/`
7. Installation check script reports PASS

**FAIL Conditions**:
- Any Python package missing
- Wrong package versions installed
- Application code not deployed
- Import errors for any core dependency

**BLOCKED Conditions**:
- Cannot SSH to hx-docling-mcp-server
- No sudo privileges
- Deployment tasks 001-013 not executed

---

## Test Data

**Required Test Files**: None (validation only)

**Test Environment**:
- Node: hx-docling-mcp-server (192.168.10.217)
- OS: Ubuntu 24.04 LTS
- Python: 3.11+

---

## Defect Logging

**IF FAIL**:
1. Create defect ticket: `defect-docling-mcp-critical-001-installation-incomplete.md`
2. Severity: CRITICAL (blocks all downstream testing)
3. Assign to: william-chen (Infrastructure Lead)
4. Include: Complete pip list, error logs, missing components
5. Action: STOP all testing until installation complete

**Defect Template Location**: `/home/agent0/HX-Infrastructure/templates/testing/defect-template.md`

---

## Notes

- This test MUST pass before any functionality or integration testing
- Installation failures block all downstream deployment tasks
- Re-run after any installation corrections to verify fix

---

## Test Execution Log Template

```
Test Execution: tc-docling-mcp-deployment-001
Date: YYYY-MM-DD
Executor: <name>
Environment: hx-docling-mcp-server (192.168.10.217)

Step 1 - Virtual Environment: [PASS/FAIL]
Step 2 - FastMCP Framework: [PASS/FAIL]
Step 3 - Docling Library: [PASS/FAIL]
Step 4 - LightRAG Framework: [PASS/FAIL]
Step 5 - Core Dependencies: [PASS/FAIL]
Step 6 - Application Code: [PASS/FAIL]
Step 7 - Installation Check Script: [PASS/FAIL]

Overall Result: [PASS/FAIL/BLOCKED]
Defect Created: [YES/NO] - [defect-ID if applicable]
Evidence Location: /tmp/tc-deployment-001-*.log

Signature: ___________________
Date: ___________________
```

---

**Test Case Version**: 1.0
**Last Updated**: 2025-11-27
**Review Status**: Pending Review
**Approved By**: TBD
