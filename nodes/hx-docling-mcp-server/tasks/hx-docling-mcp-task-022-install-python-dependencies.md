# Task 022: Install Python Dependencies

**Assigned To**: william-chen
**Estimated Effort**: 2 hours
**Dependencies**: Task 021 (Python Virtual Environment Creation)
**Status**: Not Started

## Objective

Install all Python package dependencies in the virtual environment from requirements.txt, including FastMCP, Docling, Pydantic, and all integration libraries (LiteLLM client, Qdrant client, Redis client).

## Pre-Execution Validation

**CRITICAL**: Check if Python dependencies are already installed in virtual environment BEFORE running pip install.

```bash
# Validation command to check if Python packages already installed
VENV_PATH="/opt/docling-mcp/venv"

echo "Checking Python dependencies installation status..."

if [ ! -f "$VENV_PATH/bin/python" ]; then
    echo "❌ Virtual environment not found - Task 021 prerequisite not met"
    exit 1
fi

# Check for key packages
KEY_PACKAGES=(
    "fastmcp"
    "docling"
    "pydantic"
    "uvicorn"
    "redis"
    "httpx"
)

ALL_INSTALLED=true

for pkg in "${KEY_PACKAGES[@]}"; do
    if $VENV_PATH/bin/python -c "import $pkg" 2>/dev/null; then
        VERSION=$($VENV_PATH/bin/python -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
        echo "✅ $pkg: $VERSION installed"
    else
        echo "❌ $pkg: Not installed"
        ALL_INSTALLED=false
    fi
done

if [ "$ALL_INSTALLED" = true ]; then
    echo ""
    echo "✅ VALIDATION RESULT: All critical Python dependencies already installed"
    echo "ACTION: SKIP task execution, proceed to validation section"
    exit 0
else
    echo ""
    echo "❌ VALIDATION RESULT: Some Python dependencies missing"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Skip to Validation section
**If Not Complete**: Continue with Implementation Steps below

---

## Context

The Docling MCP Server requires extensive Python dependencies across multiple categories:

- **MCP Framework**: FastMCP (MCP protocol implementation)
- **Web Framework**: Uvicorn (ASGI server), FastAPI (HTTP framework)
- **Document Processing**: Docling library (multi-format conversion, OCR)
- **Configuration**: Pydantic (settings validation, schema enforcement)
- **HTTP Clients**: httpx (async HTTP for LiteLLM, Qdrant, hx-literag-server)
- **Database Clients**: redis-py (Redis), qdrant-client (Qdrant HTTP API)
- **Utilities**: python-magic (file format detection), EasyOCR (OCR engine)

This task installs ALL Python dependencies from requirements.txt. The requirements file will be created in Task 007 (Install Application Code).

**NOTE**: If requirements.txt does not exist yet, this task will create a baseline requirements.txt with known dependencies from specification.

## Acceptance Criteria

- [ ] requirements.txt file exists in `/opt/docling-mcp/`
- [ ] All packages from requirements.txt installed successfully in venv
- [ ] FastMCP framework installed and importable
- [ ] Docling library installed with all backends (pypdfium2, python-docx, python-pptx, openpyxl)
- [ ] Pydantic v2.x installed (NOT v1.x)
- [ ] Uvicorn ASGI server installed
- [ ] httpx HTTP client installed
- [ ] redis-py client installed
- [ ] EasyOCR installed (may take extended time due to PyTorch dependency)
- [ ] No package installation errors
- [ ] Package versions documented with `pip freeze > requirements-installed.txt`

## Implementation Steps

### Step 1: Create requirements.txt (if not exists)

```bash
# Check if requirements.txt exists from Task 007
REQUIREMENTS_FILE="/opt/docling-mcp/requirements.txt"

if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "✅ requirements.txt found: $REQUIREMENTS_FILE"
    echo "Using existing requirements file from Task 007"
else
    echo "⚠️  requirements.txt not found - creating baseline from specification"

    cat > "$REQUIREMENTS_FILE" <<'EOF'
# Docling MCP Server - Python Dependencies
# Generated: Task 022 (Baseline)
# Node: hx-docling-mcp-server.hx.dev.local

# MCP Framework
fastmcp>=0.1.0

# Web Framework
uvicorn[standard]>=0.30.0
fastapi>=0.115.0
starlette>=0.38.0

