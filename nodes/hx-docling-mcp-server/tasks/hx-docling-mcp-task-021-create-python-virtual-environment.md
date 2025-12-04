# Task 021: Create Python Virtual Environment

**Assigned To**: william-chen
**Estimated Effort**: 1 hour
**Dependencies**: Task 011 (System Dependencies Installation)
**Status**: Not Started

## Objective

Create Python 3.11 virtual environment in `/opt/docling-mcp/venv/`, upgrade pip/setuptools/wheel, and prepare environment for Python dependency installation.

## Pre-Execution Validation

**CRITICAL**: Check if Python virtual environment already exists and is configured BEFORE creating new venv.

```bash
# Validation command to check if venv already exists
VENV_PATH="/opt/docling-mcp/venv"

echo "Checking Python virtual environment status..."

if [ -d "$VENV_PATH" ] && [ -f "$VENV_PATH/bin/activate" ] && [ -f "$VENV_PATH/bin/python" ]; then
    echo "✅ Virtual environment directory exists: $VENV_PATH"

    # Verify Python version in venv
    VENV_PYTHON_VERSION=$($VENV_PATH/bin/python --version 2>&1)
    echo "Virtual environment Python version: $VENV_PYTHON_VERSION"

    # Verify pip available
    if [ -f "$VENV_PATH/bin/pip" ]; then
        VENV_PIP_VERSION=$($VENV_PATH/bin/pip --version 2>&1)
        echo "Virtual environment pip version: $VENV_PIP_VERSION"

        echo ""
        echo "✅ VALIDATION RESULT: Python virtual environment already configured"
        echo "ACTION: SKIP task execution, proceed to validation section"
        exit 0
    else
        echo "❌ pip not found in venv, venv may be corrupt"
        echo "ACTION: PROCEED with recreation"
    fi
else
    echo "❌ VALIDATION RESULT: Virtual environment does not exist or incomplete"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Skip to Validation section
**If Not Complete**: Continue with Implementation Steps below

---

## Context

Python virtual environments provide isolated Python package installations, preventing system-wide package conflicts. The Docling MCP Server uses a dedicated virtual environment at `/opt/docling-mcp/venv/` for:

- **Dependency Isolation**: Separate from system Python packages
- **Version Control**: Lock specific package versions without affecting other services
- **Security**: Run with non-root user permissions (docling-mcp service account)
- **Reproducibility**: Document exact Python environment for disaster recovery

This task creates the virtual environment foundation. Python package installation occurs in subsequent tasks (Task 031 onwards).

## Acceptance Criteria

- [ ] Virtual environment created at `/opt/docling-mcp/venv/` using Python 3.11
- [ ] Virtual environment Python interpreter at `/opt/docling-mcp/venv/bin/python` (symlink to python3.11)
- [ ] pip upgraded to latest version (>=24.0)
- [ ] setuptools upgraded to latest version (>=69.0)
- [ ] wheel upgraded to latest version (>=0.43.0)
- [ ] Virtual environment owned by docling-mcp service account (User:Group matching Task 004)
- [ ] Virtual environment activation script functional (`source /opt/docling-mcp/venv/bin/activate`)
- [ ] No errors during venv creation or package upgrades

## Implementation Steps

### Step 1: Verify Python 3.11 Availability

```bash
# Verify Python 3.11 installed (dependency: Task 011)
echo "Verifying Python 3.11 installation..."

if command -v python3.11 > /dev/null 2>&1; then
    PYTHON_VERSION=$(python3.11 --version)
    echo "✅ Python 3.11 found: $PYTHON_VERSION"
else
    echo "❌ Python 3.11 not found - Task 011 prerequisite not met"
    exit 1
fi

# Verify venv module available
if python3.11 -m venv --help > /dev/null 2>&1; then
    echo "✅ Python 3.11 venv module available"
else
    echo "❌ Python 3.11 venv module not found"
    echo "Install with: sudo apt-get install python3.11-venv"
    exit 1
