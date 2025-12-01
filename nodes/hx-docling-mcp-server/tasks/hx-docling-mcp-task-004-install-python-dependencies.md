# Task 004: Install Python Dependencies

**Task ID**: hx-docling-mcp-task-004
**Category**: Installation / Python Packages
**Assigned To**: william-chen (Infrastructure Specialist)
**Status**: PENDING
**Priority**: HIGH (Blocker for deployment)
**Created**: 2025-11-27
**Estimated Effort**: 45 minutes

---

## Task Description

Install all required Python dependencies for Docling MCP Server into the isolated Python 3.12 virtual environment. This includes FastMCP framework, docling library, LightRAG, Qdrant client, Redis client, LiteLLM, and all supporting packages with pinned versions for reproducibility.

---

## Prerequisites

- [ ] Task 002 complete (Samba AD service account created)
- [ ] Task 003 complete (Python 3.12 virtual environment created at `/opt/docling-mcp/venv`)
- [ ] System dependencies installed (tesseract-ocr, poppler-utils, libmagic1)
- [ ] Virtual environment validation script passed
- [ ] Internet connectivity available for package downloads

---

## Acceptance Criteria

- [ ] All Python dependencies installed successfully in venv
- [ ] requirements.txt file created with pinned versions
- [ ] No package installation errors or conflicts
- [ ] All critical packages verified importable
- [ ] Package compatibility validated
- [ ] Disk space adequate after installation (>5GB remaining)
- [ ] requirements.txt frozen for reproducibility

---

## Detailed Procedure

### Step 1: Create requirements.txt with Pinned Versions

```bash
# Connect to hx-docling-mcp-server
ssh administrator@192.168.10.217

# Create requirements.txt with pinned versions
sudo tee /opt/docling-mcp/requirements.txt > /dev/null <<'EOF'
# Docling MCP Server Dependencies
# Python 3.12+
# Generated: 2025-11-27

# Core MCP Framework
fastmcp>=0.5.0,<1.0.0
pydantic>=2.10,<3.0

# Docling Document Processing
docling>=2.25,<3.0

# LightRAG Knowledge Graph
lightrag>=0.1.0,<1.0

# Vector Database Client
qdrant-client>=1.7.0,<2.0

# Redis Client
redis>=5.0.0,<6.0

# LiteLLM Multi-Provider Abstraction
litellm>=1.0.0,<2.0

# HTTP and API Support
httpx>=0.25.0
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
python-multipart>=0.0.6

# Data Processing
numpy>=1.24.0,<2.0
pandas>=2.1.0
pillow>=10.0.0

# Document Processing Support
python-magic>=0.4.27
PyPDF2>=3.0.0
python-docx>=1.0.0
openpyxl>=3.1.0

# OCR Support
pytesseract>=0.3.10

# Logging and Monitoring
python-json-logger>=2.0.7

# Environment Configuration
python-dotenv>=1.0.0

# Testing (development only - optional)
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-asyncio>=0.21.0
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/requirements.txt

# Verify file created
cat /opt/docling-mcp/requirements.txt
```

### Step 2: Activate Virtual Environment

```bash
# Activate venv
source /opt/docling-mcp/venv/bin/activate

# Verify activation
echo $VIRTUAL_ENV
# Expected: /opt/docling-mcp/venv

# Verify Python version
python --version
# Expected: Python 3.12.x

# Verify pip version
pip --version
# Expected: pip 24.x or higher
```

### Step 3: Upgrade Core Build Tools (Within venv)

```bash
# Upgrade pip, wheel, setuptools
pip install --upgrade pip wheel setuptools

# Verify versions
pip list | grep -E "(pip|wheel|setuptools)"
# Expected: Latest versions of all three packages
```

### Step 4: Install Python Dependencies from requirements.txt

