# Task 011: Verify Python 3.11+ Installation

**Task ID**: hx-lang-server-task-011
**Phase**: Pre-Deployment (System Dependencies)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 005 (Directory Permissions)
**Estimated Effort**: 30 minutes

---

## Objective

Verify Python 3.11+ is installed on hx-lang-server.hx.dev.local (Ubuntu 24.04 LTS) and configure as the runtime for the LangGraph service. Ubuntu 24.04 ships with Python 3.12 by default; this task validates availability and readiness.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 005 (Directory Permissions) completed

---

## Pre-Execution Validation

**CRITICAL**: Check if Python 3.11+ is already available BEFORE any installation steps.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check Python 3.11+ availability
echo "Checking Python 3.11+ installation status..."

# Check for Python 3.12 (Ubuntu 24.04 default)
if command -v python3.12 > /dev/null 2>&1; then
    PYTHON_VERSION=$(python3.12 --version)
    echo "Python 3.12 found: $PYTHON_VERSION"
    PYTHON_CMD="python3.12"
fi

# Check for Python 3.11
if command -v python3.11 > /dev/null 2>&1; then
    PYTHON_VERSION=$(python3.11 --version)
    echo "Python 3.11 found: $PYTHON_VERSION"
    PYTHON_CMD="python3.11"
fi

# Check default python3
if command -v python3 > /dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version)
    echo "Default python3: $PYTHON_VERSION"

    # Extract major.minor version
    VERSION_NUM=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

    if [[ "$VERSION_NUM" == "3.11" || "$VERSION_NUM" == "3.12" || "$VERSION_NUM" > "3.11" ]]; then
        echo "Default python3 meets minimum requirement (3.11+)"
        PYTHON_CMD="python3"
    fi
fi

if [ -n "$PYTHON_CMD" ]; then
    echo ""
    echo "VALIDATION RESULT: Python 3.11+ is available"
    echo "Selected Python interpreter: $PYTHON_CMD"
    echo "ACTION: SKIP installation, proceed to venv module validation"
else
    echo ""
    echo "VALIDATION RESULT: Python 3.11+ not found"
    echo "ACTION: PROCEED with installation steps"
fi
```

**If Already Available**: Skip to Step 3 (venv module validation)
**If Not Available**: Continue with Step 1 below

---

## Implementation Steps

### Step 1: Update Package Repository Cache

```bash
# Update apt package cache
sudo apt-get update

# Verify update successful
if [ $? -eq 0 ]; then
    echo "APT cache updated successfully"
else
    echo "APT cache update failed - check DNS and network connectivity"
    exit 1
fi
```

### Step 2: Install Python 3.11 (if needed)

**Note**: Ubuntu 24.04 LTS includes Python 3.12 by default. Python 3.11 can be installed from deadsnakes PPA if specifically required, but Python 3.12 is recommended.

```bash
# Install Python 3.12 (Ubuntu 24.04 default) - typically already present
sudo apt-get install -y python3.12 python3.12-venv python3.12-dev

# Verify installation
python3.12 --version

# If Python 3.11 specifically required (not recommended):
# sudo add-apt-repository ppa:deadsnakes/ppa
# sudo apt-get update
# sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
```

### Step 3: Verify venv Module Availability

```bash
# Verify venv module is available
echo "Verifying venv module availability..."

# Test with Python 3.12 (preferred for Ubuntu 24.04)
if python3.12 -m venv --help > /dev/null 2>&1; then
    echo "python3.12-venv module available"
    PYTHON_CMD="python3.12"
else
    echo "python3.12-venv module NOT available"

    # Install venv module
    sudo apt-get install -y python3.12-venv
fi

# Verify again
if $PYTHON_CMD -m venv --help > /dev/null 2>&1; then
    echo "venv module confirmed available for $PYTHON_CMD"
else
    echo "ERROR: venv module still not available after installation"
    exit 1
fi
```

### Step 4: Verify pip Availability

```bash
# Verify pip module availability
echo "Verifying pip module availability..."

# Check pip version
$PYTHON_CMD -m pip --version

if [ $? -eq 0 ]; then
    echo "pip module available"
else
    echo "pip module NOT available"

    # Install pip if missing
    sudo apt-get install -y python3-pip

    # Verify again
    $PYTHON_CMD -m pip --version
fi
```

### Step 5: Document Python Configuration

```bash
# Document Python configuration for future reference
DOC_DIR="/opt/hx-lang-server/deployment-docs"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/python-configuration.txt" > /dev/null <<EOF
# Python Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-011