fi
```

### Step 2: Create Virtual Environment Directory

```bash
# Create Python virtual environment in /opt/docling-mcp/venv/
VENV_PATH="/opt/docling-mcp/venv"

echo "Creating Python 3.11 virtual environment at $VENV_PATH..."

python3.11 -m venv "$VENV_PATH"

if [ $? -eq 0 ] && [ -f "$VENV_PATH/bin/activate" ]; then
    echo "✅ Virtual environment created successfully"
else
    echo "❌ Virtual environment creation failed"
    exit 1
fi

# Verify venv Python version
VENV_PYTHON=$($VENV_PATH/bin/python --version)
echo "Virtual environment Python version: $VENV_PYTHON"
```

### Step 3: Upgrade pip, setuptools, and wheel

```bash
# Activate virtual environment and upgrade core packages
VENV_PATH="/opt/docling-mcp/venv"

echo "Upgrading pip, setuptools, and wheel to latest versions..."

# Upgrade pip first (pip can upgrade itself)
$VENV_PATH/bin/python -m pip install --upgrade pip

if [ $? -eq 0 ]; then
    PIP_VERSION=$($VENV_PATH/bin/pip --version)
    echo "✅ pip upgraded: $PIP_VERSION"
else
    echo "❌ pip upgrade failed"
    exit 1
fi

# Upgrade setuptools and wheel
$VENV_PATH/bin/pip install --upgrade setuptools wheel

if [ $? -eq 0 ]; then
    SETUPTOOLS_VERSION=$($VENV_PATH/bin/python -c "import setuptools; print(setuptools.__version__)")
    WHEEL_VERSION=$($VENV_PATH/bin/python -c "import wheel; print(wheel.__version__)")
    echo "✅ setuptools upgraded: $SETUPTOOLS_VERSION"
    echo "✅ wheel upgraded: $WHEEL_VERSION"
else
    echo "❌ setuptools/wheel upgrade failed"
    exit 1
fi
```

### Step 4: Configure Virtual Environment Ownership

**Service Account Override Mechanism**:

This step supports flexible service account configuration across different environments:

- **Environment Variable Overrides** (highest priority):
  - `SERVICE_USER_OVERRIDE`: Custom service account username
  - `SERVICE_GROUP_OVERRIDE`: Custom service account group
  - Example: `export SERVICE_USER_OVERRIDE="custom-mcp" SERVICE_GROUP_OVERRIDE="mcp-services"`

- **Fallback Resolution Order**:
  1. Use `SERVICE_USER_OVERRIDE` and `SERVICE_GROUP_OVERRIDE` if both are set
  2. Attempt domain account check (`docling-mcp@hx.dev.local` / `domain users@hx.dev.local`)
  3. Attempt local account check (`docling-mcp` / `docling-mcp`)
  4. Emit error with instructions to set override variables

```bash
# Set ownership to service account with override support
VENV_PATH="/opt/docling-mcp/venv"

echo "Configuring virtual environment ownership..."

# Resolution Order 1: Check for operator overrides (highest priority)
if [ -n "$SERVICE_USER_OVERRIDE" ] && [ -n "$SERVICE_GROUP_OVERRIDE" ]; then
    SERVICE_USER="$SERVICE_USER_OVERRIDE"
    SERVICE_GROUP="$SERVICE_GROUP_OVERRIDE"
    echo "✅ Using operator-provided overrides:"
    echo "   SERVICE_USER=$SERVICE_USER"
    echo "   SERVICE_GROUP=$SERVICE_GROUP"
    
    # Validate override account exists
    if ! getent passwd "$SERVICE_USER" > /dev/null 2>&1; then
        echo "⚠️  WARNING: Override user '$SERVICE_USER' not found in system database"
        echo "   Proceeding anyway (may fail during chown)"
    fi

