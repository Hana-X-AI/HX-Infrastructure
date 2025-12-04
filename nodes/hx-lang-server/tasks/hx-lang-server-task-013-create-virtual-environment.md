# Task 013: Create Python Virtual Environment

**Task ID**: hx-lang-server-task-013
**Phase**: Pre-Deployment (System Dependencies)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 011 (Python Installation), Task 012 (System Packages), Task 003 (Directory Structure)
**Estimated Effort**: 30 minutes

---

## Objective

Create Python virtual environment at `/opt/hx-lang-server/venv` for isolating LangGraph application dependencies from system Python packages.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 011 (Python Installation) completed - Python 3.11+ available
- [ ] Task 012 (System Packages) completed - build tools available
- [ ] Task 003 (Directory Structure) completed - /opt/hx-lang-server exists
- [ ] Service account hx-lang-server exists (Task 001)

---

## Pre-Execution Validation

**CRITICAL**: Check if virtual environment already exists BEFORE creating new one.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check virtual environment status
VENV_PATH="/opt/hx-lang-server/venv"

echo "Checking virtual environment status..."

if [ -d "$VENV_PATH" ]; then
    echo "Virtual environment directory exists: $VENV_PATH"

    # Check if it's a valid virtual environment
    if [ -f "$VENV_PATH/bin/activate" ] && [ -f "$VENV_PATH/bin/python" ]; then
        echo "Valid virtual environment detected"
        echo ""
        echo "Python version in venv:"
        $VENV_PATH/bin/python --version
        echo ""
        echo "pip version in venv:"
        $VENV_PATH/bin/pip --version
        echo ""
        echo "VALIDATION RESULT: Virtual environment already exists"
        echo "ACTION: SKIP creation, proceed to validation section"
    else
        echo "WARNING: Directory exists but is not a valid virtual environment"
        echo "ACTION: Remove and recreate virtual environment"
    fi
else
    echo "VALIDATION RESULT: Virtual environment does not exist"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Exists**: Skip to Validation section
**If Not Exists**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Verify Base Directory Exists

```bash
# Verify application directory exists
APP_DIR="/opt/hx-lang-server"

if [ -d "$APP_DIR" ]; then
    echo "Application directory exists: $APP_DIR"
    ls -la "$APP_DIR"
else
    echo "ERROR: Application directory does not exist"
    echo "Prerequisite Task 003 (Directory Structure) may not be complete"
    exit 1
fi
```

### Step 2: Identify Python Interpreter

```bash
# Determine which Python interpreter to use
echo "Identifying Python interpreter..."

if command -v python3.12 > /dev/null 2>&1; then
    PYTHON_CMD="python3.12"
    echo "Using Python 3.12: $(python3.12 --version)"
elif command -v python3.11 > /dev/null 2>&1; then
    PYTHON_CMD="python3.11"
    echo "Using Python 3.11: $(python3.11 --version)"
else
    PYTHON_CMD="python3"
    VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    echo "Using default python3: $VERSION"

    # Verify minimum version
    if [[ ! "$VERSION" > "3.10" ]]; then
        echo "ERROR: Python version $VERSION does not meet minimum requirement (3.11+)"
        exit 1
    fi
fi

echo "Selected Python interpreter: $PYTHON_CMD"
```

### Step 3: Create Virtual Environment

```bash
# Create virtual environment
VENV_PATH="/opt/hx-lang-server/venv"

echo "Creating virtual environment at $VENV_PATH..."

# Use sudo to create venv in /opt directory
sudo $PYTHON_CMD -m venv "$VENV_PATH"

if [ $? -eq 0 ]; then
    echo "Virtual environment created successfully"
else
    echo "ERROR: Virtual environment creation failed"
    exit 1
fi

# Verify virtual environment structure
ls -la "$VENV_PATH"
ls -la "$VENV_PATH/bin"
```

### Step 4: Set Virtual Environment Ownership

