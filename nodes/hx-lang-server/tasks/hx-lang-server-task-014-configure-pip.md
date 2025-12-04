# Task 014: Configure pip Package Manager

**Task ID**: hx-lang-server-task-014
**Phase**: Pre-Deployment (System Dependencies)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 013 (Virtual Environment)
**Estimated Effort**: 20 minutes

---

## Objective

Configure pip package manager with appropriate settings for reliable package installation, including index URLs, timeouts, and cache configuration for the hx-lang-server virtual environment.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 013 (Virtual Environment) completed
- [ ] Virtual environment at /opt/hx-lang-server/venv exists

---

## Pre-Execution Validation

**CRITICAL**: Check current pip configuration before modifying.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check pip configuration
VENV_PATH="/opt/hx-lang-server/venv"

echo "Checking pip configuration status..."

# Check if pip.conf exists
PIP_CONF_SYSTEM="/etc/pip.conf"
PIP_CONF_USER="$HOME/.pip/pip.conf"
PIP_CONF_VENV="$VENV_PATH/pip.conf"

if [ -f "$PIP_CONF_VENV" ]; then
    echo "pip configuration exists in venv: $PIP_CONF_VENV"
    cat "$PIP_CONF_VENV"
    echo ""
    echo "VALIDATION RESULT: pip configuration already exists"
    echo "ACTION: Review and update if needed"
elif [ -f "$PIP_CONF_SYSTEM" ]; then
    echo "System pip configuration exists: $PIP_CONF_SYSTEM"
    cat "$PIP_CONF_SYSTEM"
    echo ""
    echo "VALIDATION RESULT: Using system pip configuration"
    echo "ACTION: Create venv-specific configuration if needed"
else
    echo "VALIDATION RESULT: No pip configuration found"
    echo "ACTION: PROCEED with implementation steps"
fi

# Show current pip configuration
echo ""
echo "Current pip configuration:"
"$VENV_PATH/bin/pip" config list 2>/dev/null || echo "No configuration set"
```

**If Already Configured**: Review existing configuration, skip if satisfactory
**If Not Configured**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Verify Virtual Environment pip

```bash
# Verify pip in virtual environment
VENV_PATH="/opt/hx-lang-server/venv"

echo "Verifying pip installation..."

if [ -x "$VENV_PATH/bin/pip" ]; then
    "$VENV_PATH/bin/pip" --version
    echo "pip available in virtual environment"
else
    echo "ERROR: pip not found in virtual environment"
    exit 1
fi
```

### Step 2: Upgrade pip to Latest Version

```bash
# Upgrade pip to latest version
VENV_PATH="/opt/hx-lang-server/venv"

echo "Upgrading pip to latest version..."

# Determine service account
if getent passwd "hx-lang-server@hx.dev.local" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server@hx.dev.local"
elif getent passwd "hx-lang-server" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server"
else
    SERVICE_USER="root"
fi

# Upgrade pip
sudo -u "$SERVICE_USER" "$VENV_PATH/bin/pip" install --upgrade pip 2>/dev/null || \
    sudo "$VENV_PATH/bin/pip" install --upgrade pip

# Verify upgrade
"$VENV_PATH/bin/pip" --version

if [ $? -eq 0 ]; then
    echo "pip upgraded successfully"
else
    echo "WARNING: pip upgrade may have failed"
fi
```

### Step 3: Create pip Configuration File

```bash
# Create pip configuration for virtual environment
VENV_PATH="/opt/hx-lang-server/venv"
PIP_CONF="$VENV_PATH/pip.conf"

echo "Creating pip configuration..."

sudo tee "$PIP_CONF" > /dev/null <<'EOF'
[global]
# Default index URL (PyPI)
index-url = https://pypi.org/simple

# Additional index URLs (if needed for internal packages)
# extra-index-url = https://internal-pypi.example.com/simple

# Connection timeout (seconds)
timeout = 60

# Retry count for failed downloads
retries = 3