# Resolution Order 2: Domain account (if SSSD configured)
elif getent passwd docling-mcp@hx.dev.local > /dev/null 2>&1; then
    SERVICE_USER="docling-mcp@hx.dev.local"
    SERVICE_GROUP="domain users@hx.dev.local"
    echo "✅ Using Samba AD domain account: $SERVICE_USER"

# Resolution Order 3: Local system account
elif getent passwd docling-mcp > /dev/null 2>&1; then
    SERVICE_USER="docling-mcp"
    SERVICE_GROUP="docling-mcp"
    echo "✅ Using local system account: $SERVICE_USER"

# Resolution Order 4: No account found - emit clear error with instructions
else
    echo "❌ ERROR: Service account not found"
    echo ""
    echo "No service account detected in system database (neither domain nor local)."
    echo ""
    echo "RESOLUTION OPTIONS:"
    echo ""
    echo "1. Set environment variable overrides for custom account:"
    echo "   export SERVICE_USER_OVERRIDE=\"your-custom-user\""
    echo "   export SERVICE_GROUP_OVERRIDE=\"your-custom-group\""
    echo "   Then re-run this script"
    echo ""
    echo "2. Complete prerequisite tasks:"
    echo "   - Task 001: Create Samba AD service account (docling-mcp@hx.dev.local)"
    echo "   - Task 004: Configure system ownership"
    echo ""
    echo "3. Create local system account:"
    echo "   sudo useradd -r -s /bin/bash -d /opt/docling-mcp docling-mcp"
    echo ""
    exit 1
fi

# Set ownership recursively
echo "Setting ownership: $SERVICE_USER:$SERVICE_GROUP"
sudo chown -R "$SERVICE_USER":"$SERVICE_GROUP" "$VENV_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Virtual environment ownership set to $SERVICE_USER:$SERVICE_GROUP"
    ls -ld "$VENV_PATH"
else
    echo "❌ Failed to set virtual environment ownership"
    echo "   User: $SERVICE_USER"
    echo "   Group: $SERVICE_GROUP"
    exit 1
fi
```

### Step 5: Document Virtual Environment Configuration

**Dynamic Hostname Configuration**:

The hostname is automatically detected at runtime for accurate inventory documentation:

- **Runtime Detection**: Uses `$(hostname -f)` to get fully-qualified domain name
- **Override Support**: Set `NODE_HOSTNAME` environment variable to override
  - Example: `export NODE_HOSTNAME="custom-node.example.com"`
- **Fallback**: Falls back to short hostname if FQDN unavailable

```bash
# Document venv configuration for troubleshooting
VENV_PATH="/opt/docling-mcp/venv"
DOC_PATH="/opt/docling-mcp/deployment-docs"

mkdir -p "$DOC_PATH"

# Detect current node hostname (with override support)
if [ -n "$NODE_HOSTNAME" ]; then
    CURRENT_NODE="$NODE_HOSTNAME"
    echo "Using override hostname: $CURRENT_NODE"
elif command -v hostname >/dev/null 2>&1; then
    # Try FQDN first, fallback to short hostname
    CURRENT_NODE=$(hostname -f 2>/dev/null || hostname)
    echo "Detected hostname: $CURRENT_NODE"
else
    CURRENT_NODE="unknown-node"
    echo "⚠️  WARNING: Cannot detect hostname, using: $CURRENT_NODE"
fi

cat > "$DOC_PATH/python-venv-inventory.txt" <<EOF
# Python Virtual Environment Inventory
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: $CURRENT_NODE
# Task: hx-docling-mcp-task-021

## Virtual Environment Location
Path: $VENV_PATH

## Python Version
$(${VENV_PATH}/bin/python --version)

## Core Package Versions
pip: $(${VENV_PATH}/bin/pip --version)
setuptools: $(${VENV_PATH}/bin/python -c "import setuptools; print(setuptools.__version__)")
wheel: $(${VENV_PATH}/bin/python -c "import wheel; print(wheel.__version__)")

## Ownership
$(ls -ld $VENV_PATH)

## Activation Command
source $VENV_PATH/bin/activate