# Document Processing
docling>=1.0.0
pypdfium2>=4.30.0
python-docx>=1.1.0
python-pptx>=0.6.23
openpyxl>=3.1.0
beautifulsoup4>=4.12.0
lxml>=5.0.0
easyocr>=1.7.0

# Configuration & Validation
pydantic>=2.8.0
pydantic-settings>=2.4.0

# HTTP Clients
httpx>=0.27.0

# Database Clients
redis>=5.0.0
qdrant-client>=1.11.0

# File Format Detection
python-magic>=0.4.27

# Utilities
python-dotenv>=1.0.0
aiofiles>=24.1.0

# Logging
structlog>=24.0.0
python-json-logger>=2.0.0
EOF

    echo "✅ Baseline requirements.txt created: $REQUIREMENTS_FILE"
    cat "$REQUIREMENTS_FILE"
fi
```

### Step 2: Install Python Dependencies from requirements.txt

```bash
# Install all packages from requirements.txt
VENV_PATH="/opt/docling-mcp/venv"
REQUIREMENTS_FILE="/opt/docling-mcp/requirements.txt"

echo "Installing Python dependencies from requirements.txt..."
echo "This may take 5-10 minutes due to large packages (PyTorch for EasyOCR)"

$VENV_PATH/bin/pip install -r "$REQUIREMENTS_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Python dependencies installed successfully"
else
    echo "❌ Python dependency installation failed"
    echo "Check pip output above for specific package errors"
    exit 1
fi
```

### Step 3: Verify Critical Package Installation

```bash
# Verify critical packages are importable
VENV_PATH="/opt/docling-mcp/venv"

echo "Verifying critical package installations..."

# Test FastMCP
if $VENV_PATH/bin/python -c "import fastmcp; print(f'FastMCP version: {fastmcp.__version__}')" 2>/dev/null; then
    echo "✅ FastMCP installed and importable"
else
    echo "❌ FastMCP import failed"
    exit 1
fi

# Test Docling
if $VENV_PATH/bin/python -c "import docling; print(f'Docling version: {docling.__version__}')" 2>/dev/null; then
    echo "✅ Docling installed and importable"
else
    echo "❌ Docling import failed"
    exit 1
fi

# Test Docling backends (required for multi-format support per FR-005)
echo ""
echo "Verifying Docling backend packages..."
BACKENDS=("pypdfium2" "docx" "pptx" "openpyxl")
BACKEND_DISPLAY=("pypdfium2 (PDF)" "python-docx (DOCX)" "python-pptx (PPTX)" "openpyxl (XLSX)")
BACKEND_FAILED=0

for i in "${!BACKENDS[@]}"; do
    BACKEND="${BACKENDS[$i]}"
    DISPLAY="${BACKEND_DISPLAY[$i]}"
    
    if $VENV_PATH/bin/python -c "import ${BACKEND}" 2>/dev/null; then
        echo "✅ ${DISPLAY} backend available"
    else
        echo "❌ ${DISPLAY} backend import failed"
        BACKEND_FAILED=1
    fi
done

if [ $BACKEND_FAILED -eq 1 ]; then
    echo ""
    echo "❌ One or more Docling backends failed to import"
    echo "   Required backends: pypdfium2, python-docx, python-pptx, openpyxl"
    echo "   These are essential for multi-format document processing (FR-005)"
    exit 1
fi

echo "✅ All Docling backends verified"
echo ""

# Test Pydantic v2
if $VENV_PATH/bin/python -c "import pydantic; assert pydantic.__version__.startswith('2.'), 'Pydantic v1 detected'; print(f'Pydantic version: {pydantic.__version__}')" 2>/dev/null; then
    echo "✅ Pydantic v2 installed and importable"
else
    echo "❌ Pydantic import failed or wrong version (v1 vs v2)"
    exit 1
fi

# Test Uvicorn
if $VENV_PATH/bin/python -c "import uvicorn; print(f'Uvicorn version: {uvicorn.__version__}')" 2>/dev/null; then
    echo "✅ Uvicorn installed and importable"
else
    echo "❌ Uvicorn import failed"
    exit 1
fi

# Test Redis
if $VENV_PATH/bin/python -c "import redis; print(f'redis-py version: {redis.__version__}')" 2>/dev/null; then
    echo "✅ redis-py installed and importable"
