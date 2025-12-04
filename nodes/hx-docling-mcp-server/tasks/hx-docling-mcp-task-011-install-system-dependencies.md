# Task 011: Install System Dependencies

**Assigned To**: william-chen
**Estimated Effort**: 1.5 hours
**Dependencies**: Task 005 (Directory Permissions)
**Status**: Not Started

## Objective

Install all required OS-level system packages for Docling MCP Server including Python 3.11 runtime, poppler-utils, tesseract-ocr, libmagic1, and supporting libraries on Ubuntu 24.04 LTS.

## Pre-Execution Validation

**CRITICAL**: Check if system dependencies are already installed BEFORE proceeding with apt installation.

```bash
# Validation command to check if critical packages already installed
echo "Checking system dependencies installation status..."

PACKAGES_TO_CHECK=(
    "python3.11"
    "python3.11-venv"
    "python3.11-dev"
    "poppler-utils"
    "tesseract-ocr"
    "libmagic1"
    "build-essential"
    "libssl-dev"
    "libffi-dev"
)

ALL_INSTALLED=true

for pkg in "${PACKAGES_TO_CHECK[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo "✅ $pkg: Already installed"
    else
        echo "❌ $pkg: Not installed"
        ALL_INSTALLED=false
    fi
done

if [ "$ALL_INSTALLED" = true ]; then
    echo ""
    echo "✅ VALIDATION RESULT: All system dependencies already installed"
    echo "ACTION: SKIP task execution, proceed to validation section"
    exit 0
else
    echo ""
    echo "❌ VALIDATION RESULT: Some system dependencies missing"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Skip to Validation section
**If Not Complete**: Continue with Implementation Steps below

---

## Context

The Docling MCP Server requires multiple system-level dependencies for document processing:

- **Python 3.11**: Runtime environment (Ubuntu 24.04 includes 3.11 by default)
- **poppler-utils**: PDF rendering utilities for pypdfium2 backend
- **tesseract-ocr**: OCR engine for scanned documents and images
- **libmagic1**: File format detection (magic number identification)
- **build-essential**: Compilation tools for Python packages with C extensions
- **libssl-dev, libffi-dev**: Cryptographic libraries for secure connections
- **Image processing libraries**: libjpeg-dev, libpng-dev, libtiff-dev for image format support

This task installs all bare-metal system dependencies before Python virtual environment creation (Task 021).

## Acceptance Criteria

- [ ] Python 3.11 installed and available at `/usr/bin/python3.11`
- [ ] Python 3.11 venv module installed (`python3.11-venv` package)
- [ ] Python 3.11 development headers installed (`python3.11-dev` package)
- [ ] poppler-utils installed (verify: `pdftoppm --version`)
- [ ] tesseract-ocr installed (verify: `tesseract --version`)
- [ ] libmagic1 installed (verify: `dpkg -l | grep libmagic1`)
- [ ] build-essential installed (verify: `gcc --version`)
- [ ] libssl-dev and libffi-dev installed
- [ ] Image processing libraries installed (libjpeg-dev, libpng-dev, libtiff-dev)
- [ ] No package installation errors in apt output
- [ ] Package versions documented for future reference

## Implementation Steps

### Step 1: Update Package Repository Cache

```bash
# Update apt package cache to latest repository state
sudo apt-get update

# Verify cache update successful
if [ $? -eq 0 ]; then
    echo "✅ APT cache updated successfully"
else
    echo "❌ APT cache update failed"
    exit 1
fi
```

### Step 2: Install Python 3.11 and Development Tools

```bash
# Install Python 3.11 runtime, venv module, and development headers
sudo apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    build-essential

# Verify Python 3.11 installation
python3.11 --version
if [ $? -eq 0 ]; then
    echo "✅ Python 3.11 installed successfully"
else
    echo "❌ Python 3.11 installation failed"
    exit 1
fi
```

### Step 3: Install Document Processing System Dependencies

```bash
# Install poppler-utils for PDF processing
sudo apt-get install -y poppler-utils

# Install tesseract-ocr for OCR processing
sudo apt-get install -y tesseract-ocr tesseract-ocr-eng

# Install libmagic for file format detection
sudo apt-get install -y libmagic1 libmagic-dev file

# Verify installations
pdftoppm --version && echo "✅ poppler-utils installed"
tesseract --version && echo "✅ tesseract-ocr installed"
dpkg -l | grep -q libmagic1 && echo "✅ libmagic1 installed"
```

### Step 4: Install Cryptographic and Image Processing Libraries

```bash
# Install SSL/TLS and cryptographic libraries
sudo apt-get install -y \
    libssl-dev \
    libffi-dev

# Install image processing libraries for format support
sudo apt-get install -y \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libwebp-dev

# Verify library installations
dpkg -l | grep -E '(libssl-dev|libffi-dev|libjpeg-dev|libpng-dev|libtiff-dev)'
```

### Step 5: Install Additional System Utilities

```bash
# Install additional utilities for document processing
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip

# Verify installations
curl --version && echo "✅ curl installed"
wget --version && echo "✅ wget installed"
git --version && echo "✅ git installed"
unzip -v && echo "✅ unzip installed"
```

### Step 6: Document Installed Package Versions

```bash
# Create package version inventory
mkdir -p /opt/docling-mcp/deployment-docs