## Installed Packages (Initial State)
$(${VENV_PATH}/bin/pip list)
EOF

echo "✅ Virtual environment inventory documented: $DOC_PATH/python-venv-inventory.txt"
cat "$DOC_PATH/python-venv-inventory.txt"
```

## Validation

**Validation Commands:**

```bash
echo "=== Python Virtual Environment Validation ==="

VENV_PATH="/opt/docling-mcp/venv"

# Validate venv existence and structure
echo "1. Virtual Environment Structure:"
if [ -d "$VENV_PATH" ]; then
    echo "✅ PASSED: Virtual environment directory exists"
else
    echo "❌ FAILED: Virtual environment directory missing"
    exit 1
fi

if [ -f "$VENV_PATH/bin/activate" ]; then
    echo "✅ PASSED: Activation script exists"
else
    echo "❌ FAILED: Activation script missing"
    exit 1
fi

if [ -f "$VENV_PATH/bin/python" ]; then
    echo "✅ PASSED: Python interpreter exists"
else
    echo "❌ FAILED: Python interpreter missing"
    exit 1
fi

# Validate Python version
echo ""
echo "2. Python Version:"
VENV_PYTHON_VERSION=$($VENV_PATH/bin/python --version 2>&1)
echo "Virtual environment Python: $VENV_PYTHON_VERSION"

if echo "$VENV_PYTHON_VERSION" | grep -q "Python 3.11"; then
    echo "✅ PASSED: Python 3.11 configured"
else
    echo "❌ FAILED: Python version mismatch"
    exit 1
fi

# Validate pip availability and version
echo ""
echo "3. pip Configuration:"
if [ -f "$VENV_PATH/bin/pip" ]; then
    PIP_VERSION=$($VENV_PATH/bin/pip --version 2>&1)
    echo "pip version: $PIP_VERSION"

    # Extract pip version number (POSIX-compliant, no bc dependency)
    # Parse version into major.minor format, convert to integer for comparison
    PIP_VERSION_NUM=$($VENV_PATH/bin/pip --version | sed -n 's/.*pip \([0-9]*\.[0-9]*\).*/\1/p' | head -n1)
    
    if [ -n "$PIP_VERSION_NUM" ]; then
        # Split version into major and minor using IFS (POSIX shell)
        IFS='.' read -r PIP_MAJOR PIP_MINOR <<EOF
$PIP_VERSION_NUM
EOF
        
        # Normalize to integer: major*100 + minor (e.g., 24.0 → 2400)
        PIP_VERSION_INT=$((PIP_MAJOR * 100 + PIP_MINOR))
        PIP_THRESHOLD=2400  # 24.0 → 2400
        
        if [ "$PIP_VERSION_INT" -ge "$PIP_THRESHOLD" ]; then
            echo "✅ PASSED: pip version >= 24.0 (detected: $PIP_VERSION_NUM)"
        else
            echo "⚠️  WARNING: pip version < 24.0 (detected: $PIP_VERSION_NUM), upgrade recommended"
        fi
    else
        echo "⚠️  WARNING: Could not parse pip version, skipping version check"
    fi
else
    echo "❌ FAILED: pip not found"
    exit 1
fi

# Validate setuptools and wheel
echo ""
echo "4. Build Tools:"
SETUPTOOLS_VERSION=$($VENV_PATH/bin/python -c "import setuptools; print(setuptools.__version__)" 2>&1)
WHEEL_VERSION=$($VENV_PATH/bin/python -c "import wheel; print(wheel.__version__)" 2>&1)

echo "setuptools version: $SETUPTOOLS_VERSION"
echo "wheel version: $WHEEL_VERSION"

if [ $? -eq 0 ]; then
    echo "✅ PASSED: setuptools and wheel installed"
else
    echo "❌ FAILED: setuptools or wheel missing"
    exit 1
fi

# Validate ownership
echo ""
echo "5. Ownership and Permissions:"
VENV_OWNER=$(stat -c '%U:%G' "$VENV_PATH")
echo "Virtual environment owner: $VENV_OWNER"