# Trust PyPI hosts (HTTPS only, no HTTP)
trusted-host = pypi.org
               pypi.python.org
               files.pythonhosted.org

# Cache configuration
cache-dir = /var/cache/pip

# Disable cache if disk space is limited (uncomment if needed)
# no-cache-dir = true

[install]
# Compile Python files to bytecode during install
compile = true

# Do not warn about script directory not in PATH
no-warn-script-location = false

# Prefer binary wheels over source distributions
prefer-binary = true

# Upgrade strategy (only-if-needed prevents unnecessary upgrades)
upgrade-strategy = only-if-needed
EOF

# Set ownership
sudo chown "$SERVICE_USER" "$PIP_CONF" 2>/dev/null || true
sudo chmod 644 "$PIP_CONF"

echo "pip configuration created: $PIP_CONF"
cat "$PIP_CONF"
```

### Step 4: Create pip Cache Directory

```bash
# Create and configure pip cache directory
CACHE_DIR="/var/cache/pip"

echo "Creating pip cache directory..."

# Create cache directory
sudo mkdir -p "$CACHE_DIR"

# Set ownership to service account
sudo chown "$SERVICE_USER:$SERVICE_USER" "$CACHE_DIR" 2>/dev/null || \
    sudo chown "$SERVICE_USER" "$CACHE_DIR" 2>/dev/null || true

# Set permissions (owner rwx, group rx, others rx)
sudo chmod 755 "$CACHE_DIR"

# Verify cache directory
ls -la "$CACHE_DIR"
echo "pip cache directory created: $CACHE_DIR"
```

### Step 5: Verify pip Configuration

```bash
# Verify pip configuration
VENV_PATH="/opt/hx-lang-server/venv"

echo "Verifying pip configuration..."

# List current configuration
echo "Current pip configuration:"
"$VENV_PATH/bin/pip" config list

# Test package resolution (dry-run)
echo ""
echo "Testing package resolution..."
"$VENV_PATH/bin/pip" install --dry-run httpx 2>&1 | head -n5

if [ $? -eq 0 ]; then
    echo "pip configuration working correctly"
else
    echo "WARNING: pip configuration test failed"
fi
```

### Step 6: Document pip Configuration

```bash
# Document pip configuration
DOC_DIR="/opt/hx-lang-server/deployment-docs"
VENV_PATH="/opt/hx-lang-server/venv"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/pip-configuration.txt" > /dev/null <<EOF
# pip Configuration
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-014

## pip Version
$("$VENV_PATH/bin/pip" --version)

## Configuration File
Location: $VENV_PATH/pip.conf

## Cache Directory
Location: /var/cache/pip
Owner: $SERVICE_USER

## Index URL
Primary: https://pypi.org/simple

## Settings
- Timeout: 60 seconds
- Retries: 3
- Prefer binary wheels: yes
- Upgrade strategy: only-if-needed

## Usage Commands
# Install package
$VENV_PATH/bin/pip install <package>

# Install with specific version
$VENV_PATH/bin/pip install <package>==<version>

# Install from requirements file
$VENV_PATH/bin/pip install -r requirements.txt

# List installed packages
$VENV_PATH/bin/pip list

# Show package info
$VENV_PATH/bin/pip show <package>

# Freeze installed packages
$VENV_PATH/bin/pip freeze > requirements.txt

# Check for outdated packages
$VENV_PATH/bin/pip list --outdated

## Current Configuration
$("$VENV_PATH/bin/pip" config list)
EOF

echo "pip configuration documented: $DOC_DIR/pip-configuration.txt"
cat "$DOC_DIR/pip-configuration.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| pip Configuration | /opt/hx-lang-server/venv/pip.conf | pip settings file |
| Cache Directory | /var/cache/pip | Package cache directory |
| Documentation | /opt/hx-lang-server/deployment-docs/pip-configuration.txt | Configuration documentation |

---

## Verification

**Validation Commands:**

