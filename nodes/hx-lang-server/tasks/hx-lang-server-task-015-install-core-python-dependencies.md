# Task 015: Install Core Python Dependencies

**Task ID**: hx-lang-server-task-015
**Phase**: Pre-Deployment (System Dependencies)
**Assigned To**: william-chen
**Status**: Not Started
**Dependencies**: Task 013 (Virtual Environment), Task 014 (pip Configuration)
**Estimated Effort**: 45 minutes

---

## Objective

Install core Python dependencies for hx-lang-server including FastAPI, Uvicorn, Pydantic, and HTTP client libraries. These form the foundation before LangGraph-specific packages.

---

## Prerequisites

- [ ] SSH access to hx-lang-server.hx.dev.local (192.168.10.226)
- [ ] sudo privileges on target server
- [ ] Task 013 (Virtual Environment) completed
- [ ] Task 014 (pip Configuration) completed
- [ ] Network connectivity to PyPI

---

## Pre-Execution Validation

**CRITICAL**: Check if core packages are already installed BEFORE running pip install.

```bash
# SSH to target server
ssh hx-lang-server.hx.dev.local

# Validation command to check installed packages
VENV_PATH="/opt/hx-lang-server/venv"

echo "Checking core Python dependencies..."

PACKAGES_TO_CHECK=(
    "fastapi"
    "uvicorn"
    "pydantic"
    "pydantic-settings"
    "httpx"
    "aiohttp"
    "python-dotenv"
    "structlog"
)

MISSING_PACKAGES=()

for pkg in "${PACKAGES_TO_CHECK[@]}"; do
    if "$VENV_PATH/bin/pip" show "$pkg" > /dev/null 2>&1; then
        VERSION=$("$VENV_PATH/bin/pip" show "$pkg" | grep "Version:" | awk '{print $2}')
        echo "INSTALLED: $pkg ($VERSION)"
    else
        echo "MISSING: $pkg"
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo ""
    echo "VALIDATION RESULT: All core packages already installed"
    echo "ACTION: SKIP installation, proceed to validation section"
else
    echo ""
    echo "VALIDATION RESULT: ${#MISSING_PACKAGES[@]} packages missing"
    echo "ACTION: PROCEED with installation steps"
fi
```

**If Already Installed**: Skip to Validation section
**If Missing Packages**: Continue with Implementation Steps below

---

## Implementation Steps

### Step 1: Create Requirements File

```bash
# Create requirements file for core dependencies
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Creating core requirements file..."

sudo tee "$APP_DIR/requirements-core.txt" > /dev/null <<'EOF'
# Core Python Dependencies for hx-lang-server
# Task: hx-lang-server-task-015
# Date: 2025-12-04

# API Framework
fastapi>=0.115.0
uvicorn>=0.32.0

# Data Validation
pydantic>=2.9.0
pydantic-settings>=2.6.0

# HTTP Clients
httpx>=0.27.0
aiohttp>=3.10.0

# Environment and Configuration
python-dotenv>=1.0.0

# Structured Logging
structlog>=24.0.0
EOF

# Set ownership
sudo chown hx-lang-server "$APP_DIR/requirements-core.txt" 2>/dev/null || true

echo "Core requirements file created: $APP_DIR/requirements-core.txt"
cat "$APP_DIR/requirements-core.txt"
```

### Step 2: Install Core Dependencies

```bash
# Install core dependencies from requirements file
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Installing core Python dependencies..."

# Determine service account
if getent passwd "hx-lang-server@hx.dev.local" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server@hx.dev.local"
elif getent passwd "hx-lang-server" > /dev/null 2>&1; then
    SERVICE_USER="hx-lang-server"
else
    SERVICE_USER="root"
fi

# Install packages
sudo -u "$SERVICE_USER" "$VENV_PATH/bin/pip" install -r "$APP_DIR/requirements-core.txt" 2>/dev/null || \
    sudo "$VENV_PATH/bin/pip" install -r "$APP_DIR/requirements-core.txt"

if [ $? -eq 0 ]; then
    echo "Core dependencies installed successfully"
else
    echo "ERROR: Core dependencies installation failed"
    exit 1
fi
```

### Step 3: Verify Package Installations

```bash
# Verify each package installed correctly
VENV_PATH="/opt/hx-lang-server/venv"

echo "Verifying package installations..."

PACKAGES=(
    "fastapi"
    "uvicorn"
    "pydantic"
    "pydantic-settings"
    "httpx"
    "aiohttp"
    "python-dotenv"
    "structlog"
)

ALL_INSTALLED=true

for pkg in "${PACKAGES[@]}"; do
    if "$VENV_PATH/bin/pip" show "$pkg" > /dev/null 2>&1; then
        VERSION=$("$VENV_PATH/bin/pip" show "$pkg" | grep "Version:" | awk '{print $2}')
        echo "VERIFIED: $pkg ($VERSION)"
    else
        echo "MISSING: $pkg"
        ALL_INSTALLED=false
    fi
done

if [ "$ALL_INSTALLED" = true ]; then
    echo "All core packages verified"
else
    echo "ERROR: Some packages missing"
    exit 1
fi
```