else
    echo "❌ redis-py import failed"
    exit 1
fi

# Test httpx
if $VENV_PATH/bin/python -c "import httpx; print(f'httpx version: {httpx.__version__}')" 2>/dev/null; then
    echo "✅ httpx installed and importable"
else
    echo "❌ httpx import failed"
    exit 1
fi

# Test EasyOCR (may fail if CUDA not available, gracefully handle)
if $VENV_PATH/bin/python -c "import easyocr; print(f'EasyOCR version: {easyocr.__version__}')" 2>/dev/null; then
    echo "✅ EasyOCR installed and importable"
else
    echo "⚠️  EasyOCR import warning (may require GPU support, check logs)"
fi
```

### Step 4: Document Installed Package Versions

```bash
# Freeze installed packages for documentation
VENV_PATH="/opt/docling-mcp/venv"
DOC_PATH="/opt/docling-mcp/deployment-docs"

mkdir -p "$DOC_PATH"

# Create comprehensive package inventory
$VENV_PATH/bin/pip freeze > "$DOC_PATH/requirements-installed.txt"

echo "✅ Installed package inventory created: $DOC_PATH/requirements-installed.txt"

# Display summary
echo ""
echo "Installed Package Summary:"
echo "Total packages: $($VENV_PATH/bin/pip list | wc -l)"
echo ""
echo "Critical packages:"
$VENV_PATH/bin/pip list | grep -E '(fastmcp|docling|pydantic|uvicorn|redis|httpx|easyocr)'
```

### Step 5: Verify Package Compatibility

```bash
# Check for package conflicts or compatibility issues
VENV_PATH="/opt/docling-mcp/venv"

echo "Checking package dependency compatibility..."

$VENV_PATH/bin/pip check

if [ $? -eq 0 ]; then
    echo "✅ All package dependencies compatible, no conflicts detected"
else
    echo "⚠️  WARNING: Package dependency conflicts detected"
    echo "Review pip check output above for details"
    echo "Conflicts may require manual resolution"
fi
```

## Validation

**Validation Commands:**

```bash
echo "=== Python Dependencies Validation ==="

VENV_PATH="/opt/docling-mcp/venv"

# Validate requirements.txt exists
echo "1. Requirements File:"
if [ -f "/opt/docling-mcp/requirements.txt" ]; then
    echo "✅ PASSED: requirements.txt exists"
    echo "Requirements count: $(grep -v '^#' /opt/docling-mcp/requirements.txt | grep -v '^$' | wc -l) packages"
else
    echo "❌ FAILED: requirements.txt missing"
    exit 1
fi

# Validate critical packages installed
echo ""
echo "2. Critical Packages:"
CRITICAL_PACKAGES=(
    "fastmcp:FastMCP framework"
    "docling:Docling library"
    "pydantic:Configuration validation"
    "uvicorn:ASGI server"
    "redis:Redis client"
    "httpx:HTTP client"
)

ALL_CRITICAL_OK=true