cat > /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt <<'EOF'
# System Dependencies Installation Inventory
# Date: $(date +%Y-%m-%d)
# Node: hx-docling-mcp-server.hx.dev.local
# Task: hx-docling-mcp-task-011

## Python Runtime
EOF

echo "Python 3.11: $(python3.11 --version)" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt
echo "Python 3.11 venv: $(dpkg -l | grep python3.11-venv | awk '{print $3}')" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt
echo "Python 3.11 dev: $(dpkg -l | grep python3.11-dev | awk '{print $3}')" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt

cat >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt <<'EOF'

## Document Processing Tools
EOF

echo "poppler-utils: $(pdftoppm -v 2>&1 | head -n1)" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt
echo "tesseract-ocr: $(tesseract --version 2>&1 | head -n1)" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt
echo "libmagic1: $(dpkg -l | grep libmagic1 | awk '{print $3}')" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt

cat >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt <<'EOF'

## Build Tools
EOF

echo "build-essential: $(gcc --version | head -n1)" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt
echo "libssl-dev: $(dpkg -l | grep libssl-dev | awk '{print $3}')" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt
echo "libffi-dev: $(dpkg -l | grep libffi-dev | awk '{print $3}')" >> /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt

echo "✅ Package version inventory created: /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt"
cat /opt/docling-mcp/deployment-docs/system-dependencies-inventory.txt
```

## Validation

**Validation Commands:**

```bash
echo "=== System Dependencies Validation ==="

# Validate Python 3.11 installation
echo "1. Python 3.11 Runtime:"
python3.11 --version
which python3.11
python3.11 -m venv --help > /dev/null 2>&1 && echo "✅ venv module available"

# Validate document processing tools
echo "2. Document Processing Tools:"
pdftoppm --version 2>&1 | head -n1
tesseract --version 2>&1 | head -n1
file --version | head -n1

# Validate build tools
echo "3. Build and Compilation Tools:"
gcc --version | head -n1
pkg-config --version

# Validate libraries
echo "4. System Libraries:"
dpkg -l | grep -E '(libmagic1|libssl-dev|libffi-dev|libjpeg-dev|libpng-dev|libtiff-dev)' | awk '{print $2, $3}'

# Validate utilities
echo "5. System Utilities:"
curl --version | head -n1
wget --version | head -n1
git --version

# Summary
echo ""
echo "=== Validation Summary ==="
VALIDATION_PASSED=true

# Check critical packages
for cmd in python3.11 pdftoppm tesseract gcc curl; do
    if ! command -v $cmd > /dev/null 2>&1; then
        echo "❌ FAILED: $cmd not found in PATH"
        VALIDATION_PASSED=false
    else
        echo "✅ PASSED: $cmd available"
    fi
done

if [ "$VALIDATION_PASSED" = true ]; then
    echo ""
    echo "✅ ALL VALIDATIONS PASSED - System dependencies installed successfully"
    exit 0
else
    echo ""
    echo "❌ VALIDATION FAILED - Some dependencies missing or not accessible"
    exit 1
fi
```

**Expected Results:**
- Python 3.11 version output: `Python 3.11.x`
- poppler-utils version: `pdftoppm version 24.x.x`
- tesseract version: `tesseract 5.x.x`
- All libraries show installed status with version numbers
- No "command not found" errors
- All validation checks return `✅ PASSED`

## Notes

**Ubuntu 24.04 LTS Considerations:**
- Python 3.11 is the default Python 3 version on Ubuntu 24.04 LTS
- Tesseract 5.x is available in default repositories (no PPA required)
- poppler-utils version 24.x provides all required PDF processing capabilities

**Bare-Metal Deployment:**
- All packages installed via native OS package manager (apt)
- NO Docker containers or virtual machines
- NO package compilation from source (use apt packages exclusively)

**Security Considerations:**
- Use ONLY official Ubuntu repositories (no third-party PPAs for critical packages)
- Document all package versions for reproducibility
- Keep package cache updated with `apt-get update` before installation

**Troubleshooting:**
- If `apt-get update` fails: Check DNS resolution to Ubuntu repository mirrors
- If package installation fails: Review `/var/log/apt/history.log` for errors
- If Python 3.11 not found: Verify Ubuntu version is 24.04 LTS (`lsb_release -a`)

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: Deployment Architecture (lines 4887-5086)
- Section: Dependencies - System Dependencies (lines 835-1035)

**HX-Infrastructure Standards**:
- Bare-metal deployment standard (no Docker for production)
- Manual procedures with documentation (no automation scripts)
- Ubuntu 24.04 LTS as standard server OS

## Risk Assessment

**Risk Level**: Low

**Risks**:
1. **APT repository unavailable**: Mitigated by checking connectivity before installation
2. **Package version incompatibility**: Mitigated by using Ubuntu 24.04 LTS stable repositories
3. **Disk space insufficient**: Mitigated by pre-checking available disk space (Task 003 validated 50GB+ available)

**Mitigation**:
- Validate repository connectivity with `apt-get update` before package installation
- Use pre-execution validation to detect already-installed packages (avoid redundant work)
- Document exact package versions for troubleshooting and future reference