## Python Interpreter
Primary: $PYTHON_CMD
Path: $(which $PYTHON_CMD)
Version: $($PYTHON_CMD --version)

## Modules
venv: Available ($PYTHON_CMD -m venv)
pip: $($PYTHON_CMD -m pip --version)

## System Python Versions Available
$(ls -la /usr/bin/python* 2>/dev/null || echo "No system Python binaries found")

## Specification Reference
- Minimum Required: Python 3.11+
- Specification: node-spec.md (LangGraph requirement)
- LangGraph v0.3.x requires Python 3.10+
EOF

echo "Python configuration documented: $DOC_DIR/python-configuration.txt"
cat "$DOC_DIR/python-configuration.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Python Runtime | /usr/bin/python3.12 | Python 3.12 interpreter (Ubuntu 24.04 default) |
| venv Module | python3.12-venv | Virtual environment module |
| pip Module | python3-pip | Package installer |
| Configuration Doc | /opt/hx-lang-server/deployment-docs/python-configuration.txt | Python setup documentation |

---

## Verification

**Validation Commands:**

```bash
echo "=== Python 3.11+ Installation Validation ==="

# Check 1: Python interpreter available
echo "1. Python Interpreter:"
if command -v python3.12 > /dev/null 2>&1; then
    python3.12 --version
    echo "PASSED: Python 3.12 available"
elif command -v python3.11 > /dev/null 2>&1; then
    python3.11 --version
    echo "PASSED: Python 3.11 available"
else
    echo "FAILED: Python 3.11+ not found"
    exit 1
fi

# Check 2: venv module
echo ""
echo "2. venv Module:"
if python3 -m venv --help > /dev/null 2>&1; then
    echo "PASSED: venv module available"
else
    echo "FAILED: venv module not available"
    exit 1
fi

# Check 3: pip module
echo ""
echo "3. pip Module:"
if python3 -m pip --version > /dev/null 2>&1; then
    python3 -m pip --version
    echo "PASSED: pip module available"
else
    echo "FAILED: pip module not available"
    exit 1
fi

# Check 4: Python version meets minimum
echo ""
echo "4. Version Requirement:"
VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
if [[ "$VERSION" == "3.11" || "$VERSION" == "3.12" || "$VERSION" > "3.11" ]]; then
    echo "PASSED: Python $VERSION meets minimum requirement (3.11+)"
else
    echo "FAILED: Python $VERSION does not meet minimum requirement (3.11+)"
    exit 1
fi

echo ""
echo "=== Validation Summary ==="
echo "ALL VALIDATIONS PASSED - Python 3.11+ ready for hx-lang-server"
```

**Expected Results:**
- Python 3.12.x (or 3.11.x) installed and available
- venv module responds to --help flag
- pip module shows version information
- Python version >= 3.11

---

## Rollback Procedure

Python packages installed via apt can be removed if needed:

```bash
# Remove Python packages (CAUTION: may break system dependencies)
# Only execute if absolutely necessary

# Remove venv module only (safe)
sudo apt-get remove --purge python3.12-venv

# Remove Python 3.11 (if installed from PPA)
# sudo apt-get remove --purge python3.11 python3.11-venv python3.11-dev

# Note: Do NOT remove python3.12 on Ubuntu 24.04 - it is the system Python
```

---

## Notes

**Ubuntu 24.04 LTS Python:**
- Default Python is 3.12.x (not 3.11)
- Python 3.12 fully compatible with LangGraph requirements
- No need to downgrade to 3.11 unless specific library incompatibility found

**LangGraph Compatibility:**
- LangGraph v0.3.x requires Python >= 3.10
- Python 3.12 tested and supported
- All langchain ecosystem libraries support Python 3.12

**Virtual Environment Strategy:**
- System Python remains untouched
- Application dependencies isolated in /opt/hx-lang-server/venv
- Virtual environment created in Task 013

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Dependencies - Python Dependencies (lines 600-626)
- Section: Node Requirements - Operating System (lines 122-125)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 2: System Dependencies (Task Range 011-020)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **System Python conflict**: Installing additional Python version conflicts with system packages
   - Mitigation: Use Ubuntu default Python 3.12; avoid modifying system Python
2. **Missing venv module**: venv not installed by default
   - Mitigation: Install python3.12-venv package before virtual environment creation

**Dependencies Blocked:**
- Task 013 (Create Virtual Environment) depends on Python 3.11+ with venv module
- All subsequent Python-based tasks depend on this task