```bash
# Set ownership to service account
VENV_PATH="/opt/hx-lang-server/venv"
SERVICE_USER="hx-lang-server"

echo "Setting virtual environment ownership..."

# Check if domain account exists
if getent passwd "hx-lang-server@hx.dev.local" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server@hx.dev.local"
    SERVICE_GROUP="domain users@hx.dev.local"
    echo "Using Samba AD domain account: $SERVICE_USER"
elif getent passwd "hx-lang-server" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server"
    SERVICE_GROUP="hx-lang-server"
    echo "Using local system account: $SERVICE_USER"
else
    echo "WARNING: Service account not found, using root ownership temporarily"
    SERVICE_USER="root"
    SERVICE_GROUP="root"
fi

# Set ownership recursively
sudo chown -R "$SERVICE_USER:$SERVICE_GROUP" "$VENV_PATH"

# Verify ownership
ls -la "$VENV_PATH"
echo "Ownership set to $SERVICE_USER:$SERVICE_GROUP"
```

### Step 5: Upgrade pip in Virtual Environment

```bash
# Upgrade pip to latest version
VENV_PATH="/opt/hx-lang-server/venv"

echo "Upgrading pip in virtual environment..."

# Run as service account if possible, otherwise use sudo
sudo -u "$SERVICE_USER" "$VENV_PATH/bin/pip" install --upgrade pip 2>/dev/null || \
    sudo "$VENV_PATH/bin/pip" install --upgrade pip

# Verify pip upgrade
"$VENV_PATH/bin/pip" --version

if [ $? -eq 0 ]; then
    echo "pip upgraded successfully"
else
    echo "WARNING: pip upgrade may have failed"
fi
```

### Step 6: Install Essential Build Tools in venv

```bash
# Install wheel and setuptools for package building
VENV_PATH="/opt/hx-lang-server/venv"

echo "Installing essential build tools..."

sudo -u "$SERVICE_USER" "$VENV_PATH/bin/pip" install --upgrade setuptools wheel 2>/dev/null || \
    sudo "$VENV_PATH/bin/pip" install --upgrade setuptools wheel

# Verify installations
"$VENV_PATH/bin/pip" show setuptools | head -n2
"$VENV_PATH/bin/pip" show wheel | head -n2

echo "Build tools installed in virtual environment"
```

### Step 7: Document Virtual Environment Configuration

```bash
# Document virtual environment configuration
DOC_DIR="/opt/hx-lang-server/deployment-docs"
VENV_PATH="/opt/hx-lang-server/venv"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/virtual-environment-configuration.txt" > /dev/null <<EOF
# Virtual Environment Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-013

## Virtual Environment
Path: $VENV_PATH
Python: $($VENV_PATH/bin/python --version)
pip: $($VENV_PATH/bin/pip --version)

## Ownership
Owner: $SERVICE_USER
Group: $SERVICE_GROUP

## Activation
# To activate (bash):
source $VENV_PATH/bin/activate

# To deactivate:
deactivate

## Package Management
# Install package:
$VENV_PATH/bin/pip install <package>

# List installed packages:
$VENV_PATH/bin/pip list

# Freeze requirements:
$VENV_PATH/bin/pip freeze > requirements.txt

## Directory Structure
$(ls -la $VENV_PATH)

## Base Packages Installed
$(\"$VENV_PATH/bin/pip\" list)
EOF

echo "Virtual environment documented: $DOC_DIR/virtual-environment-configuration.txt"
cat "$DOC_DIR/virtual-environment-configuration.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Virtual Environment | /opt/hx-lang-server/venv | Python virtual environment directory |
| Python Interpreter | /opt/hx-lang-server/venv/bin/python | Isolated Python interpreter |
| pip Installer | /opt/hx-lang-server/venv/bin/pip | Package installer |
| Activate Script | /opt/hx-lang-server/venv/bin/activate | Shell activation script |
| Configuration Doc | /opt/hx-lang-server/deployment-docs/virtual-environment-configuration.txt | Documentation |

---

## Verification

**Validation Commands:**

```bash
echo "=== Virtual Environment Validation ==="

VENV_PATH="/opt/hx-lang-server/venv"
VALIDATION_PASSED=true

# Check 1: Directory exists
echo "1. Virtual Environment Directory:"
if [ -d "$VENV_PATH" ]; then
    echo "PASSED: Directory exists at $VENV_PATH"
else
    echo "FAILED: Directory does not exist"
    VALIDATION_PASSED=false
fi

# Check 2: Python interpreter
echo ""
echo "2. Python Interpreter:"
if [ -x "$VENV_PATH/bin/python" ]; then
    "$VENV_PATH/bin/python" --version
    echo "PASSED: Python interpreter available"