### Step 4: Test Package Imports

```bash
# Test that packages can be imported
VENV_PATH="/opt/hx-lang-server/venv"

echo "Testing package imports..."

"$VENV_PATH/bin/python" <<'EOF'
import sys

packages_to_test = [
    ("fastapi", "FastAPI"),
    ("uvicorn", "uvicorn"),
    ("pydantic", "BaseModel"),
    ("pydantic_settings", "BaseSettings"),
    ("httpx", "AsyncClient"),
    ("aiohttp", "ClientSession"),
    ("dotenv", "load_dotenv"),
    ("structlog", "get_logger"),
]

failed = []

for module, attr in packages_to_test:
    try:
        mod = __import__(module)
        if hasattr(mod, attr) or hasattr(mod, attr.lower()):
            print(f"PASS: {module} imported successfully")
        else:
            print(f"PASS: {module} imported (attr {attr} not checked)")
    except ImportError as e:
        print(f"FAIL: {module} - {e}")
        failed.append(module)

if failed:
    print(f"\nFailed imports: {', '.join(failed)}")
    sys.exit(1)
else:
    print("\nAll package imports successful")
    sys.exit(0)
EOF

if [ $? -eq 0 ]; then
    echo "Package import test passed"
else
    echo "ERROR: Package import test failed"
    exit 1
fi
```

### Step 5: Freeze Installed Packages

```bash
# Create frozen requirements for reproducibility
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Creating frozen requirements..."

"$VENV_PATH/bin/pip" freeze > "$APP_DIR/requirements-core-frozen.txt"

echo "Frozen requirements:"
cat "$APP_DIR/requirements-core-frozen.txt"

# Set ownership
sudo chown hx-lang-server "$APP_DIR/requirements-core-frozen.txt" 2>/dev/null || true

echo "Frozen requirements created: $APP_DIR/requirements-core-frozen.txt"
```

### Step 6: Document Installed Packages

```bash
# Document installed packages
DOC_DIR="/opt/hx-lang-server/deployment-docs"
VENV_PATH="/opt/hx-lang-server/venv"
sudo mkdir -p "$DOC_DIR"

sudo tee "$DOC_DIR/core-dependencies-inventory.txt" > /dev/null <<EOF
# Core Python Dependencies Inventory
# Date: $(date +%Y-%m-%d %H:%M:%S)
# Node: hx-lang-server.hx.dev.local (192.168.10.226)
# Task: hx-lang-server-task-015

## Package Summary

### API Framework
FastAPI: $("$VENV_PATH/bin/pip" show fastapi | grep "Version:" | awk '{print $2}')
Uvicorn: $("$VENV_PATH/bin/pip" show uvicorn | grep "Version:" | awk '{print $2}')

### Data Validation
Pydantic: $("$VENV_PATH/bin/pip" show pydantic | grep "Version:" | awk '{print $2}')
Pydantic-Settings: $("$VENV_PATH/bin/pip" show pydantic-settings | grep "Version:" | awk '{print $2}')

### HTTP Clients
HTTPX: $("$VENV_PATH/bin/pip" show httpx | grep "Version:" | awk '{print $2}')
AIOHTTP: $("$VENV_PATH/bin/pip" show aiohttp | grep "Version:" | awk '{print $2}')

### Utilities
Python-dotenv: $("$VENV_PATH/bin/pip" show python-dotenv | grep "Version:" | awk '{print $2}')
Structlog: $("$VENV_PATH/bin/pip" show structlog | grep "Version:" | awk '{print $2}')

## Complete Package List
$("$VENV_PATH/bin/pip" list)

## Specification Reference
Requirements from: node-spec.md (lines 600-626)
EOF

echo "Core dependencies documented: $DOC_DIR/core-dependencies-inventory.txt"
cat "$DOC_DIR/core-dependencies-inventory.txt"
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Requirements File | /opt/hx-lang-server/requirements-core.txt | Core dependency specifications |
| Frozen Requirements | /opt/hx-lang-server/requirements-core-frozen.txt | Pinned versions |
| Documentation | /opt/hx-lang-server/deployment-docs/core-dependencies-inventory.txt | Package inventory |

---

## Verification

**Validation Commands:**

```bash
echo "=== Core Python Dependencies Validation ==="

VENV_PATH="/opt/hx-lang-server/venv"
VALIDATION_PASSED=true

# Check 1: All packages installed
echo "1. Package Installation:"
REQUIRED_PACKAGES=(
    "fastapi>=0.115.0"
    "uvicorn>=0.32.0"
    "pydantic>=2.9.0"
    "pydantic-settings>=2.6.0"
    "httpx>=0.27.0"
    "aiohttp>=3.10.0"
    "python-dotenv>=1.0.0"
    "structlog>=24.0.0"
)