for entry in "${CRITICAL_PACKAGES[@]}"; do
    IFS=':' read -r pkg desc <<< "$entry"

    if $VENV_PATH/bin/python -c "import $pkg" 2>/dev/null; then
        VERSION=$($VENV_PATH/bin/python -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
        echo "✅ PASSED: $desc ($pkg v$VERSION)"
    else
        echo "❌ FAILED: $desc ($pkg) not installed"
        ALL_CRITICAL_OK=false
    fi
done

if [ "$ALL_CRITICAL_OK" = false ]; then
    echo "❌ Critical package validation failed"
    exit 1
fi

# Validate Pydantic version (must be v2.x)
echo ""
echo "3. Pydantic Version Check:"
PYDANTIC_VERSION=$($VENV_PATH/bin/python -c "import pydantic; print(pydantic.__version__)")
if [[ "$PYDANTIC_VERSION" == 2.* ]]; then
    echo "✅ PASSED: Pydantic v2.x ($PYDANTIC_VERSION)"
else
    echo "❌ FAILED: Pydantic v1.x detected ($PYDANTIC_VERSION), requires v2.x"
    exit 1
fi

# Validate package compatibility
echo ""
echo "4. Package Compatibility:"
if $VENV_PATH/bin/pip check > /dev/null 2>&1; then
    echo "✅ PASSED: No package dependency conflicts"
else
    echo "⚠️  WARNING: Package conflicts detected, review may be needed"
fi

# Validate package count
echo ""
echo "5. Package Inventory:"
PACKAGE_COUNT=$($VENV_PATH/bin/pip list | tail -n +3 | wc -l)
echo "Total packages installed: $PACKAGE_COUNT"

if [ "$PACKAGE_COUNT" -gt 50 ]; then
    echo "✅ PASSED: Expected package count (>50 packages with dependencies)"
else
    echo "⚠️  WARNING: Low package count, installation may be incomplete"
fi

# Validate requirements-installed.txt documentation
echo ""
echo "6. Documentation:"
if [ -f "/opt/docling-mcp/deployment-docs/requirements-installed.txt" ]; then
    echo "✅ PASSED: Installed package inventory documented"
    DOC_COUNT=$(wc -l < /opt/docling-mcp/deployment-docs/requirements-installed.txt)
    echo "Documented packages: $DOC_COUNT"
else
    echo "⚠️  WARNING: Package inventory not documented"
fi

# Summary
echo ""
echo "=== Validation Summary ==="
if [ "$ALL_CRITICAL_OK" = true ]; then
    echo "✅ ALL VALIDATIONS PASSED - Python dependencies ready"
    echo ""
    echo "Next Step: Task 007 - Install Application Code"
    exit 0
else
    echo "❌ VALIDATION FAILED - Some critical packages missing"
    exit 1
fi
```

**Expected Results:**
- requirements.txt contains 20+ packages
- All critical packages import successfully
- Pydantic version starts with "2."
- pip check returns no errors
- Total package count >50 (including transitive dependencies)
- requirements-installed.txt contains full package list with versions

## Notes

**Large Package Installation:**
- **EasyOCR**: Requires PyTorch (several GB download), installation may take 10-20 minutes
- **Total venv size**: Approximately 2-3 GB after all dependencies installed
- **Network bandwidth**: Requires stable internet connection for PyPI downloads

**PyTorch/CUDA Considerations:**
- EasyOCR installs CPU-only PyTorch by default (no CUDA required)
- GPU acceleration NOT required for hx-docling-mcp-server (CPU OCR sufficient)
- If GPU needed in future, reinstall PyTorch with CUDA support

**Pydantic v1 vs v2:**
- **CRITICAL**: Pydantic v2.x required (v1.x incompatible)
- FastAPI 0.115+ requires Pydantic v2
- If v1.x installed, uninstall and reinstall: `pip uninstall pydantic && pip install pydantic>=2.8.0`

**Dependency Conflicts:**
- If `pip check` reports conflicts, review carefully
- Common conflicts: Pydantic v1/v2, starlette/fastapi version mismatches
- Resolve by pinning specific versions in requirements.txt

**Requirements.txt Management:**
- **requirements.txt**: High-level dependencies (what we explicitly need)
- **requirements-installed.txt**: All packages including transitive dependencies (pip freeze output)
- Use requirements-installed.txt for exact environment recreation

**Troubleshooting:**
- If package import fails: Check for system library dependencies (Task 011)
- If PyTorch fails: Verify sufficient disk space (PyTorch ~1.5GB)
- If httpx fails: Check OpenSSL installation (libssl-dev from Task 011)

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Python Dependencies (requirements.txt content)
- Section: Pydantic Configuration Schema (lines 1000-1100)

**Package Documentation**:
- FastMCP: https://github.com/jlowin/fastmcp
- Docling: https://github.com/DS4SD/docling
- Pydantic: https://docs.pydantic.dev/2.8/
- EasyOCR: https://github.com/JaidedAI/EasyOCR

## Risk Assessment

**Risk Level**: Medium

**Risks**:
1. **PyTorch download timeout**: EasyOCR requires large PyTorch download (1.5GB+)
2. **Pydantic v1/v2 conflict**: FastAPI/Pydantic version incompatibility
3. **Disk space exhaustion**: Virtual environment can exceed 2GB
4. **Package compilation failure**: Some packages require build-essential (Task 011 dependency)

**Mitigation**:
- Pre-validate internet connectivity and bandwidth
- Pre-check disk space (Task 003 validation confirmed 50GB+ available)
- Install build-essential in Task 011 BEFORE this task
- Document exact package versions with pip freeze for reproducibility
- If PyTorch download fails, use local PyPI mirror or manual download