```bash
# Install all dependencies (with verbose output)
pip install -r /opt/docling-mcp/requirements.txt --verbose

# Expected output: Package installation progress for each package
# Watch for any errors or warnings

# Verify installation success
echo $?
# Expected: 0 (success)
```

### Step 5: Verify Critical Package Installations

```bash
# Test critical package imports
python -c "import fastmcp; print(f'FastMCP version: {fastmcp.__version__}')"
# Expected: FastMCP version: 0.5.x or higher

python -c "import docling; print(f'Docling installed: {docling.__file__}')"
# Expected: Docling installed: /opt/docling-mcp/venv/lib/python3.12/site-packages/docling/__init__.py

python -c "import lightrag; print('LightRAG imported successfully')"
# Expected: LightRAG imported successfully

python -c "from qdrant_client import QdrantClient; print('Qdrant client imported')"
# Expected: Qdrant client imported

python -c "import redis; print(f'Redis version: {redis.__version__}')"
# Expected: Redis version: 5.x.x

python -c "import litellm; print(f'LiteLLM version: {litellm.__version__}')"
# Expected: LiteLLM version: 1.x.x

python -c "import pydantic; print(f'Pydantic version: {pydantic.__version__}')"
# Expected: Pydantic version: 2.10.x

python -c "import fastapi; print(f'FastAPI version: {fastapi.__version__}')"
# Expected: FastAPI version: 0.104.x or higher

python -c "import uvicorn; print(f'Uvicorn version: {uvicorn.__version__}')"
# Expected: Uvicorn version: 0.24.x or higher
```

### Step 6: Freeze Installed Dependencies

```bash
# Generate frozen requirements with exact versions
pip freeze > /opt/docling-mcp/requirements-frozen.txt

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/requirements-frozen.txt

# Display frozen requirements
cat /opt/docling-mcp/requirements-frozen.txt

# Count installed packages
pip list --format=freeze | wc -l
# Expected: 50-80 packages (dependencies included)
```

### Step 7: Create Dependency Validation Script

```bash
# Create validation script
sudo tee /opt/docling-mcp/scripts/validate-dependencies.sh > /dev/null <<'EOF'
#!/bin/bash
# Python Dependencies Validation Script for Docling MCP Server

set -e

echo "===== Python Dependencies Validation ====="
echo ""

VENV_PATH="/opt/docling-mcp/venv"

# Activate venv
source "$VENV_PATH/bin/activate"

# Function to check package import
check_import() {
    local package=$1
    local import_name=$2
    echo -n "Checking $package... "
    if python -c "import importlib; importlib.import_module('${import_name}')" 2>/dev/null; then
        VERSION=$(python -c "import importlib; mod = importlib.import_module('${import_name}'); print(getattr(mod, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
        echo "✓ INSTALLED (version: $VERSION)"
    else
        echo "✗ IMPORT FAILED"
        exit 1
    fi
}

# Check critical packages
echo "===== Critical Package Imports ====="
echo ""
check_import "FastMCP" "fastmcp"
check_import "Docling" "docling"
check_import "LightRAG" "lightrag"
check_import "Qdrant Client" "qdrant_client"
check_import "Redis" "redis"
check_import "LiteLLM" "litellm"
check_import "Pydantic" "pydantic"
check_import "FastAPI" "fastapi"
check_import "Uvicorn" "uvicorn"
check_import "HTTPX" "httpx"
check_import "NumPy" "numpy"
check_import "Pandas" "pandas"
check_import "Pillow" "PIL"
check_import "python-magic" "magic"
check_import "PyPDF2" "PyPDF2"
check_import "python-docx" "docx"
check_import "openpyxl" "openpyxl"
check_import "pytesseract" "pytesseract"
check_import "python-dotenv" "dotenv"

echo ""
echo "===== Package Version Verification ====="
echo ""

# Verify minimum versions
python -c "
import fastmcp, pydantic, docling, redis, fastapi
import sys

# Use pip's vendored packaging for version comparison (always available)
try:
    from packaging import version
except ImportError:
    # Fallback to pip's vendored packaging (always available with pip)
    from pip._vendor.packaging import version

versions = {
    'fastmcp': (fastmcp.__version__, '0.5.0'),
    'pydantic': (pydantic.__version__, '2.10.0'),
    'redis': (redis.__version__, '5.0.0'),
    'fastapi': (fastapi.__version__, '0.104.0'),
}

failed = False
for pkg, (actual, minimum) in versions.items():
    if version.parse(actual) >= version.parse(minimum):
        print(f'✓ {pkg}: {actual} (>= {minimum})')
    else:
        print(f'✗ {pkg}: {actual} (< {minimum} - FAIL)')
        failed = True

if failed:
    sys.exit(1)
"

echo ""
echo "===== Package Count ====="
echo ""
PACKAGE_COUNT=$(pip list --format=freeze | wc -l)
echo "Total packages installed: $PACKAGE_COUNT"
if [ "$PACKAGE_COUNT" -ge 50 ]; then
    echo "✓ Package count acceptable (>= 50 packages)"
else
    echo "✗ Package count too low (< 50 packages)"
    exit 1
fi

echo ""
echo "===== Dependency Conflicts Check ====="
echo ""
pip check
if [ $? -eq 0 ]; then
    echo "✓ No dependency conflicts detected"
else
    echo "✗ Dependency conflicts detected"
    exit 1
fi

deactivate

echo ""
echo "===== Validation Complete ====="
echo "✓ All dependency checks passed"
EOF

# Make script executable
sudo chmod +x /opt/docling-mcp/scripts/validate-dependencies.sh

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/scripts/validate-dependencies.sh

# Run validation script
sudo -u docling-mcp@hx.dev.local /opt/docling-mcp/scripts/validate-dependencies.sh

# Verify script exit code
echo $?
# Expected: 0 (success)
```