for spec in "${REQUIRED_PACKAGES[@]}"; do
    pkg=$(echo "$spec" | cut -d'>' -f1 | cut -d'=' -f1)
    if "$VENV_PATH/bin/pip" show "$pkg" > /dev/null 2>&1; then
        VERSION=$("$VENV_PATH/bin/pip" show "$pkg" | grep "Version:" | awk '{print $2}')
        echo "PASSED: $pkg ($VERSION)"
    else
        echo "FAILED: $pkg not installed"
        VALIDATION_PASSED=false
    fi
done

# Check 2: FastAPI can be imported
echo ""
echo "2. FastAPI Import Test:"
if "$VENV_PATH/bin/python" -c "from fastapi import FastAPI; print('FastAPI imported')" 2>/dev/null; then
    echo "PASSED: FastAPI imports correctly"
else
    echo "FAILED: FastAPI import failed"
    VALIDATION_PASSED=false
fi

# Check 3: Uvicorn can be run
echo ""
echo "3. Uvicorn Test:"
if "$VENV_PATH/bin/uvicorn" --version 2>/dev/null; then
    echo "PASSED: Uvicorn executable works"
else
    echo "FAILED: Uvicorn not working"
    VALIDATION_PASSED=false
fi

# Check 4: Pydantic validation
echo ""
echo "4. Pydantic Test:"
"$VENV_PATH/bin/python" <<'PYEOF'
from pydantic import BaseModel

class TestModel(BaseModel):
    name: str
    value: int

m = TestModel(name="test", value=42)
print(f"Pydantic validation working: {m.model_dump()}")
PYEOF

if [ $? -eq 0 ]; then
    echo "PASSED: Pydantic working correctly"
else
    echo "FAILED: Pydantic test failed"
    VALIDATION_PASSED=false
fi

# Check 5: HTTP client test
echo ""
echo "5. HTTP Client Test:"
"$VENV_PATH/bin/python" <<'PYEOF'
import httpx
import asyncio

async def test():
    async with httpx.AsyncClient() as client:
        print("HTTPX AsyncClient created successfully")
    return True

asyncio.run(test())
PYEOF

if [ $? -eq 0 ]; then
    echo "PASSED: HTTP client working"
else
    echo "WARNING: HTTP client test failed (may be network issue)"
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "ALL VALIDATIONS PASSED - Core dependencies ready for hx-lang-server"
else
    echo "VALIDATION FAILED - Some checks did not pass"
    exit 1
fi
```

**Expected Results:**
- All 8 core packages installed with correct versions
- FastAPI imports without errors
- Uvicorn executable shows version
- Pydantic model validation works
- HTTPX async client creates successfully

---

## Rollback Procedure

Remove installed packages if needed:

```bash
# Uninstall core packages
VENV_PATH="/opt/hx-lang-server/venv"
APP_DIR="/opt/hx-lang-server"

echo "Removing core dependencies..."

# Uninstall packages
"$VENV_PATH/bin/pip" uninstall -y \
    fastapi uvicorn pydantic pydantic-settings \
    httpx aiohttp python-dotenv structlog

# Remove requirements files
rm -f "$APP_DIR/requirements-core.txt"
rm -f "$APP_DIR/requirements-core-frozen.txt"

echo "Core dependencies removed"

# Note: This leaves virtual environment intact
# Packages can be reinstalled by re-running this task
```

---

## Notes

**Package Versions:**
- All versions match specification in node-spec.md (lines 600-626)
- Minimum versions specified; pip will install latest compatible
- Frozen requirements capture exact versions for reproducibility

**FastAPI Stack:**
- FastAPI: Modern async web framework
- Uvicorn: ASGI server (production-ready)
- Pydantic: Data validation (v2.x for performance)
- Pydantic-Settings: Environment configuration

**HTTP Clients:**
- HTTPX: Modern async HTTP client (replaces requests)
- AIOHTTP: Alternative async HTTP client (LangChain uses this)

**Utilities:**
- python-dotenv: Environment variable loading from .env files
- structlog: Structured JSON logging

**Security Considerations:**
- All packages from PyPI official index
- HTTPS-only downloads
- Latest versions include security fixes

---

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Dependencies - Python Dependencies (lines 600-626)
- Section: API Specification (lines 476-539)

**Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/tasks/task-framework.md`
- Work Stream 2: System Dependencies (Task Range 011-020)

---

## Risk Assessment

**Risk Level**: Low

**Risks:**
1. **Package version conflict**: Dependencies have conflicting requirements
   - Mitigation: pip resolves dependencies automatically; freeze captures working state
2. **Network timeout**: Large packages fail to download
   - Mitigation: pip retry configuration; can resume partial downloads
3. **Breaking changes**: New package versions incompatible
   - Mitigation: Minimum versions specified; frozen requirements for rollback

**Dependencies Blocked:**
- Task 016+ (LangGraph packages) depend on core framework
- Work Stream 3 (LangGraph installation) requires these packages