if echo "$VENV_OWNER" | grep -qE '(docling-mcp|domain users)'; then
    echo "✅ PASSED: Ownership set to service account"
else
    echo "⚠️  WARNING: Ownership may not match service account"
fi

# Test activation
echo ""
echo "6. Activation Test:"
source "$VENV_PATH/bin/activate"
if [ "$VIRTUAL_ENV" = "$VENV_PATH" ]; then
    echo "✅ PASSED: Virtual environment activation successful"
    echo "Active Python: $(which python)"
    deactivate
else
    echo "❌ FAILED: Virtual environment activation failed"
    exit 1
fi

# Summary
echo ""
echo "=== Validation Summary ==="
echo "✅ ALL VALIDATIONS PASSED - Python virtual environment ready for package installation"
```

**Expected Results:**
- Virtual environment directory exists at `/opt/docling-mcp/venv/`
- Python version: `Python 3.11.x`
- pip version: `pip 24.x or higher`
- setuptools version: `69.x or higher`
- wheel version: `0.43.x or higher`
- Ownership: `docling-mcp:docling-mcp` or `docling-mcp@hx.dev.local:domain users@hx.dev.local`
- Activation test: `VIRTUAL_ENV` variable set correctly

## Notes

**Virtual Environment Benefits:**
- **Isolation**: Packages installed in venv do NOT affect system Python
- **Portability**: Can recreate environment from requirements.txt
- **Security**: Non-root user can install packages within venv
- **Consistency**: Same Python version and packages across development/staging/production

**Activation:**
```bash
# Activate virtual environment (changes PATH and PYTHONPATH)
source /opt/docling-mcp/venv/bin/activate

# Verify activation (prompt changes to show (venv))
which python  # Should show /opt/docling-mcp/venv/bin/python

# Deactivate when done
deactivate
```

**Systemd Integration:**
- Systemd service unit does NOT need to activate venv
- Use full path to venv Python: `/opt/docling-mcp/venv/bin/python`
- Environment variable in systemd unit: `Environment="PATH=/opt/docling-mcp/venv/bin:..."`

**Troubleshooting:**
- If venv creation fails: Check `/opt/docling-mcp/` ownership and permissions (Task 004)
- If pip upgrade fails: Check internet connectivity to PyPI (pypi.org)
- If ownership fails: Verify service account exists (Task 001, Task 004)

## References

**Specification**: `${HX_INFRASTRUCTURE_ROOT}/nodes/hx-docling-mcp-server/specification/node-spec.md`

- Section: Deployment Architecture - Phase 3: Service Installation (lines 5010-5020)
- Section: Python Virtual Environment requirements

**Environment Variables**:

- `HX_INFRASTRUCTURE_ROOT`: Root directory of HX-Infrastructure repository
  - **Development**: Typically `~/HX-Infrastructure` or your git clone location
  - **CI/CD**: Set by pipeline (e.g., `$GITHUB_WORKSPACE`, `$CI_PROJECT_DIR`)
  - **Production**: Set in deployment scripts (e.g., `/opt/hx-infrastructure`)
  - **Resolution**: `export HX_INFRASTRUCTURE_ROOT=$(git rev-parse --show-toplevel)` (auto-detect git root)

**Python Documentation**:

- Python venv: <https://docs.python.org/3.11/library/venv.html>
- pip documentation: <https://pip.pypa.io/en/stable/>

## Risk Assessment

**Risk Level**: Low

**Risks**:

1. **Internet connectivity failure**: pip upgrade requires PyPI access
2. **Disk space insufficient**: venv requires ~100MB for base packages
3. **Permission denied**: Ownership issues if Task 004 not complete

**Mitigation**:

- Pre-validate internet connectivity with `curl https://pypi.org` before pip upgrade
- Pre-check disk space (Task 003 validated 50GB+ available)
- Validate service account exists and directory ownership correct before venv creation
- Document venv configuration for disaster recovery