### Step 8: Document Installed Dependencies

```bash
# Create dependency documentation with runtime evaluation
# Note: Using quoted 'EOF' to preserve $() syntax for documentation readability
# The commands are NOT executed at write-time; they remain as literal instructions
sudo tee /opt/docling-mcp/documentation/python-dependencies.txt > /dev/null <<'EOF'
Python Dependencies Documentation
=================================

Installation Date: [Run: date]
Node: hx-docling-mcp-server (192.168.10.217)
Python Version: [Run: source /opt/docling-mcp/venv/bin/activate && python --version]
Virtual Environment: /opt/docling-mcp/venv

Critical Packages Installed:
----------------------------
[Run: source /opt/docling-mcp/venv/bin/activate && pip list | grep -E "(fastmcp|docling|lightrag|qdrant-client|redis|litellm|pydantic|fastapi|uvicorn)"]

All Installed Packages (Frozen):
--------------------------------
[Run: cat /opt/docling-mcp/requirements-frozen.txt]

Package Statistics:
------------------
Total Packages: [Run: source /opt/docling-mcp/venv/bin/activate && pip list --format=freeze | wc -l]
Disk Usage: [Run: du -sh /opt/docling-mcp/venv | awk '{print $1}']

Dependency Conflicts:
--------------------
[Run: source /opt/docling-mcp/venv/bin/activate && pip check 2>&1]

Installed By: [Run: whoami]
Installation Command: pip install -r /opt/docling-mcp/requirements.txt
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/documentation/python-dependencies.txt

# Display documentation
cat /opt/docling-mcp/documentation/python-dependencies.txt
```

### Step 9: Deactivate Virtual Environment

```bash
# Deactivate venv
deactivate

# Verify deactivation
echo $VIRTUAL_ENV
# Expected: (empty)

# Verify system Python NOT affected
python3 --version
# Expected: System Python version (NOT venv Python)
```

### Step 10: Verify Disk Space After Installation