```bash
echo "=== pip Configuration Validation ==="

VENV_PATH="/opt/hx-lang-server/venv"
VALIDATION_PASSED=true

# Check 1: pip version
echo "1. pip Version:"
"$VENV_PATH/bin/pip" --version
echo "PASSED: pip installed and accessible"

# Check 2: pip configuration file
echo ""
echo "2. Configuration File:"
if [ -f "$VENV_PATH/pip.conf" ]; then
    echo "PASSED: pip.conf exists at $VENV_PATH/pip.conf"
else
    echo "WARNING: pip.conf not found (using defaults)"
fi

# Check 3: Cache directory
echo ""
echo "3. Cache Directory:"
if [ -d "/var/cache/pip" ]; then
    ls -la /var/cache/pip
    echo "PASSED: Cache directory exists"
else
    echo "WARNING: Cache directory does not exist"
fi

# Check 4: Index URL reachable
echo ""
echo "4. Index URL Connectivity:"
if curl -s --head https://pypi.org/simple/ | head -n1 | grep -q "200"; then
    echo "PASSED: PyPI index reachable"
else
    echo "WARNING: Cannot reach PyPI index (may need proxy)"
fi

# Check 5: Package resolution test
echo ""
echo "5. Package Resolution Test:"
"$VENV_PATH/bin/pip" install --dry-run httpx > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "PASSED: Package resolution working"
else
    echo "FAILED: Package resolution failed"
    VALIDATION_PASSED=false
fi

# Check 6: Configuration list
echo ""
echo "6. Active Configuration:"
"$VENV_PATH/bin/pip" config list

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - pip configured for hx-lang-server"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- pip shows latest version
- pip.conf file exists in virtual environment
- Cache directory exists with correct permissions
- PyPI index is reachable
- Package resolution test passes
- Configuration list shows settings

---

## Rollback Procedure

Remove pip configuration if needed:

```bash
# Remove pip configuration
VENV_PATH="/opt/hx-lang-server/venv"

echo "Removing pip configuration..."

# Remove configuration file
sudo rm -f "$VENV_PATH/pip.conf"

# Optionally remove cache directory
# sudo rm -rf /var/cache/pip

echo "pip configuration removed (using defaults)"

# Verify removal
"$VENV_PATH/bin/pip" config list
```

---

## Notes

**Configuration Location:**
- pip.conf in venv directory takes precedence over system config
- Virtual environment isolation maintained
- No impact on system Python or other virtual environments

**Index URL:**
- Using official PyPI (https://pypi.org/simple)
- HTTPS only (no HTTP allowed)
- Can add internal PyPI mirrors via extra-index-url if needed

**Caching:**
- Cache directory at /var/cache/pip
- Speeds up repeated installations
- Reduces network bandwidth usage
- Can be disabled if disk space is limited

**Security Considerations:**
- HTTPS-only index URLs
- Trusted hosts explicitly listed
- No HTTP fallback allowed
- Package integrity verified by pip

**Performance Settings:**
- prefer-binary reduces compilation time
- 60-second timeout for slow connections
- 3 retries for transient failures
- only-if-needed upgrade strategy prevents unnecessary work

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Dependencies - Python Dependencies (lines 600-626)

**pip Documentation:**
- Configuration: https://pip.pypa.io/en/stable/topics/configuration/
- pip.conf: https://pip.pypa.io/en/stable/user_guide/#config-file

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 2: System Dependencies (Task Range 011-020)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **PyPI unavailable**: Network issues prevent package download
   - Mitigation: Timeout and retry settings; cache for previously downloaded packages
2. **Invalid configuration**: Syntax error in pip.conf
   - Mitigation: pip validates configuration; rollback to defaults if needed
3. **Cache disk space**: Large cache consumes disk
   - Mitigation: /var/cache separate from application; can disable cache

**Dependencies Blocked:**
- Task 015 onwards depend on working pip configuration
- All Python package installations use this configuration