else
    echo "FAILED: Python interpreter not found or not executable"
    VALIDATION_PASSED=false
fi

# Check 3: pip available
echo ""
echo "3. pip Installer:"
if [ -x "$VENV_PATH/bin/pip" ]; then
    "$VENV_PATH/bin/pip" --version
    echo "PASSED: pip available"
else
    echo "FAILED: pip not found or not executable"
    VALIDATION_PASSED=false
fi

# Check 4: Activation script
echo ""
echo "4. Activation Script:"
if [ -f "$VENV_PATH/bin/activate" ]; then
    echo "PASSED: Activation script exists"
else
    echo "FAILED: Activation script not found"
    VALIDATION_PASSED=false
fi

# Check 5: Python version meets requirement
echo ""
echo "5. Python Version:"
VERSION=$("$VENV_PATH/bin/python" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
if [[ "$VERSION" == "3.11" || "$VERSION" == "3.12" || "$VERSION" > "3.11" ]]; then
    echo "PASSED: Python $VERSION meets minimum requirement (3.11+)"
else
    echo "FAILED: Python $VERSION does not meet minimum requirement"
    VALIDATION_PASSED=false
fi

# Check 6: Ownership
echo ""
echo "6. Directory Ownership:"
OWNER=$(stat -c '%U' "$VENV_PATH")
if [[ "$OWNER" == "hx-lang-server" || "$OWNER" == "hx-lang-server@hx.dev.local" || "$OWNER" == "root" ]]; then
    echo "PASSED: Ownership is $OWNER"
else
    echo "WARNING: Unexpected ownership: $OWNER"
fi

# Check 7: Can install packages
echo ""
echo "7. Package Installation Test:"
"$VENV_PATH/bin/pip" install --dry-run httpx > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "PASSED: Can install packages (dry-run test)"
else
    echo "WARNING: Package installation test failed"
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Virtual environment ready for hx-lang-server"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- Virtual environment directory exists at /opt/hx-lang-server/venv
- Python interpreter shows version 3.11+ or 3.12+
- pip shows latest version
- Activation script exists
- Ownership set to service account
- Packages can be installed (dry-run test passes)

---

## Rollback Procedure

Remove virtual environment if needed:

```bash
# Remove virtual environment completely
VENV_PATH="/opt/hx-lang-server/venv"

echo "Removing virtual environment..."

# Remove directory
sudo rm -rf "$VENV_PATH"

# Verify removal
if [ ! -d "$VENV_PATH" ]; then
    echo "Virtual environment removed successfully"
else
    echo "ERROR: Failed to remove virtual environment"
fi

# Note: This is a clean operation - no system impact
# Virtual environment can be recreated by re-running this task
```

---

## Notes

**Virtual Environment Location:**
- Path: /opt/hx-lang-server/venv
- Isolated from system Python
- All application dependencies installed here
- Service account has write access

**Python Version:**
- Uses system Python 3.12 (Ubuntu 24.04 default) or Python 3.11
- LangGraph v0.3.x requires Python >= 3.10
- Virtual environment inherits system Python version

**Ownership Considerations:**
- venv owned by service account (hx-lang-server)
- Allows service to modify packages if needed
- pip install commands run as service account

**Best Practices:**
- Never install packages with sudo pip install (use venv pip)
- Always use absolute paths to venv executables in systemd
- Keep pip updated for security fixes

**systemd Integration:**
- ExecStart uses /opt/hx-lang-server/venv/bin/uvicorn
- PATH includes /opt/hx-lang-server/venv/bin
- EnvironmentFile sets VIRTUAL_ENV if needed

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Service Account - Home Directory (lines 136-139)
- Section: systemd Service Configuration (lines 816-842)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 2: System Dependencies (Task Range 011-020)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **Permission denied**: Cannot create directory in /opt
   - Mitigation: Use sudo for venv creation; set ownership afterward
2. **Corrupted venv**: Partial creation leaves broken environment
   - Mitigation: Rollback procedure removes entire directory
3. **Wrong Python version**: venv created with incompatible Python
   - Mitigation: Explicitly specify Python interpreter; verify version

**Dependencies Blocked:**
- Task 014 (Install Python Dependencies) requires virtual environment
- All subsequent Python package installations depend on this task