```bash
# Check venv disk usage
du -sh /opt/docling-mcp/venv
# Expected: 500MB - 1.5GB

# Check remaining disk space
df -h /
# Expected: >5GB available

# Detailed venv breakdown
du -h -d 1 /opt/docling-mcp/venv | sort -h
```

---

## Validation

### Validation Commands

```bash
# 1. Verify requirements.txt exists
test -f /opt/docling-mcp/requirements.txt && echo "PASS: requirements.txt exists" || echo "FAIL: requirements.txt missing"

# 2. Verify requirements-frozen.txt exists
test -f /opt/docling-mcp/requirements-frozen.txt && echo "PASS: frozen requirements exist" || echo "FAIL: frozen requirements missing"

# 3. Verify critical packages installed
source /opt/docling-mcp/venv/bin/activate
python -c "import fastmcp, docling, lightrag, qdrant_client, redis, litellm, pydantic, fastapi" && echo "PASS: critical packages importable" || echo "FAIL: import error"
deactivate

# 4. Verify package count >= 50
PACKAGE_COUNT=$(source /opt/docling-mcp/venv/bin/activate && pip list --format=freeze | wc -l)
[ "$PACKAGE_COUNT" -ge 50 ] && echo "PASS: package count adequate ($PACKAGE_COUNT)" || echo "FAIL: package count too low ($PACKAGE_COUNT)"

# 5. Verify no dependency conflicts
source /opt/docling-mcp/venv/bin/activate
pip check && echo "PASS: no dependency conflicts" || echo "FAIL: dependency conflicts detected"
deactivate

# 6. Verify disk space remaining
AVAILABLE=$(df / | tail -1 | awk '{print $4}')
[ "$AVAILABLE" -gt 5242880 ] && echo "PASS: disk space adequate" || echo "FAIL: low disk space"

# 7. Run comprehensive validation script
/opt/docling-mcp/scripts/validate-dependencies.sh && echo "PASS: all validation checks passed" || echo "FAIL: validation script failed"
```

### Success Criteria

- ✅ requirements.txt created with package specifications
- ✅ requirements-frozen.txt created with exact versions
- ✅ All packages from requirements.txt installed successfully
- ✅ All critical packages importable without errors
- ✅ Package versions meet minimum requirements
- ✅ No dependency conflicts detected (pip check)
- ✅ Total packages >= 50 (dependencies included)
- ✅ Disk space >5GB remaining
- ✅ Validation script passes all checks
- ✅ Documentation generated

---

## Troubleshooting

### Issue: Package Installation Fails

**Symptom**: `ERROR: Could not find a version that satisfies the requirement...`

**Solution**:
```bash
# Check Python version
source /opt/docling-mcp/venv/bin/activate
python --version
# Must be Python 3.12.x

# Check pip version
pip --version
# Upgrade if needed
pip install --upgrade pip

# Try installing package individually
pip install <package-name> --verbose

# Check for system dependencies
# Some packages require system libraries installed in Task 003
```

### Issue: Dependency Conflict

**Symptom**: `ERROR: pip's dependency resolver does not currently take into account all the packages...`

**Solution**:
```bash
# Check conflicts
source /opt/docling-mcp/venv/bin/activate
pip check

# Show dependency tree
pip install pipdeptree
pipdeptree

# Install conflicting packages with compatible versions
pip install <package>==<compatible-version>
```

### Issue: Import Error After Installation

**Symptom**: `ModuleNotFoundError: No module named 'xxx'`

**Solution**:
```bash
# Verify venv activated
echo $VIRTUAL_ENV
# Must show /opt/docling-mcp/venv

# Verify package installed
source /opt/docling-mcp/venv/bin/activate
pip list | grep <package-name>

# Reinstall package
pip uninstall <package-name> -y
pip install <package-name>

# Test import again
python -c "import <package-name>"
```

### Issue: Insufficient Disk Space

**Symptom**: `OSError: [Errno 28] No space left on device`

**Solution**:
```bash
# Check disk usage
df -h /

# Clean pip cache
source /opt/docling-mcp/venv/bin/activate
pip cache purge

# Remove __pycache__ directories
find /opt/docling-mcp/venv -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null

# If needed, expand disk or clean other files
```

### Issue: SSL/TLS Certificate Error

**Symptom**: `[SSL: CERTIFICATE_VERIFY_FAILED]`

**Solution**:
```bash
# Update ca-certificates
sudo apt-get update
sudo apt-get install --reinstall ca-certificates

# Install certifi package
source /opt/docling-mcp/venv/bin/activate
pip install --upgrade certifi

# Retry installation
pip install -r /opt/docling-mcp/requirements.txt
```

---

## Rollback Procedure

**If dependency installation fails or needs recreation**:

```bash
# Activate venv
source /opt/docling-mcp/venv/bin/activate

# Uninstall all packages (except pip, setuptools, wheel)
pip freeze | grep -v -E "(pip|setuptools|wheel)" | xargs pip uninstall -y

# Deactivate venv
deactivate

# Remove frozen requirements
sudo rm -f /opt/docling-mcp/requirements-frozen.txt

# Remove validation script
sudo rm -f /opt/docling-mcp/scripts/validate-dependencies.sh

# Remove documentation
sudo rm -f /opt/docling-mcp/documentation/python-dependencies.txt

# If complete venv recreation needed, see Task 004 rollback
# rm -rf /opt/docling-mcp/venv
# Then recreate from Task 004, Step 2
```

---

## Dependencies

**Blocks**:
- Task 007: Install Application Code (requires packages for code execution)
- All development tasks (requires dependencies)
- All testing tasks (requires test packages)

**Depends On**:
- Task 002: Create Samba AD Service Account (ownership)
- Task 003: Install System Dependencies (system libraries for compilation)
- Task 004: Create Python Virtual Environment (venv must exist)

---

## Notes

### Package Selection Rationale

**Core Framework Packages**:
- **fastmcp**: MCP protocol framework (primary application framework)
- **pydantic >=2.10**: Data validation and MCP tool schemas
- **fastapi**: HTTP API framework for MCP HTTP transport
- **uvicorn**: ASGI server for FastAPI

**Document Processing Packages**:
- **docling ~=2.25**: Document conversion library (PDF, DOCX, images)
- **PyPDF2**: PDF parsing
- **python-docx**: DOCX parsing
- **openpyxl**: XLSX parsing
- **pytesseract**: OCR engine wrapper

**Knowledge Graph Packages**:
- **lightrag**: Knowledge graph generation framework
- **qdrant-client**: Vector database client for knowledge graph storage
- **redis**: Session management and caching

**LLM Integration Packages**:
- **litellm**: Multi-provider LLM abstraction (Ollama routing)

**Supporting Packages**:
- **numpy, pandas**: Data processing
- **pillow**: Image processing
- **python-magic**: MIME type detection
- **python-dotenv**: Environment variable management
- **python-json-logger**: Structured logging

### Version Pinning Strategy

**Major.Minor Pinning** (`>=X.Y,<X+1.0`):
- Allows patch updates (bug fixes)
- Prevents breaking changes from major version bumps
- Balances security patches with stability

**Frozen Requirements** (`requirements-frozen.txt`):
- Exact versions for reproducibility
- Generated with `pip freeze`
- Used for debugging and rollback scenarios

### HX-Infrastructure Standards Compliance

- ✅ **Bare-Metal Deployment**: Native Python packages (no containers)
- ✅ **Virtual Environment Isolation**: No system Python package pollution
- ✅ **Service Account Ownership**: All files owned by domain service account
- ✅ **Manual Procedures**: All commands documented for human execution
- ✅ **Version Documentation**: Frozen requirements for reproducibility

---

## References

- **Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (Task 005)
- **Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md` (Technology Stack)
- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Dependencies)
- **Requirements File**: `/opt/docling-mcp/requirements.txt`

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
